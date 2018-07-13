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
	triggerPixelIn : in std_logic_vector(8*numberOfChannels-1 downto 0);
	deadTime : in std_logic;
	internalTiming : in internalTiming_t;
	trigger : out triggerLogic_t;
	registerRead : out triggerLogic_registerRead_t;
	registerWrite : in triggerLogic_registerWrite_t	
	);
end triggerLogic;

architecture Behavioral of triggerLogic is
	
	signal triggerSerdesNotDelayed : std_logic_vector(7 downto 0) := (others=>'0');
	signal triggerSerdesDelayed : std_logic_vector(7 downto 0) := (others=>'0');
	--variable triggerOutSerdes_v : std_logic_vector(7 downto 0) := (others=>'0');
	signal triggerMasked : data8x8Bit_t := (others=>(others=>'0'));
	
	signal fifoClear : std_logic := '0';
	signal fifoWrite : std_logic := '0';
	signal fifoRead : std_logic := '0';
	type stateDelay_t is (init1, init2, run);
	signal stateDelay : stateDelay_t := init1;
	signal delayCounter : integer range 0 to 2047 := 0;
	
	signal registerSoftTrigger_old : std_logic := '0';
	signal softTrigger : std_logic := '0';
	signal triggerDisabled : std_logic := '0';
	signal singleSeq_old : std_logic := '0';
	signal triggerNotDelayed : std_logic := '0';
	signal triggerNotDelayed_old : std_logic := '0';
	signal triggerDelayed : std_logic := '0';
	
	signal triggerGeneratorCounter : unsigned(31 downto 0) := (others=>'0');
	signal triggerGeneratorTrigger : std_logic := '0';

	constant rateChannels : integer := 1;
	type counter_t is array (0 to rateChannels-1) of unsigned(15 downto 0);
	signal rateCounter : counter_t := (others => (others => '0'));
	signal rateCounterInsideDeadTime : counter_t := (others => (others => '0'));
	signal triggerToRate : std_logic_vector(rateChannels-1 downto 0) := (others=>'0');
	signal triggerToRate_old : std_logic_vector(rateChannels-1 downto 0) := (others=>'0');
	signal newData : std_logic := '0';
	signal counter_ms : unsigned(15 downto 0) := (others => '0');
	signal counter_sec : unsigned(15 downto 0) := (others => '0');
	signal rateLatched : counter_t := (others => (others => '0'));
	signal rateDeadTimeLatched : counter_t := (others => (others => '0'));
	signal realTimeDeltaCounter : unsigned(63 downto 0) := (others=>'0');
--	signal realTimeDeltaCounterLatched : std_logic_vector(63 downto 0) := (others=>'0');
--	signal realTimeCounterLatched : std_logic_vector(63 downto 0) := (others=>'0');
	
	signal sumTrigger : std_logic := '0';
	signal sumTrigger_old : std_logic := '0';
	
	signal sumTriggerSameEvent : std_logic := '0';
	signal sameEventCounter : unsigned(11 downto 0) := (others => '0');
	signal sameEventTime : std_logic_vector(11 downto 0) := (others => '0');

begin

	registerRead.triggerSerdesDelay <= registerWrite.triggerSerdesDelay;
	registerRead.triggerMask <= registerWrite.triggerMask;
	registerRead.triggerGeneratorEnabled <= registerWrite.triggerGeneratorEnabled;
	registerRead.sameEventTime <= registerWrite.sameEventTime;
	sameEventTime <= registerWrite.sameEventTime;
	
	registerRead.triggerGeneratorPeriod <= registerWrite.triggerGeneratorPeriod;

	--registerRead.trigger.triggerNotDelayed <= triggerNotDelayed;
	--registerRead.trigger.triggerDelayed <= triggerDelayed;
	--registerRead.trigger.triggerSerdesNotDelayed <= triggerSerdesNotDelayed;
	--registerRead.trigger.triggerSerdesDelayed <= triggerSerdesDelayed;
	
	trigger.triggerNotDelayed <= triggerNotDelayed;
	trigger.triggerDelayed <= triggerDelayed;
	trigger.triggerSerdesNotDelayed <= triggerSerdesNotDelayed;
	trigger.triggerSerdesDelayed <= triggerSerdesDelayed;
	trigger.softTrigger <= softTrigger or triggerGeneratorTrigger;
	trigger.sumTriggerSameEvent <= sumTriggerSameEvent;
	--triggerNotDelayed <= '1' when (((triggerPixelIn /= (triggerPixelIn'range => '0')) or (softTrigger = '1')) and (triggerDisabled = '0')) else '0';
	triggerNotDelayed <= '1' when (triggerSerdesNotDelayed /= x"00") else '0';
	triggerDelayed <= '1' when (triggerSerdesDelayed /= x"00") else '0';


	triggerToRate(0) <= triggerDelayed; -- ## hack!!11!
	sumTrigger <= triggerDelayed; -- ## better: use 'notDelayed' trigger and delay the result... 
	trigger.newData <= newData;
	registerRead.counterPeriod <= registerWrite.counterPeriod;
	trigger.counterPeriod <= registerWrite.counterPeriod;
	--trigger.realTimeCounterLatched <= realTimeCounterLatched;
--	trigger.realTimeDeltaCounterLatched <= realTimeDeltaCounterLatched;
	g0: for i in 0 to rateChannels-1 generate -- ## hack....
		trigger.rateLatched <= std_logic_vector(rateLatched(i));
		trigger.rateDeadTimeLatched <= std_logic_vector(rateDeadTimeLatched(i));
		registerRead.rateLatched <= std_logic_vector(rateLatched(i));
		registerRead.rateDeadTimeLatched <= std_logic_vector(rateDeadTimeLatched(i));
		--registerRead.rate <= std_logic_vector(rateCounter(i));
	end generate;


	g1: for i in 0 to numberOfChannels-1 generate
		triggerMasked(i) <= triggerPixelIn(8*i+7 downto 8*i+0) when ((registerWrite.triggerMask(i) = '0') and (triggerDisabled = '0')) else x"00";
	end generate;
		
	--triggerSerdesNotDelayed <= triggerPixelIn(7 downto 0) or triggerPixelIn(15 downto 8) or triggerPixelIn(23 downto 16) or triggerPixelIn(31 downto 24) or triggerPixelIn(39 downto 32) or triggerPixelIn(47 downto 40) or triggerPixelIn(55 downto 48) or triggerPixelIn(63 downto 56);
	triggerSerdesNotDelayed <= triggerMasked(0) or triggerMasked(1) or triggerMasked(2) or triggerMasked(3) or triggerMasked(4) or triggerMasked(5) or triggerMasked(6) or triggerMasked(7); -- vector of time slots ## ?!?!
	
	e0: entity work.triggerLogicDelayFifo port map(registerWrite.clock, fifoClear, triggerSerdesNotDelayed, fifoWrite, fifoRead, triggerSerdesDelayed, open, open);

	
	P0:process (registerWrite.clock)
	begin
		if rising_edge(registerWrite.clock) then
			fifoClear <= '0'; -- autoreset	
			fifoWrite <= '1'; -- autoreset
			fifoRead <= '1'; -- autoreset
			softTrigger <= '0'; -- autoreset
			if (registerWrite.reset = '1') then
				fifoClear <= '1'; -- autoreset
				stateDelay <= init1;
				singleSeq_old <= '0';
				triggerDisabled <= '0';
			else
				singleSeq_old <= registerWrite.singleSeq;
				if((registerWrite.singleSeq = '1') and (singleSeq_old = '0')) then
					triggerDisabled <= '0';
					registerRead.singleSeq <= '1';
				end if;
				if((registerWrite.singleSeq = '1') and (triggerNotDelayed = '1')) then
					triggerDisabled <= '1';
					registerRead.singleSeq <= '0';
				end if;

				registerSoftTrigger_old <= registerWrite.softTrigger;
				if((registerSoftTrigger_old = '0') and (registerWrite.softTrigger = '1')) then
					softTrigger <= '1'; -- autoreset
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

	-- # hack...
	P2:process (registerWrite.clock)
	begin
		if rising_edge(registerWrite.clock) then
			newData <= '0'; -- autoreset
			if(registerWrite.reset = '1') then
				rateCounter <= (others => (others => '0'));
				rateCounterInsideDeadTime <= (others => (others => '0'));
				counter_ms <= (others => '0');
				counter_sec <= (others => '0');
				rateLatched <= (others => (others => '0'));
				rateDeadTimeLatched <= (others => (others => '0'));
				realTimeDeltaCounter <= (others => '0');
--				realTimeDeltaCounterLatched <= (others => '0');
				sumTrigger_old <= '0';
				--sumTrigger <= '0';
				sumTriggerSameEvent <= '0';
				sameEventCounter <= (others => '0');
			else
				triggerToRate_old <= triggerToRate;
				realTimeDeltaCounter <= realTimeDeltaCounter + 1;
				
				sumTrigger_old <= sumTrigger;

				if(internalTiming.tick_ms = '1') then
					counter_ms <= counter_ms + 1;
				end if;
				if(counter_ms >= x"03e7") then
					counter_ms <= (others => '0');
					counter_sec <= counter_sec + 1;
				end if;
				
				if((sumTrigger_old = '0') and (sumTrigger = '1') and (sumTriggerSameEvent = '0')) then
					sumTriggerSameEvent <= '1'; -- ## lag
					sameEventCounter <= (others => '0');
				end if;
				if(sumTriggerSameEvent = '1') then
					sameEventCounter <= sameEventCounter + 1; -- ## more lag
				end if;
				if(sameEventCounter >= unsigned(sameEventTime)) then -- ## even more lag
					sameEventCounter <= (others => '0'); 
					sumTriggerSameEvent <= '0';
				end if;
					
				for i in 0 to rateChannels-1 loop
					if((triggerToRate_old(i) = '0') and (triggerToRate(i) = '1')) then
						rateCounter(i) <= rateCounter(i) + 1;
						if(rateCounter(i) = x"ffff") then
							rateCounter(i) <= x"ffff";
						end if;
						
						--if((deadTime = '1') and (sumTriggerSameEvent = '0')) then
						if(deadTime = '1') then
							rateCounterInsideDeadTime(i) <= rateCounterInsideDeadTime(i) + 1;
						end if;
						if(rateCounterInsideDeadTime(i) = x"ffff") then
							rateCounterInsideDeadTime(i) <= x"ffff";
						end if;
					end if;
				
					if(registerWrite.resetCounter = '1') then -- ## hack
						rateCounter(i) <= (others => '0');
						rateCounterInsideDeadTime(i) <= (others => '0');
						realTimeDeltaCounter <= (others => '0');
					end if;
				end loop;
				
				if(registerWrite.counterPeriod = x"0000") then
					for i in 0 to rateChannels-1 loop
						rateLatched(i) <= rateCounter(i);
						rateDeadTimeLatched(i) <= rateCounterInsideDeadTime(i);
					end loop;
				elsif(counter_sec >= unsigned(registerWrite.counterPeriod)) then -- ## rates for continuous operation
					counter_sec <= (others => '0');
					
					rateCounter <= (others => (others => '0'));
					rateCounterInsideDeadTime <= (others => (others => '0'));
					
					rateLatched <= rateCounter;
					rateDeadTimeLatched <= rateCounterInsideDeadTime;
					
					-- if(period2 = foo) then
					newData <= '1'; -- autoreset
					--realTimeCounterLatched <= internalTiming.realTimeCounter;
					-- end if;
--					realTimeDeltaCounterLatched <= std_logic_vector(realTimeDeltaCounter);
					realTimeDeltaCounter <= (others => '0');
				end if;
				
			end if;
		end if;
	end process P2;


end Behavioral;

