----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    20:41:43 03/08/2017 
-- Design Name: 
-- Module Name:    triggerTimeToRisingEdge - Behavioral 
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

entity timeToRisingEdge_v1 is
	port
	(
		clock : in std_logic;
		reset : in std_logic;
		serdesIn : in std_logic_vector(7 downto 0);
		gate : in std_logic;
		timeToRisingEdge : out std_logic_vector(15 downto 0);
		noEdgeDetected : out std_logic;
		newData : out std_logic;
		newDataValid : out std_logic
	);
end entity;

architecture behavioral of timeToRisingEdge_v1 is
	type state_t is (idle, sample, latch);
	signal state : state_t;
	signal pixelCounter : unsigned(15 downto 0);
	signal pixelCounterLatched : unsigned(15 downto 0);
	--signal newData : std_logic;
	signal noEdge : std_logic;

begin
	
	timeToRisingEdge <= std_logic_vector(pixelCounterLatched);
	noEdgeDetected <= noEdge;

	P0:process (clock)
	begin
		if rising_edge(clock) then
			newData <= '0';
			noEdge <= '0';
			if (reset = '1') then
				pixelCounter <= (others => '0');
				pixelCounterLatched <= (others => '0');
				state <= idle;
				newDataValid <= '0';
			else
				case state is
					when idle =>
						pixelCounter <= (others => '0');
						if(gate = '1') then
							newDataValid <= '0';
							state <= sample;
							pixelCounter <= x"000" &  countZerosFromRight8(serdesIn); -- ## syntax ?!?!?!
							if(serdesIn /= x"00") then 
								state <= latch;
							end if;
						end if;
								
					when sample =>
						pixelCounter <= pixelCounter + countZerosFromRight8(serdesIn);
						if(gate = '0') then 
							state <= latch;
							noEdge <= '1';
						end if;
						if(serdesIn /= x"00") then 
							state <= latch;
						end if;
						
					when latch =>
						pixelCounterLatched <= pixelCounter;
						state <= idle;
						noEdge <= noEdge;
						newData <= '1';
						newDataValid <= '1';
					
				end case;
			end if;
		end if;
	end process P0;

end behavioral;
