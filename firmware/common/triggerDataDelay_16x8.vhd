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


entity triggerDataDelay_16x8 is
	port
	(
		triggerPixelIn : in std_logic_vector(16*8-1 downto 0);
		triggerPixelOut : out std_logic_vector(16*8-1 downto 0);
		registerRead : out triggerDataDelay_registerRead_t;
		registerWrite : in triggerDataDelay_registerWrite_t
	);
end triggerDataDelay_16x8;

architecture behavioral of triggerDataDelay_16x8 is	
	signal fifoReadRequest : std_logic := '0';
	signal fifoWriteRequest : std_logic := '0';
	signal fifoReset : std_logic := '0';
	
	signal fifoCounter : unsigned(15 downto 0) := (others=>'0');
	
	signal numberOfDelayCycles : std_logic_vector(15 downto 0);
	
begin
	
	registerRead.numberOfDelayCycles <= registerWrite.numberOfDelayCycles;
	numberOfDelayCycles <= registerWrite.numberOfDelayCycles;

	delayA: entity work.fifo_64x256 port map(
		clk => registerWrite.clock,
		srst => fifoReset,
		din => triggerPixelIn(8*8-1 downto 0),
		wr_en => fifoWriteRequest,
		rd_en => fifoReadRequest,
		dout => triggerPixelOut(8*8-1 downto 0),
		full => open,
		empty => open
		);

	delayB: entity work.fifo_64x256 port map(
		clk => registerWrite.clock,
		srst => fifoReset,
		din => triggerPixelIn(16*8-1 downto 8*8),
		wr_en => fifoWriteRequest,
		rd_en => fifoReadRequest,
		dout => triggerPixelOut(16*8-1 downto 8*8),
		full => open,
		empty => open
		);

	P0:process (registerWrite.clock)
	begin
		if rising_edge(registerWrite.clock) then
			fifoWriteRequest <= '1'; -- autoreset
			fifoReadRequest <= '0'; -- autoreset
			fifoReset <= '0'; -- autoreset
			if ((registerWrite.reset = '1') or (registerWrite.resetDelay = '1')) then
				fifoReset <= '1'; -- autoreset
				fifoCounter <= (others=>'0');
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
	

end behavioral;
