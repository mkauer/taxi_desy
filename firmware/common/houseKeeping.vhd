----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:13:00 09/28/2018 
-- Design Name: 
-- Module Name:    ad9649 - Behavioral 
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
--use IEEE.numeric_std.all;
use work.types.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity houseKeeping is
	port
	(
		notLedEnable_pin : out std_logic;
		notLedGreen_pin : out std_logic;
		notLedRed_pin : out std_logic;
		enableJ24TestPins : out std_logic;
		
		registerRead : out houseKeeping_registerRead_t;
		registerWrite : in houseKeeping_registerWrite_t
	);
end houseKeeping;

architecture behavioral of houseKeeping is
	signal notLedEnable : std_logic;
	signal notLedGreen : std_logic;
	signal notLedRed : std_logic;

begin
	
	i0: OBUFT port map(O => notLedEnable_pin, I => notLedEnable, T => notLedEnable);
	i1: OBUFT port map(O => notLedGreen_pin, I => notLedGreen, T => notLedGreen);
	i2: OBUFT port map(O => notLedRed_pin, I => notLedRed, T => notLedRed);
	
	registerRead.enablePcbLeds <= registerWrite.enablePcbLeds;
	registerRead.enablePcbLedGreen <= registerWrite.enablePcbLedGreen;
	registerRead.enablePcbLedRed <= registerWrite.enablePcbLedRed;
	registerRead.enableJ24TestPins <= registerWrite.enableJ24TestPins;

	notLedEnable <= not registerWrite.enablePcbLeds;
	notLedGreen <= not registerWrite.enablePcbLedGreen;
	notLedRed <= not registerWrite.enablePcbLedRed;
	enableJ24TestPins <= registerWrite.enableJ24TestPins;
	
--	P0:process (registerWrite.clock)
--	begin
--		if rising_edge(registerWrite.clock) then
--			if rising_edge(registerWrite.reset) then
--			else
--			end if;
--		end if;
--	end process P0;

end behavioral;

