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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity triggerSystem is
generic(
--	serdesFactor : integer := 8;
	numberOfChannels : integer := 8;
	)
port(
	clock : in std_logic;
	reset : in std_logic;
	triggerIn : in std_logic_vector(8*numberOfChannels-1 downto 0);
	triggerOut : out std_logic
	);
end triggerSystem;

architecture Behavioral of triggerSystem is

begin

	triggerOut <= '1' when (triggerIn /= (triggerIn'range => '0')) else '0';

end Behavioral;

