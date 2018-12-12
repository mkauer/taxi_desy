----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    20:29:56 03/08/2017 
-- Design Name: 
-- Module Name:    pixelRateCounter - Behavioral 
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
--use work.types_platformSpecific.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity pixelRateCounter_v2 is
	port
	(
		pixelIn : in std_logic_vector(8*numberOfChannels-1 downto 0);
		triggerGate : in std_logic;
--		trigger : in triggerLogic_t;
		rateCounterNewData : out std_logic;
		pixelRateCounter : out pixelRateCounter_v2_t;
		internalTiming : in internalTiming_t;
		registerRead : out pixelRateCounter_v2_registerRead_t;
		registerWrite : in pixelRateCounter_v2_registerWrite_t
	);
end pixelRateCounter_v2;

architecture behavioral of pixelRateCounter_v2 is
	signal sameEvent : std_logic_vector(numberOfChannels-1 downto 0) := (others => '0'); -- is like sampling dead time, not readout dead time... trigger that are close will be count as one / same event..... all per channel, not the best way to do this....
	type counter2_t is array (0 to numberOfChannels-1) of unsigned(7 downto 0);
	signal pixel : std_logic_vector(numberOfChannels-1 downto 0) := (others => '0');
	signal rateAllEdges_latched : dataNumberOfChannelsX16Bit_t := (others => (others => '0'));
	signal rateFirstHitsDuringGate_latched : dataNumberOfChannelsX16Bit_t := (others => (others => '0'));
	signal rateAdditionalHitsDuringGate_latched : dataNumberOfChannelsX16Bit_t := (others => (others => '0'));
	signal c1 : dataNumberOfChannelsX16Bit_t := (others => (others => '0'));
	signal c2 : dataNumberOfChannelsX16Bit_t := (others => (others => '0'));
	signal c3 : dataNumberOfChannelsX16Bit_t := (others => (others => '0'));
	signal counter_ms : integer range 0 to 1023;
	signal counter_sec : unsigned(15 downto 0) := (others => '0');
	signal realTimeDeltaCounter : unsigned(63 downto 0) := (others=>'0');
	signal realTimeDeltaCounterLatched : std_logic_vector(63 downto 0) := (others=>'0');
	signal realTimeCounterLatched : std_logic_vector(63 downto 0) := (others=>'0');

	signal newData : std_logic := '0';
	signal newData_latched : std_logic := '0';

	signal rateCounterReset : std_logic_vector(numberOfChannels-1 downto 0);
	signal gate : std_logic;
	signal gateCounterEnabled : std_logic;
	signal gateCounter : unsigned(15 downto 0);

begin

	--registerRead.gateTimeout <= registerWrite.gateTimeout;
	registerRead.rateCounterPeriod <= registerWrite.rateCounterPeriod;
	pixelRateCounter.rateCounterPeriod <= registerWrite.rateCounterPeriod;

	pixelRateCounter.realTimeCounterLatched <= realTimeCounterLatched;
	pixelRateCounter.realTimeDeltaCounterLatched <= realTimeDeltaCounterLatched;

	g0: for i in 0 to numberOfChannels-1 generate
		pixelRateCounter.rateAllEdgesLatched(i) <= rateAllEdges_latched(i);
		pixelRateCounter.rateFirstHitsDuringGateLatched(i) <= rateFirstHitsDuringGate_latched(i);
		pixelRateCounter.rateAdditionalHitsDuringGateLatched(i) <= rateAdditionalHitsDuringGate_latched(i);
		
		registerRead.rateAllEdgesLatched(i) <= rateAllEdges_latched(i);
		registerRead.rateFirstHitsDuringGateLatched(i) <= rateFirstHitsDuringGate_latched(i);
		registerRead.rateAdditionalHitsDuringGateLatched(i) <= rateAdditionalHitsDuringGate_latched(i);
		
		g1: entity work.rateCounter port map(registerWrite.clock, rateCounterReset(i), pixel(i), gate, c1(i), c2(i), c3(i));
	end generate;
	
	rateCounterNewData <= newData;
	pixelRateCounter.newData <= newData;
	registerRead.newData <= newData_latched;
	
--	gate <= externalTrigger or gateCounterEnabled;
--	gate <= trigger.flasherTriggerGate;
	gate <= triggerGate;

	P0:process (registerWrite.clock)
	begin
		if rising_edge(registerWrite.clock) then
			newData <= '0'; -- autoreset
			--rateCounterReset <= (others => '0'); --autoreset
			rateCounterReset <= registerWrite.resetCounter; --autoreset
			if(registerWrite.reset = '1') then
				counter_ms <= 0;
				counter_sec <= (others => '0');
				
--				gateCounter <= (others => '0');
--				gateCounterEnabled <= '0';
				
				rateAllEdges_latched <= (others => (others => '0'));
				rateFirstHitsDuringGate_latched <= (others => (others => '0'));
				rateAdditionalHitsDuringGate_latched <= (others => (others => '0'));
				
				realTimeDeltaCounter <= (others => '0');
				realTimeDeltaCounterLatched <= (others => '0');
				realTimeCounterLatched <= (others => '0');
				sameEvent <= (others => '0');
				newData_latched <= '0';
			
				rateCounterReset <= (others => '1'); --autoreset
			else
				newData_latched <= (newData_latched or newData) and not registerWrite.newDataReset;
				
				for i in 0 to numberOfChannels-1 loop
					if(pixelIn(i*8+7 downto i*8) /= x"00") then -- ## this has odd time slot dependencys.... fast pulses can concartinate
						pixel(i) <= '1';
					else
						pixel(i) <= '0';
					end if;
				end loop;

--				if((externalTrigger = '1') or (gateCounterEnabled = '1')) then
--					gateCounterEnabled <= '1';
--					gateCounter <= gateCounter + 1;
--					if(gateCounter > unsigned(registerWrite.gateTimeout)) then
--						gateCounter <= (others => '0');
--						gateCounterEnabled <= '0';
--					end if;
--				end if;

				realTimeDeltaCounter <= realTimeDeltaCounter + 1;

				if(internalTiming.tick_ms = '1') then
					counter_ms <= counter_ms + 1;
				end if;
				if(counter_ms >= 1000) then
					counter_ms <= 0;
					counter_sec <= counter_sec + 1;
				end if;
				
				if(registerWrite.rateCounterPeriod = x"0000") then
					rateAllEdges_latched <= c1;
					rateFirstHitsDuringGate_latched <= c2;
					rateAdditionalHitsDuringGate_latched <= c3;
				elsif(counter_sec >= unsigned(registerWrite.rateCounterPeriod)) then 
					counter_sec <= (others => '0');
					
					rateAllEdges_latched <= c1;
					rateFirstHitsDuringGate_latched <= c2;
					rateAdditionalHitsDuringGate_latched <= c3;
					
					rateCounterReset <= (others => '1'); --autoreset
					
					newData <= '1'; -- autoreset
					realTimeCounterLatched <= internalTiming.realTimeCounter;
					realTimeDeltaCounterLatched <= std_logic_vector(realTimeDeltaCounter);
					realTimeDeltaCounter <= (others => '0');
				end if;
			end if;
		end if;
	end process P0;

end behavioral;

