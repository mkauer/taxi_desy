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

entity pulseShaper is
--entity pulseStretcher is
generic(
		numberOfChannels_g : integer := 8;
		pulsePolarity : string := "POSITIVE"
		--mode : string := "changeMinAndMax";
		--mode : string := "changeMin";
		--mode : string := "changeMax";
		--mode : string := "append";
		--mode : string := "remove";
		--min : integer := 0;
		--max : integer := 0;
		--add : integer := 0;
	);
port(
	clock : in std_logic;
	reset : in std_logic;
	i : in std_logic_vector(numberOfChannels_g-1 downto 0);
	o : out std_logic_vector(numberOfChannels_g-1 downto 0)
	);
end pulseShaper;

architecture Behavioral of pulseShaper is
	signal i_old : std_logic_vector(numberOfChannels_g-1 downto 0) := (others => '0');
	signal iStretch : std_logic_vector(numberOfChannels_g-1 downto 0) := (others => '0');
begin

g0: if pulsePolarity = "POSITIVE" generate
	P0:process (clock)
	begin
		if rising_edge(clock) then
			if(reset = '1') then
				i_old <= (others => '0');
				iStretch <= (others => '0');
			else
				for m in 0 to numberOfChannels_g-1 loop
					if((i_old(m) = '0') and (i(m) = '1')) then
						iStretch(m) <= '1';
					else
						iStretch(m) <= '0';
					end if;
				end loop;
				i_old <= i;
				o <= i or iStretch;
			end if;
		end if;
	end process P0;
end generate g0;

assert pulsePolarity /= "NEGATIVE" report "pulseShaper with negative polarity is used but not implemented" severity failure;
--g1: if pulsePolarity = "NEGATIVE" generate
--end generate g1;

end Behavioral;

