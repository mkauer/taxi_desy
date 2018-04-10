----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:43:23 09/08/2017 
-- Design Name: 
-- Module Name:    internalTiming - Behavioral 
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

entity internalTiming is
	generic(
		clockRate_kHz : integer -- := 118750
	);
	port(
		internalTiming : out internalTiming_t;
		registerRead : out internalTiming_registerRead_t;
		registerWrite : in internalTiming_registerWrite_t	
	);
end internalTiming;

architecture behavioral of internalTiming is
	
	signal tick_ms : std_logic := '0';
	signal counter_clock : integer range 0 to 2**17-1 := 0;
	signal realTimeCounter : unsigned(63 downto 0) := (others=>'0');
	
begin

internalTiming.realTimeCounter <= std_logic_vector(realTimeCounter);
internalTiming.tick_ms <= tick_ms;
--registerRead.tick_ms <= tick_ms;

P0:process (registerWrite.clock)
begin
	if rising_edge(registerWrite.clock) then
		tick_ms <= '0'; -- autoreset
		if (registerWrite.reset = '1') then
			counter_clock <= 1;
			realTimeCounter <= (others=>'0');
		else
			realTimeCounter <= realTimeCounter + 1;
			
			counter_clock <= counter_clock + 1;
			if(counter_clock = clockRate_kHz) then
				counter_clock <= 1;
				tick_ms <= '1'; -- autoreset
			end if;
		end if;
	end if;
end process P0;

end behavioral;

