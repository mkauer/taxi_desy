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
--library UNISIM;
--use UNISIM.VComponents.all;

entity ad9649 is
	port
	(
		d : in std_logic_vector(13 downto 0);
		dco : in std_logic;
		outOfRange : in std_logic;
		adcClock_n : out std_logic;
		adcClock_p : out std_logic;
		
		sdio : out std_logic;
		sclk : out std_logic;
		csb : out std_logic;
		
	);
end ad9649;

architecture behavioral of ad9649 is
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

