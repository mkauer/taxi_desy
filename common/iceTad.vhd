----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:49:38 06/23/2017 
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
use IEEE.numeric_std.all;
use work.types.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity iceTad is
port(
	nP24VOn : out std_logic_vector(7 downto 0);
	nP24VOnTristate : out std_logic_vector(7 downto 0);
	rs485DataIn : in std_logic_vector(7 downto 0);
	rs485DataOut : out std_logic_vector(7 downto 0);
	rs485DataTristate : out std_logic_vector(7 downto 0);
	rs485DataEnable : out std_logic_vector(7 downto 0);
	registerRead : out iceTad_registerRead_t;
	registerWrite : in iceTad_registerWrite_t	
	);
end iceTad;

architecture Behavioral of iceTad is
	
	signal dfdf : std_logic_vector(7 downto 0) := (others=>'0');
	type stateDelay_t is (init1, init2, run);
	signal stateDelay : stateDelay_t := init1;
	signal delayCounter : integer range 0 to 2047 := 0;
	
begin

	registerRead.powerOn <= registerWrite.powerOn;
	
	nP24VOn <= (others=>'0');
	rs485DataOut <= (others=>'0');
	rs485DataTristate <= (others=>'1');
	rs485DataEnable <= (others=>'0');

	P1:process (registerWrite.clock)
	begin
		if rising_edge(registerWrite.clock) then
			if (registerWrite.reset = '1') then
				nP24VOnTristate <= (others=>'1');
			else
				q:for i in 0 to registerWrite.powerOn'length-1 loop
					if(registerWrite.powerOn(i) = '1') then
						nP24VOnTristate(i) <= '0';
					else
						nP24VOnTristate(i) <= '1';
					end if;
				end loop;
			end if;
		end if;
	end process P1;

end Behavioral;

