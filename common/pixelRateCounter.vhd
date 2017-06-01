----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    20:29:56 03/08/2017 
-- Design Name: 
-- Module Name:    pixelRateCounter - Behavioral 
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

entity pixelRateCounter is
	port
	(
		triggerPixelIn : in std_logic_vector(8*8-1 downto 0);
		registerRead : out pixelRateCounter_registerRead_t;
		registerWrite : in pixelRateCounter_registerWrite_t
	);
end pixelRateCounter;

architecture behavioral of pixelRateCounter is
	signal pixel : std_logic_vector(7 downto 0) := (others => '0');
	signal pixel_old : std_logic_vector(pixel'length-1 downto 0) := (others => '0');
	type counter_t is array (0 to 8-1) of unsigned(15 downto 0);
	signal pixelCounter : counter_t := (others => (others => '0'));
begin
	P0:process (registerWrite.clock)
	begin
		if rising_edge(registerWrite.clock) then
			if(registerWrite.reset = '1') then
				pixel <= (others => '0');
				pixel_old <= (others => '0');
				pixelCounter <= (others => (others => '0'));
			else
				pixel_old <= pixel;
				
				for i in 0 to 8-1 loop
					if(triggerPixelIn(i*8+7 downto i*8) /= x"00") then
						pixel(i) <= '1';
					else
						pixel(i) <= '0';
					end if;
					
					if((pixel_old(i) = '0') and (pixel(i) = '1')) then
						pixelCounter(i) <= pixelCounter(i) + 1;
					end if;
				end loop;
			
--				if(registerWrite.pps =  '1') then
--					pixelCounter <= (others => (others => '0'));
					registerRead.ch0 <= std_logic_vector(pixelCounter(0));
					registerRead.ch1 <= std_logic_vector(pixelCounter(1));
					registerRead.ch2 <= std_logic_vector(pixelCounter(2));
					registerRead.ch3 <= std_logic_vector(pixelCounter(3));
					registerRead.ch4 <= std_logic_vector(pixelCounter(4));
					registerRead.ch5 <= std_logic_vector(pixelCounter(5));
					registerRead.ch6 <= std_logic_vector(pixelCounter(6));
					registerRead.ch7 <= std_logic_vector(pixelCounter(7));
--				end if;
				
				if(registerWrite.resetCounter /= x"0000") then
					pixelCounter <= (others => (others => '0'));
				end if;
				
			end if;
		end if;
	end process P0;

end behavioral;

