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
use work.types_platformSpecific.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity pixelRateCounter_polarstern is
	port
	(
		triggerPixelIn : in std_logic_vector(8*numberOfChannels_platformSpecific-1 downto 0);
		pixelRateCounter : out pixelRateCounter_polarstern_t;
		internalTiming : in internalTiming_t;
		registerRead : out pixelRateCounter_polarstern_registerRead_t;
		registerWrite : in pixelRateCounter_polarstern_registerWrite_t
	);
end pixelRateCounter_polarstern;

architecture behavioral of pixelRateCounter_polarstern is
	signal pixel : std_logic_vector_xCannel_t := (others => '0');
	signal pixel_old : std_logic_vector(pixel'length-1 downto 0) := (others => '0');
	type counter_t is array (0 to numberOfChannels_platformSpecific-1) of unsigned(15 downto 0);
	signal pixelCounter : counter_t := (others => (others => '0'));
	signal pixelCounterLatched : counter_t := (others => (others => '0'));
	signal counter_ms : unsigned(15 downto 0) := (others => '0');
	signal counter_sec : unsigned(15 downto 0) := (others => '0');
	signal realTimeDeltaCounter : unsigned(63 downto 0) := (others=>'0');
	signal newData : std_logic := '0';
	signal newDataLatched : std_logic := '0';
	signal newDataLatchedReset : std_logic := '0';
begin

	registerRead.counterPeriod <= registerWrite.counterPeriod;
	pixelRateCounter.counterPeriod <= registerWrite.counterPeriod;
				
	pixelRateCounter.newData <= newData;
	registerRead.newDataLatched <= newDataLatched;
	newDataLatchedReset <= registerWrite.newDataLatchedReset;

	g0: for i in 0 to numberOfChannels_platformSpecific-1 generate
		registerRead.pixelCounterAllEdgesLatched(i) <= std_logic_vector(pixelCounterLatched(i));
		pixelRateCounter.channelLatched(i) <= std_logic_vector(pixelCounterLatched(i));
	end generate;

	P0:process (registerWrite.clock)
	begin
		if rising_edge(registerWrite.clock) then
			newData <= '0'; -- autoreset
			if(registerWrite.reset = '1') then
				pixel <= (others => '0');
				pixel_old <= (others => '0');
				pixelCounter <= (others => (others => '0'));
				counter_ms <= (others => '0');
				counter_sec <= (others => '0');
				pixelCounterLatched <= (others => (others => '0'));
				realTimeDeltaCounter <= (others => '0');
				newDataLatched <= '0';
			else
				pixel_old <= pixel;
				realTimeDeltaCounter <= realTimeDeltaCounter + 1;
			
				newDataLatched <= newDataLatched and not(newDataLatchedReset);

				if(internalTiming.tick_ms = '1') then
					counter_ms <= counter_ms + 1;
				end if;
				if(counter_ms >= x"03e7") then
					counter_ms <= (others => '0');
					counter_sec <= counter_sec + 1;
				end if;
				
				if(registerWrite.resetCounterTime = '1') then
					counter_ms <= (others => '0');
					counter_sec <= (others => '0');
				end if;

				for i in 0 to numberOfChannels_platformSpecific-1 loop
					if(triggerPixelIn(i*8+7 downto i*8) /= x"00") then -- ## this has odd time slot dependencys.... fast pulses can concartinate
						pixel(i) <= '1';
					else
						pixel(i) <= '0';
					end if;
					
					if((pixel_old(i) = '0') and (pixel(i) = '1')) then
						pixelCounter(i) <= pixelCounter(i) + 1;
						if(pixelCounter(i) = x"ffff") then
							pixelCounter(i) <= x"ffff";
						end if;
					end if;
				
					if((registerWrite.resetCounter(i) = '1') or (registerWrite.resetAllCounter = '1')) then
						pixelCounter(i) <= (others => '0');
						realTimeDeltaCounter <= (others => '0');
					end if;
				end loop;
				
				if(registerWrite.counterPeriod = x"0000") then
						pixelCounterLatched <= pixelCounter;
				elsif(counter_sec >= unsigned(registerWrite.counterPeriod)) then
					counter_sec <= (others => '0');
					pixelCounter <= (others => (others => '0'));
						
					pixelCounterLatched <= pixelCounter;
					
					newData <= '1'; -- autoreset
					newDataLatched <= '1';
					pixelRateCounter.realTimeCounterLatched <= internalTiming.realTimeCounter;
					pixelRateCounter.realTimeDeltaCounterLatched <= std_logic_vector(realTimeDeltaCounter);
					realTimeDeltaCounter <= (others => '0');
				end if;
				
			end if;
		end if;
	end process P0;

end behavioral;

