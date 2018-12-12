----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:13:00 09/28/2018 
-- Design Name: 
-- Module Name:    pulseGenerator - Behavioral 
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

entity pulseGenerator is
	generic
	(
		pulsePeriodWidth_bit : integer := 8;
		generatorPeriodWidth_bit : integer := 16;
		clockRate_Hz : integer := 125000000
	);
	port
	(
		clock : in std_logic;
		reset : in std_logic;
		pulse : out std_logic;
		pulseAlwaysPositive : out std_logic;
		--pulseSerdes : out std_logic_vector(7 downto 0);
		
		doSingleShot : in std_logic;
		pulseWidth : in std_logic_vector(pulsePeriodWidth_bit-1 downto 0);
		generatorPeriod : in std_logic_vector(generatorPeriodWidth_bit-1 downto 0);
		enableGenerator : in std_logic;
		useNegativePolarity : in std_logic
	);
end pulseGenerator;

architecture behavioral of pulseGenerator is
	signal triggerOut : std_logic := '0';
	signal trigger_latched : std_logic := '0';

	signal pulseWidthCounter : unsigned(pulsePeriodWidth_bit-1 downto 0);
	signal triggerGeneratorCounter : unsigned(generatorPeriodWidth_bit-1 downto 0);
	
--	signal counter_us : integer range 0 to 511 := 0;
--	signal counter_us_done : std_logic := '0';
	
	type stateTrigger_t is (idle, active);
	signal stateTrigger : stateTrigger_t := idle;

	signal triggerGenerator : std_logic := '0';

begin
	P0:process (clock)
	begin
		if rising_edge(clock) then
			triggerOut <= '0'; -- autoreset
			triggerGenerator <= '0'; -- autoreset
--			counter_us_done <= '0'; -- autoreset
			pulse <= triggerOut xor useNegativePolarity;
			pulseAlwaysPositive <= triggerOut;
			if (reset = '1') then
				trigger_latched <= '0';
				pulseWidthCounter <= (others=>'0');
				triggerGeneratorCounter <= to_unsigned(1, triggerGeneratorCounter'length);
				stateTrigger <= idle;
--				counter_us <= 0;
			else
				trigger_latched <= trigger_latched or doSingleShot or triggerGenerator;
				
				case stateTrigger is
					when idle =>
						if(trigger_latched = '1') then
							pulseWidthCounter <= (others=>'0');
							--pulseWidthCounter <= to_unsigned(1, pulseWidthCounter'length);
							stateTrigger <= active;
						end if;

					when active =>
						triggerOut <= '1'; -- autoreset
						pulseWidthCounter <= pulseWidthCounter + 1;
						if(pulseWidthCounter >= unsigned(pulseWidth)) then
							stateTrigger <= idle; -- ## deadTime;
							trigger_latched <= '0';
						end if;
					
					--when deadTime =>
					--	stateTrigger <= idle;

					when others => null;
				end case;

--				counter_us => counter_us + 1;
--				if(counter_us = (clockRate_Hz/1000)-1) then
--					counter_us <= 0;
--					counter_us_done <= '1'; -- autoreset
--				end if;

--				if((enableGenerator = '1') and (counter_us_done = '1')) then
				if(enableGenerator = '1') then
					triggerGeneratorCounter <= triggerGeneratorCounter + 1;
					if(triggerGeneratorCounter >= unsigned(generatorPeriod)) then
						--triggerGeneratorCounter <= (others=>'0');
						triggerGeneratorCounter <= to_unsigned(1, triggerGeneratorCounter'length);
						triggerGenerator <= '1'; -- autoreset
					end if;
				end if;

			end if;
		end if;
	end process P0;

end behavioral;

