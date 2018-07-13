----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:18:20 03/27/2017 
-- Design Name: 
-- Module Name:    histogram - Behavioral 
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
library UNISIM;
use UNISIM.VComponents.all;

entity histogram is
	port(
		ltm9007_14_to_eventFifoSystem : in ltm9007_14_to_eventFifoSystem_t;
		
		registerRead : out histogram_registerRead_t;
		registerWrite : in histogram_registerWrite_t	
	);
end histogram;

architecture Behavioral of histogram is
	signal fifoWordsB : std_logic_vector(4 downto 0) := (others=>'0');
	signal fifoReadClock : std_logic := '0';
	
	type stateAdcFifoData_t is (idle, skip, valid1, valid2);
	signal stateAdcFifoData : stateAdcFifoData_t := idle;
	
	signal chargeBuffer : data8x24Bit_t;
	signal baselineBuffer : data8x24Bit_t;
	
begin
	
	registerRead.testMode <= registerWrite.testMode;
	
	x7: entity work.histogramRam port map(
		registerWrite.clock,
		wea,
		adda,
		dina,
		registerWrite.clock,
		open
	);

	g110: for i in 0 to 7 generate
		x110: entity work.drs4OffsetCorrectionRam port map(
			registerWrite.clock,
			offsetCorrectionRamData(i)
		);
	end generate;

P0:process (registerWrite.clock)
begin
	if rising_edge(registerWrite.clock) then
		if (registerWrite.reset = '1') then
		else
			ltm9007_14_to_eventFifoSystem.baseline <= baselineBuffer;
		end if;
	end if;
end process P0;






---------------


---------------






end Behavioral;

