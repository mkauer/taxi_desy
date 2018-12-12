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
--use work.types_platformSpecific.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity rateCounter is
	port
	(
		clock : in std_logic;
		reset : in std_logic;
--		pixelSerdesIn : in std_logic_vector(7 downto 0);
		pixelIn : in std_logic;

		gate : in std_logic;
		allRisingEdges : out std_logic_vector(15 downto 0);
		firstHitsDuringGate : out std_logic_vector(15 downto 0);
		additionalHitsDuringGate : out std_logic_vector(15 downto 0)
	);
end rateCounter;

architecture behavioral of rateCounter is
	signal sameEvent : std_logic;
	signal pixel : std_logic;
	signal pixel_old : std_logic;
	
	signal pixelCounterAllRisingEdges : unsigned(15 downto 0);
	signal pixelCounterFirstHitsDuringGate : unsigned(15 downto 0);
	signal pixelCounterAdditionalHitsDuringGate : unsigned(15 downto 0);

begin
--	pixel <= '1' when (pixelIn(7 downto 0) /= x"00") else '0'; -- ## this has odd time slot dependencys.... fast pulses can concartinate
	pixel <= pixelIn;

	allRisingEdges <= std_logic_vector(pixelCounterAllRisingEdges);
	firstHitsDuringGate <= std_logic_vector(pixelCounterFirstHitsDuringGate);
	additionalHitsDuringGate <= std_logic_vector(pixelCounterAdditionalHitsDuringGate);

	P0:process (clock)
	begin
		if rising_edge(clock) then
			if(reset = '1') then -- or (resetAllCounter = '1')) then
				pixel_old <= pixel;
				sameEvent <= '0';
				
				pixelCounterAllRisingEdges <= (others => '0');
				pixelCounterFirstHitsDuringGate <= (others => '0');
				pixelCounterAdditionalHitsDuringGate <= (others => '0');
			else
				pixel_old <= pixel;
				
				if(gate = '0') then
					sameEvent <= '0';
				end if;

				if((pixel_old = '0') and (pixel = '1')) then
					pixelCounterAllRisingEdges <= pixelCounterAllRisingEdges + 1;
					if(pixelCounterAllRisingEdges = x"ffff") then
						pixelCounterAllRisingEdges <= x"ffff";
					end if;

					if(gate = '1') then
						if(sameEvent = '0') then
							sameEvent <= '1';
							pixelCounterFirstHitsDuringGate <= pixelCounterFirstHitsDuringGate + 1;
							if(pixelCounterFirstHitsDuringGate = x"ffff") then
								pixelCounterFirstHitsDuringGate <= x"ffff";
							end if;
						else
							pixelCounterAdditionalHitsDuringGate <= pixelCounterAdditionalHitsDuringGate + 1;
							if(pixelCounterAdditionalHitsDuringGate = x"ffff") then
								pixelCounterAdditionalHitsDuringGate <= x"ffff";
							end if;
						end if;
					end if;
				end if;
			end if;
		end if;
	end process P0;

end behavioral;

