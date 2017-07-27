----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:25:23 04/19/2017 
-- Design Name: 
-- Module Name:    testDataGenerator - Behavioral 
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

entity test is
	port(
		trigger : in std_logic;
		
		triggerTiming : out triggerTiming_t;
		gpsTiming : out gpsTiming_t;

		registerRead : out testDataGenerator_registerRead_t;
		registerWrite : in testDataGenerator_registerWrite_t	
	);
end test;

architecture Behavioral of test is
	signal trigger_old : std_logic := '0';
begin

P0:process (registerWrite.clock)
begin
	if rising_edge(registerWrite.clock) then
		-- test ...... 02
	end if;
end process P0;

end Behavioral;

