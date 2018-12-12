----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    20:09:33 03/08/2017 
-- Design Name: 
-- Module Name:    triggerSystem - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use work.types.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity triggerLogic is
generic(
	numberOfChannels : integer := 8
	);
port(
	pixelInSerdes : in std_logic_vector(8*numberOfChannels-1 downto 0);
	--externalTriggerIn : in std_logic_vector(0 downto 0);
	ledFlasherPreTrigger : in std_logic;
	externalDeadTime : in std_logic;
	internalTiming : in internalTiming_t;
	trigger : out triggerLogic_t;
	
	registerRead : out triggerLogic_registerRead_t;
	registerWrite : in triggerLogic_registerWrite_t	
	);
end triggerLogic;

architecture Behavioral of triggerLogic is
	
	signal pixelSerdeMaskedNotDelayed : std_logic_vector(7 downto 0);
	signal pixelSerdeMaskedDelayed : std_logic_vector(7 downto 0);
	signal triggerMasked : data8x8Bit_t;
	
	signal fifoClear : std_logic;
	signal fifoWrite : std_logic;
	signal fifoRead : std_logic;
	type stateDelay_t is (init1, init2, run);
	signal stateDelay : stateDelay_t;
	signal delayCounter : integer range 0 to 2047;
	
	signal registerSoftTrigger_old : std_logic;
	signal singleSoftTrigger : std_logic;
	signal pixelTriggerDisabled : std_logic;
	signal singleSeq_old : std_logic;
	signal pixelTriggerNotDelayed : std_logic;
	signal triggerNotDelayed_old : std_logic;
	signal pixelTriggerDelayed : std_logic;
	
	signal triggerGeneratorCounter : unsigned(31 downto 0);
	signal triggerGeneratorTrigger : std_logic;

--	constant rateChannels : integer := 1;
--	type counter_t is array (0 to rateChannels-1) of unsigned(15 downto 0);
	--signal rateCounter : counter_t := (others => (others => '0'));
	--signal rateCounterInsideDeadTime : counter_t := (others => (others => '0'));
	--signal triggerToRate : std_logic_vector(rateChannels-1 downto 0) := (others=>'0');
--	signal triggerToRate_old : std_logic_vector(rateChannels-1 downto 0);
	signal newData : std_logic;
	signal counter_ms : unsigned(15 downto 0);
	signal counter_sec : unsigned(15 downto 0);
--	signal rateLatched : counter_t;
--	signal rateDeadTimeLatched : counter_t;
--	signal realTimeDeltaCounter : unsigned(63 downto 0);
	
	--signal sumTrigger : std_logic;
	signal sumTrigger_old : std_logic;
	
	signal sumTriggerSameEvent : std_logic;
	signal sameEventCounter : unsigned(11 downto 0);
--	signal sameEventTime : std_logic_vector(11 downto 0);
	
	signal flasherTrigger : std_logic;
	signal gate : std_logic;
	signal gateCounterEnabled : std_logic;
	signal gateCounter : unsigned(15 downto 0);
	signal gatingTrigger : std_logic;
	
	signal delayIn : std_logic_vector(15 downto 0);
	signal delayOut : std_logic_vector(15 downto 0);
	
	signal suppressDrs4 : std_logic;
	signal suppressDrs4Request : std_logic;
	signal suppressDrs4In : std_logic;
	signal suppressDrs4In_old : std_logic;
	signal suppressDrs4Counter : unsigned(15 downto 0);

begin

	registerRead.triggerSerdesDelay <= registerWrite.triggerSerdesDelay;
	registerRead.triggerMask <= registerWrite.triggerMask;
	registerRead.triggerGeneratorEnabled <= registerWrite.triggerGeneratorEnabled;
--	registerRead.sameEventTime <= registerWrite.sameEventTime;
	registerRead.gateTime <= registerWrite.gateTime;
--	sameEventTime <= registerWrite.sameEventTime;
	registerRead.drs4Decimator <= registerWrite.drs4Decimator;

	registerRead.drs4TriggerDelay <= registerWrite.drs4TriggerDelay;
	
	registerRead.triggerGeneratorPeriod <= registerWrite.triggerGeneratorPeriod;

	trigger.triggerNotDelayed <= pixelTriggerNotDelayed;
	trigger.triggerDelayed <= pixelTriggerDelayed;
	trigger.triggerSerdesNotDelayed <= pixelSerdeMaskedNotDelayed;
	trigger.triggerSerdesDelayed <= pixelSerdeMaskedDelayed;
	
	--trigger.singleSoftTrigger <= singleSoftTrigger or triggerGeneratorTrigger;
	--flasherTrigger <= ledFlasherPreTrigger;
	trigger.flasherTrigger <= ledFlasherPreTrigger;
	trigger.flasherTriggerGate <= gate;
	gatingTrigger <= ledFlasherPreTrigger or singleSoftTrigger or triggerGeneratorTrigger;
	--trigger.stopDrs4 <= gatingTrigger;
	--trigger.eventFifoSystem <= trigger.triggerNotDelayed or trigger.singleSoftTrigger
	--trigger.eventFifoSystem <= flasherTrigger or singleSoftTrigger or triggerGeneratorTrigger;
	--trigger.stopDrs4 <= delayOut(0);
	suppressDrs4In <= delayOut(0);
	trigger.timingAndDrs4 <= delayOut(0) and not suppressDrs4; -- ## hack
	trigger.timingOnly <= delayOut(0) and suppressDrs4; -- ## hack
	
	--trigger.sumTriggerSameEvent <= sumTriggerSameEvent;
	pixelTriggerNotDelayed <= '1' when (pixelSerdeMaskedNotDelayed /= x"00") else '0';
	pixelTriggerDelayed <= '1' when (pixelSerdeMaskedDelayed /= x"00") else '0';

	--triggerToRate(0) <= pixelTriggerDelayed; -- ## hack!!11!
	--sumTrigger <= pixelTriggerDelayed; -- ## better: use 'notDelayed' trigger and delay the result... 
	trigger.newData <= newData;
	
--	registerRead.counterPeriod <= registerWrite.counterPeriod;
--	trigger.counterPeriod <= registerWrite.counterPeriod;
--	g0: for i in 0 to rateChannels-1 generate -- ## hack....
--		trigger.rateLatched <= std_logic_vector(rateLatched(i));
--		trigger.rateDeadTimeLatched <= std_logic_vector(rateDeadTimeLatched(i));
--		registerRead.rateLatched <= std_logic_vector(rateLatched(i));
--		registerRead.rateDeadTimeLatched <= std_logic_vector(rateDeadTimeLatched(i));
--		--registerRead.rate <= std_logic_vector(rateCounter(i));
--	end generate;

	-- pixel
	g1: for i in 0 to numberOfChannels-1 generate
		triggerMasked(i) <= pixelInSerdes(8*i+7 downto 8*i+0) when ((registerWrite.triggerMask(i) = '0') and (pixelTriggerDisabled = '0')) else x"00";
	end generate;
		
	pixelSerdeMaskedNotDelayed <= triggerMasked(0) or triggerMasked(1) or triggerMasked(2) or triggerMasked(3) or triggerMasked(4) or triggerMasked(5) or triggerMasked(6) or triggerMasked(7); -- vector of time slots ## ?!?!
	
	e0: entity work.triggerLogicDelayFifo port map(registerWrite.clock, fifoClear, pixelSerdeMaskedNotDelayed, fifoWrite, fifoRead, pixelSerdeMaskedDelayed, open, open);

	delayIn <= (0 => gatingTrigger, others=>'0');
	e1: entity work.delayLine_16x512 port map (registerWrite.clock, registerWrite.reset, registerWrite.drs4TriggerDelay, registerWrite.drs4TriggerDelayReset, delayIn, delayOut);
	
	P0:process (registerWrite.clock)
	begin
		if rising_edge(registerWrite.clock) then
			fifoClear <= '0'; -- autoreset	
			fifoWrite <= '1'; -- autoreset
			fifoRead <= '1'; -- autoreset
			singleSoftTrigger <= '0'; -- autoreset
			if (registerWrite.reset = '1') then
				fifoClear <= '1'; -- autoreset
				stateDelay <= init1;
				singleSeq_old <= '0';
				pixelTriggerDisabled <= '0';
			else
				singleSeq_old <= registerWrite.singleSeq;
				if((registerWrite.singleSeq = '1') and (singleSeq_old = '0')) then
					pixelTriggerDisabled <= '0';
					registerRead.singleSeq <= '1';
				end if;
				if((registerWrite.singleSeq = '1') and (pixelTriggerNotDelayed = '1')) then
					pixelTriggerDisabled <= '1';
					registerRead.singleSeq <= '0';
				end if;

				registerSoftTrigger_old <= registerWrite.singleSoftTrigger;
				if((registerSoftTrigger_old = '0') and (registerWrite.singleSoftTrigger = '1')) then
					singleSoftTrigger <= '1'; -- autoreset
				end if;

				case stateDelay is
					when init1 =>
						fifoClear <= '1'; -- autoreset
						fifoWrite <= '0'; -- autoreset
						fifoRead <= '0'; -- autoreset
						stateDelay <= init2;
						delayCounter <= 0;

					when init2 =>
						fifoRead <= '0'; -- autoreset
						delayCounter <= delayCounter + 1;
						if(delayCounter >= to_integer(unsigned(registerWrite.triggerSerdesDelay))) then
							stateDelay <= run;
						end if;
						
					when run =>
						if(registerWrite.triggerSerdesDelayInit = '1') then
							stateDelay <= init1;
						end if;

					when others => stateDelay <= init1;
				end case;
			end if;
		end if;
	end process P0;

	P1:process (registerWrite.clock)
	begin
		if rising_edge(registerWrite.clock) then
			triggerGeneratorTrigger <= '0'; -- autoreset
			if (registerWrite.reset = '1') then
				triggerGeneratorCounter <= (others=>'0');
			else
				if(registerWrite.triggerGeneratorEnabled = '1') then
					triggerGeneratorCounter <= triggerGeneratorCounter + 1;
					if(triggerGeneratorCounter >= unsigned(registerWrite.triggerGeneratorPeriod)) then
						triggerGeneratorCounter <= (others=>'0');
						triggerGeneratorTrigger <= '1'; -- autoreset
					end if;
				end if;
			end if;
		end if;
	end process P1;

--	-- # hack...
--	P2:process (registerWrite.clock)
--	begin
--		if rising_edge(registerWrite.clock) then
--			newData <= '0'; -- autoreset
--			if(registerWrite.reset = '1') then
--				rateCounter <= (others => (others => '0'));
--				rateCounterInsideDeadTime <= (others => (others => '0'));
--				counter_ms <= (others => '0');
--				counter_sec <= (others => '0');
--				rateLatched <= (others => (others => '0'));
--				rateDeadTimeLatched <= (others => (others => '0'));
--				realTimeDeltaCounter <= (others => '0');
----				realTimeDeltaCounterLatched <= (others => '0');
--				sumTrigger_old <= '0';
--				--sumTrigger <= '0';
--				sumTriggerSameEvent <= '0';
--				sameEventCounter <= (others => '0');
--			else
--				triggerToRate_old <= triggerToRate;
--				realTimeDeltaCounter <= realTimeDeltaCounter + 1;
--				
--				sumTrigger_old <= sumTrigger;
--
--				if(internalTiming.tick_ms = '1') then
--					counter_ms <= counter_ms + 1;
--				end if;
--				if(counter_ms >= x"03e7") then
--					counter_ms <= (others => '0');
--					counter_sec <= counter_sec + 1;
--				end if;
--				
--				if((sumTrigger_old = '0') and (sumTrigger = '1') and (sumTriggerSameEvent = '0')) then
--					sumTriggerSameEvent <= '1'; -- ## lag
--					sameEventCounter <= (others => '0');
--				end if;
--				if(sumTriggerSameEvent = '1') then
--					sameEventCounter <= sameEventCounter + 1; -- ## more lag
--				end if;
--				if(sameEventCounter >= unsigned(sameEventTime)) then -- ## even more lag
--					sameEventCounter <= (others => '0'); 
--					sumTriggerSameEvent <= '0';
--				end if;
--					
--				for i in 0 to rateChannels-1 loop
--					if((triggerToRate_old(i) = '0') and (triggerToRate(i) = '1')) then
--						rateCounter(i) <= rateCounter(i) + 1;
--						if(rateCounter(i) = x"ffff") then
--							rateCounter(i) <= x"ffff";
--						end if;
--						
--						--if((externalDeadTime = '1') and (sumTriggerSameEvent = '0')) then
--						if(externalDeadTime = '1') then
--							rateCounterInsideDeadTime(i) <= rateCounterInsideDeadTime(i) + 1;
--						end if;
--						if(rateCounterInsideDeadTime(i) = x"ffff") then
--							rateCounterInsideDeadTime(i) <= x"ffff";
--						end if;
--					end if;
--				
--					if(registerWrite.resetCounter = '1') then -- ## hack
--						rateCounter(i) <= (others => '0');
--						rateCounterInsideDeadTime(i) <= (others => '0');
--						realTimeDeltaCounter <= (others => '0');
--					end if;
--				end loop;
--				
--				if(registerWrite.counterPeriod = x"0000") then
--					for i in 0 to rateChannels-1 loop
--						rateLatched(i) <= rateCounter(i);
--						rateDeadTimeLatched(i) <= rateCounterInsideDeadTime(i);
--					end loop;
--				elsif(counter_sec >= unsigned(registerWrite.counterPeriod)) then -- ## rates for continuous operation
--					counter_sec <= (others => '0');
--					
--					rateCounter <= (others => (others => '0'));
--					rateCounterInsideDeadTime <= (others => (others => '0'));
--					
--					rateLatched <= rateCounter;
--					rateDeadTimeLatched <= rateCounterInsideDeadTime;
--					
--					-- if(period2 = foo) then
--					newData <= '1'; -- autoreset
--					--realTimeCounterLatched <= internalTiming.realTimeCounter;
--					-- end if;
----					realTimeDeltaCounterLatched <= std_logic_vector(realTimeDeltaCounter);
--					realTimeDeltaCounter <= (others => '0');
--				end if;
--				
--			end if;
--		end if;
--	end process P2;

	gate <= gatingTrigger or gateCounterEnabled;

	process(registerWrite.clock)
	begin
		if rising_edge(registerWrite.clock) then
			if(registerWrite.reset = '1') then
				gateCounterEnabled <= '0';
				gateCounter <= (others => '0');
			else			
				if((gatingTrigger = '1') or (gateCounterEnabled = '1')) then
					gateCounterEnabled <= '1';
					gateCounter <= gateCounter + 1;
					if(gateCounter > unsigned(registerWrite.gateTime)) then
						gateCounter <= (others => '0');
						gateCounterEnabled <= '0';
					end if;
				end if;
			end if;
		end if;
	end process;

	process(registerWrite.clock)
	begin
		if rising_edge(registerWrite.clock) then
			suppressDrs4In_old <= suppressDrs4In;
			if(registerWrite.reset = '1') then
				suppressDrs4 <= '0';
				suppressDrs4Request <= '0';
				suppressDrs4Counter <= (others=>'0');
			else
				if((suppressDrs4In = '1') and (suppressDrs4In_old = '0')) then
					suppressDrs4Counter <= suppressDrs4Counter + 1;

					if(suppressDrs4Counter >= unsigned(registerWrite.drs4Decimator)) then
						suppressDrs4Request <= '0';
						suppressDrs4Counter <= (others => '0');
					else
						suppressDrs4Request <= '1';
					end if;
				end if;
				if((suppressDrs4In = '0') and (suppressDrs4In_old = '0')) then
					suppressDrs4 <= suppressDrs4Request;
				end if;
			end if;
		end if;
	end process;


end Behavioral;

