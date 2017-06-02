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

entity testDataGenerator is
	port(
		trigger : in std_logic;
		
		triggerTiming : out triggerTiming_t;
		dsr4Timing : out dsr4Timing_t;
		dsr4Sampling : out dsr4Sampling_t;
		dsr4Charge : out dsr4Charge_t;
		gpsTiming : out gpsTiming_t;

		registerRead : out testDataGenerator_registerRead_t;
		registerWrite : in testDataGenerator_registerWrite_t	
	);
end testDataGenerator;

architecture Behavioral of testDataGenerator is
	signal trigger_old : std_logic := '0';
	type state8_t is (idle, run);
	signal state8 : state8_t := idle;
begin

P0:process (registerWrite.clock)
begin
	if rising_edge(registerWrite.clock) then
		if (registerWrite.reset = '1') then -- ## sync?!
			state8 <= idle;
		else
			trigger_old <= trigger;

			case state8 is				
				when idle =>
					if((trigger_old = '0') and (trigger = '1'))then
						state8 <= run;
						counter <= 0;
						data <= 0;
					end if;
					
				when run =>
					counter <= counter + 1;
					state8 <= idle;
					
				when others => null;
			end case;
			
		end if;
	end if;
end process P0;

end Behavioral;

