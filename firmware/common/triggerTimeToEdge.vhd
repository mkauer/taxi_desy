----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    20:41:43 03/08/2017 
-- Design Name: 
-- Module Name:    triggerTimeToRisingEdge - Behavioral 
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

entity triggerTimeToEdge is
	port
	(
		triggerPixelIn : in std_logic_vector(8*numberOfChannels-1 downto 0);
		trigger : in std_logic;
		--dataOut : out std_logic_vector(16*numberOfChannels-1 downto 0);
		--dataReady : out std_logic;
		registerRead : out triggerTimeToEdge_registerRead_t;
		registerWrite : in triggerTimeToEdge_registerWrite_t;
		triggerTiming : out triggerTimeToEdge_t
	);
end triggerTimeToEdge;

architecture behavioral of triggerTimeToEdge is
	type state_t is (idle, sample, latch, prepare);
	signal state1 : state_t := idle;
	type counter_t is array (0 to numberOfChannels-1) of unsigned(15 downto 0);
	signal pixelConterRising : counter_t := (others => (others => '0'));
	signal pixelConterRisingLatched : counter_t := (others => (others => '0'));
	signal pixelConterFalling : counter_t := (others => (others => '0'));
	signal pixelConterFallingLatched : counter_t := (others => (others => '0'));
	signal pixelCounterRisingStop : std_logic_vector(numberOfChannels-1 downto 0);
	signal pixelCounterFallingStop : std_logic_vector(numberOfChannels-1 downto 0);
	signal timeoutCounter : unsigned(11 downto 0) := x"000";
--	constant timeout : integer := 24; -- ~8ns*24 = 200ns
	signal dataValid : std_logic := '0';
	signal triggerPixelIn_old : std_logic_vector(numberOfChannels-1 downto 0);
	
begin
	
--	g: for i in 0 to numberOfChannels-1 generate
--		dataOut(i*16+15 downto i*16) <= std_logic_vector(pixelConterRisingLatched(i));
--	end generate;

	registerRead.maxSearchTime <= registerWrite.maxSearchTime;

	P0:process (registerWrite.clock)
	begin
		if rising_edge(registerWrite.clock) then
			if (registerWrite.reset = '1') then
				pixelConterRising <= (others => (others => '0'));
				pixelCounterRisingStop <= (others => '0');
				pixelConterFalling <= (others => (others => '0'));
				pixelCounterFallingStop <= (others => '0');
				dataValid <= '0';
				state1 <= idle;
				triggerPixelIn_old <= (others => '0');
			else
				for i in 0 to numberOfChannels-1 loop
					triggerPixelIn_old(i) <= triggerPixelIn(i*8+7);
				end loop;

				case state1 is
					when idle =>
						if(trigger = '1') then
							state1 <= sample;
							dataValid <= '0';
							triggerTiming.newData <= '0';
						end if;
						pixelConterRising <= (others => (others => '0'));
						pixelCounterRisingStop <= (others => '0');
						pixelConterFalling <= (others => (others => '0'));
						pixelCounterFallingStop <= (others => '0');
						timeoutCounter <= x"001";
								
					when sample =>
						timeoutCounter <= timeoutCounter + 1;
						if(timeoutCounter >= unsigned(registerWrite.maxSearchTime)) then -- 1 tick is ~8ns
							state1 <= latch;
						end if;

						-- riging edge
						for i in 0 to numberOfChannels-1 loop
							if(pixelCounterRisingStop(i) = '0') then
								pixelConterRising(i) <= pixelConterRising(i) + countZerosFromRight8(triggerPixelIn(i*8+7 downto i*8));
								if(triggerPixelIn(i*8+7 downto i*8) /= x"00") then 
									pixelCounterRisingStop(i) <= '1';
								end if;
							end if;
						end loop;

						-- falling edge
						for i in 0 to numberOfChannels-1 loop
							if(pixelCounterFallingStop(i) = '0') then
								pixelConterFalling(i) <= pixelConterFalling(i) + findFallingEdgeFromRight9(triggerPixelIn(i*8+7 downto i*8) & triggerPixelIn_old(i));
								if(findFallingEdgeFromRight9(triggerPixelIn(i*8+7 downto i*8) & triggerPixelIn_old(i)) /= "1000") then
									pixelCounterFallingStop(i) <= '1';
								end if;
							end if;
						end loop;
						
					when latch =>
						pixelConterRisingLatched <= pixelConterRising;
						state1 <= prepare;
						--dataReady <= '1';
						triggerTiming.newData <= '1';
						for i in 0 to numberOfChannels-1 loop
							registerRead.timeToRisingEdge(i) <= std_logic_vector(pixelConterRising(i));
							registerRead.timeToFallingEdge(i) <= std_logic_vector(pixelConterFalling(i));
							triggerTiming.timeToRisingEdge(i) <= std_logic_vector(pixelConterRising(i));
							triggerTiming.timeToFallingEdge(i) <= std_logic_vector(pixelConterFalling(i));
						end loop;	
					
					when prepare =>
						if(trigger = '0') then
							state1 <= idle;
						end if;

				end case;
			end if;
		end if;
	end process P0;

end behavioral;
