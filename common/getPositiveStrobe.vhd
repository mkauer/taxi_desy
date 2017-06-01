----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:33:18 03/24/2017 
-- Design Name: 
-- Module Name:    getPositiveStrobe - Behavioral 
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

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity getPositiveStrobe is
	port
	(
		clock : in std_logic;
		i : in std_logic;
		o : out std_logic
	);
end getPositiveStrobe;

architecture behavioral of getPositiveStrobe is
	signal s : std_logic := '0';
	signal i_old : std_logic := '0';

begin
	
	o <= i and s;

	P0:process (clock)
	begin
		if rising_edge(clock) then
			i_old <= i;
			if((i_old = '0') and (i = '1')) then
				s <= '0';
			end if;
			if(i = '0') then
				s <= '1';
			end if;
		end if;
	end process P0;

end behavioral;

