----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:43:42 03/13/2017 
-- Design Name: 
-- Module Name:    triggerDataDelay - Behavioral 
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


entity triggerDataDelay is
	port
	(
		triggerPixelIn : in triggerSerdes_t;
		triggerPixelOut : out triggerSerdes_t; 
		registerRead : out triggerDataDelay_registerRead_t;
		registerWrite : in triggerDataDelay_registerWrite_t
	);
end triggerDataDelay;

architecture behavioral of triggerDataDelay is	
	signal fifoReadRequest : std_logic := '0';
	signal fifoWriteRequest : std_logic := '0';
	signal fifoReset : std_logic := '0';
	
	signal fifoCounter : unsigned(15 downto 0) := x"0000";
	
	signal numberOfDelayCycles : std_logic_vector(15 downto 0);
	
begin
	
	g0: for i in 0 to 2 generate 
		delay: entity work.delayFifo port map(
			clk => registerWrite.clock,
			srst => fifoReset,
			din => triggerPixelIn(i),
			wr_en => fifoWriteRequest,
			rd_en => fifoReadRequest,
			dout => triggerPixelOut(i),
			full => open,
			empty => open
			);
	end generate;

	P0:process (registerWrite.clock)
	begin
		if rising_edge(registerWrite.clock) then
			fifoWriteRequest <= '1'; -- autoreset
			fifoReadRequest <= '0'; -- autoreset
			fifoReset <= '0'; -- autoreset
			if ((registerWrite.reset = '1') or (registerWrite.resetDelay = '1')) then
				fifoReset <= '1'; -- autoreset
				fifoCounter <= to_unsigned(0,fifoCounter'length);
				fifoWriteRequest <= '0'; -- autoreset
				fifoReadRequest <= '0'; -- autoreset
			else
				if(fifoCounter >= unsigned(numberOfDelayCycles)) then 
					fifoReadRequest <= '1'; -- autoreset
				else
					fifoCounter <= fifoCounter + 1;
				end if;
			end if;
		end if;
	end process P0;
	
	numberOfDelayCycles <= registerWrite.numberOfDelayCycles when(registerWrite.numberOfDelayCycles < x"00ff") else x"00ff";
	registerRead.numberOfDelayCycles <= numberOfDelayCycles;

end behavioral;
