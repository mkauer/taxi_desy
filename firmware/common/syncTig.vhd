----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:13:00 09/28/2018 
-- Design Name: 
-- Module Name:    syncTig - Behavioral 
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

entity syncTig is
	generic
	(
		WIDTH : integer := 0
	);
	port
	(
		clk_o : in std_logic;
		i : in std_logic_vector(WIDTH-1 downto 0);
		o : out std_logic_vector(WIDTH-1 downto 0)
	);
end entity;

architecture behavioral of syncTig is
	signal temp_TPTHRU_TIG : std_logic_vector(WIDTH-1 downto 0);
	signal temp_1 : std_logic_vector(WIDTH-1 downto 0);
begin

	p0: process(clk_o)
	begin
		if(rising_edge(clk_o)) then
			o <= temp_1; 
			temp_1 <= temp_TPTHRU_TIG; 
			temp_TPTHRU_TIG <=i;
		end if;
	end process p0;

end behavioral;

