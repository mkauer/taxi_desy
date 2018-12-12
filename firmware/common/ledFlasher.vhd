----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:13:00 09/28/2018 
-- Design Name: 
-- Module Name:    ledFlasher - Behavioral 
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
library UNISIM;
use UNISIM.VComponents.all;

entity ledFlasher is
	port
	(
		trigger1_p : out std_logic;
		trigger1_n : out std_logic;
		trigger2_p : out std_logic;
		trigger2_n : out std_logic;
		
		sumTriggerOut : out std_logic;
		
		registerRead : out ledFlasher_registerRead_t;
		registerWrite : in ledFlasher_registerWrite_t
	);
end ledFlasher;

architecture behavioral of ledFlasher is
	signal trigger1 : std_logic;
	signal trigger2 : std_logic;
	signal trigger1Positive : std_logic;
	signal trigger2Positive : std_logic;
	
	signal trigger1_delayed : std_logic;
	signal trigger2_delayed : std_logic;
	signal pipeline_1 : std_logic_vector(3 downto 0);
	signal pipeline_2 : std_logic_vector(3 downto 0);

begin
	
	a1: OBUFDS port map (O=>trigger1_p, OB=>trigger1_n, I=>trigger1_delayed);
	a2: OBUFDS port map (O=>trigger2_p, OB=>trigger2_n, I=>trigger2_delayed);

	sumTriggerOut <= trigger1Positive or trigger2Positive;
	
	process (registerWrite.clock)
	begin
		if rising_edge(registerWrite.clock) then
			if(registerWrite.reset = '1') then
				trigger1_delayed <= '0';
				trigger2_delayed <= '0';
				pipeline_1 <= (others=>'0');
				pipeline_2 <= (others=>'0');
			else
				pipeline_1(pipeline_1'length-1) <= trigger1;
				for i in 0 to pipeline_1'length-2 loop
					pipeline_1(i) <= pipeline_1(i+1);
				end loop;
				trigger1_delayed <= pipeline_1(0);

				pipeline_2(pipeline_2'length-1) <= trigger2;
				for i in 0 to pipeline_2'length-2 loop
					pipeline_2(i) <= pipeline_2(i+1);
				end loop;
				trigger2_delayed <= pipeline_2(0);

			end if;
		end if;
	end process;
		

	b0: entity work.pulseGenerator generic map 
	(
		pulsePeriodWidth_bit=>8,
		generatorPeriodWidth_bit=>32,
		clockRate_Hz=>globalClockRate_Hz
	)
	port map
	(
		registerWrite.clock,
		registerWrite.reset,
		trigger1,
		trigger1Positive,
		--trigger1Serdes,
		registerWrite.doSingleShot(0),
		registerWrite.pulseWidth0,
		registerWrite.generatorPeriod0,
		registerWrite.enableGenerator(0),
		registerWrite.useNegativePolarity(0)
	);

	b1: entity work.pulseGenerator generic map 
	(
		pulsePeriodWidth_bit=>8,
		generatorPeriodWidth_bit=>32,
		clockRate_Hz=>globalClockRate_Hz
	)
	port map
	(
		registerWrite.clock,
		registerWrite.reset,
		trigger2,
		trigger2Positive,
		--trigger2Serdes,
		registerWrite.doSingleShot(1),
		registerWrite.pulseWidth1,
		registerWrite.generatorPeriod1,
		registerWrite.enableGenerator(1),
		registerWrite.useNegativePolarity(1)
	);

	registerRead.enableGenerator <= registerWrite.enableGenerator;
	registerRead.useNegativePolarity <= registerWrite.useNegativePolarity;
	registerRead.pulseWidth0 <= registerWrite.pulseWidth0;
	registerRead.pulseWidth1 <= registerWrite.pulseWidth1;
	registerRead.generatorPeriod0 <= registerWrite.generatorPeriod0;
	registerRead.generatorPeriod1 <= registerWrite.generatorPeriod1;
	
--	P0:process (registerWrite.clock)
--	begin
--		if rising_edge(registerWrite.clock) then
--			if (registerWrite.reset = '1') then
--			else
--			end if;
--		end if;
--	end process P0;

end behavioral;

