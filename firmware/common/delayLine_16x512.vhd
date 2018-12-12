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


entity delayLine_16x512 is
	port
	(
		clock : in std_logic;
		reset : in std_logic;
		delay : in std_logic_vector(8 downto 0);
		resetDelay : in std_logic;
		i : in std_logic_vector(15 downto 0);
		o : out std_logic_vector(15 downto 0)
	);
end entity;

architecture behavioral of delayLine_16x512 is	
	signal fifoReadRequest : std_logic := '0';
	signal fifoWriteRequest : std_logic := '0';
	signal fifoReset : std_logic := '0';
	
	signal fifoCounter : unsigned(8 downto 0);
	
	signal fifoOut : std_logic_vector(15 downto 0);
	
	--signal numberOfDelayCycles : std_logic_vector(15 downto 0);
	
begin

	z0: entity work.fifo_16x512 port map(
		clk => clock,
		srst => fifoReset,
		din => i,
		wr_en => fifoWriteRequest,
		rd_en => fifoReadRequest,
		dout => fifoOut,
		full => open,
		empty => open
		);

	o <= i when (delay = "000000000") else fifoOut;

	P0:process (clock)
	begin
		if rising_edge(clock) then
			fifoWriteRequest <= '1'; -- autoreset
			fifoReadRequest <= '0'; -- autoreset
			fifoReset <= '0'; -- autoreset
			if ((reset = '1') or (resetDelay = '1')) then
				fifoReset <= '1'; -- autoreset
				fifoCounter <= to_unsigned(1,fifoCounter'length);
				fifoWriteRequest <= '0'; -- autoreset
				fifoReadRequest <= '0'; -- autoreset
			else
				if(fifoCounter >= unsigned(delay)) then 
					fifoReadRequest <= '1'; -- autoreset
				else
					fifoCounter <= fifoCounter + 1;
				end if;
			end if;
		end if;
	end process P0;
	

end behavioral;
