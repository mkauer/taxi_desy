----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    20:09:33 03/08/2017 
-- Design Name: 
-- Module Name:    pulseStretcher - Behavioral 
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
use ieee.numeric_std.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity pulseStretcher is
generic(
		numberOfChannels : integer := 8
	);
port(
	clock : in std_logic;
	reset : in std_logic;
	i : in std_logic_vector(numberOfChannels-1 downto 0);
	o : out std_logic_vector(numberOfChannels-1 downto 0)
	);
end pulseStretcher;

architecture Behavioral of pulseStretcher is
	signal i_old : std_logic_vector(numberOfChannels-1 downto 0) := (others => '0');
	signal iStretch : std_logic_vector(numberOfChannels-1 downto 0) := (others => '0');
	--signal iStretched : std_logic_vector(numberOfChannels-1 downto 0) := (others => '0');
begin

	P0:process (clock)
	begin
		if rising_edge(clock) then
			if(reset = '1') then
				i_old <= (others => '0');
				iStretch <= (others => '0');
	--			iStretched <= (others => '0');
			else
				for m in 0 to numberOfChannels-1 loop
					i_old(m) <= i(m);
					if((i_old(m) = '0') and (i(m) = '1')) then
						iStretch(m) <= '1';
					else
						iStretch(m) <= '0';
					end if;
					o(m) <= i(m) or iStretch(m);
				end loop;
			end if;
		end if;
	end process P0;
end Behavioral;

