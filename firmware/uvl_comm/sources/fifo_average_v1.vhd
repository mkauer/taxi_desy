--------------------------------------------------------------------------------
-- Design Name : fifo_average_v1 
-- File Name   : fifo_average_v1.vhd
-- Function    : 
-- Coder       : 
-- Date        : 2019
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use work.types.all;

entity fifo_average_v1 is
	port(
		reset : in std_logic;
		clk : in std_logic;
		dataIn : in std_logic_vector(15 downto 0);
		avgOut : out std_logic_vector(15 downto 0);
		avgFactor : in std_logic_vector(3 downto 0) -- power of 2
	   );
end entity;

architecture behavior of fifo_average_v1 is

	attribute keep : string;
	
	signal counter : unsigned(15 downto 0);  
	
	signal fifoIn : std_logic_vector(15 downto 0);
	signal fifoOut : std_logic_vector(15 downto 0);
	signal fifoWrite : std_logic;
	signal fifoRead : std_logic;
	signal fifoEmpty : std_logic;
	signal fifoWords : std_logic_vector(15 downto 0);
	signal fifoClear : std_logic;
	signal avgFactorOld : std_logic_vector(3 downto 0);

	type avrState_t is (debug0, sync0, sync1, sync2, sync3, idle);
	signal avrState: avrState_t;

	signal avgSum : signed(19 downto 0);
	signal avgSumScope : signed(19 downto 0);
	attribute keep of avgSumScope : signal is "true";
	--signal avgSum : unsigned(15+10 downto 0);
	--attribute keep of avgSum : signal is "true";

	signal avgOutInternal : std_logic_vector(15 downto 0);
	signal avgReady : std_logic;
	--signal avgFactorIntern : std_logic_vector(3 downto 0);
	
	signal fifoInBuffer : signed(15 downto 0);
	signal fifoOutBuffer : signed(15 downto 0);
	
	signal dataInBuffer : std_logic_vector(15 downto 0);
	signal softReset : std_logic;

begin

	fifoIn <= dataInBuffer;
	--avgFactorIntern <= avgFactor;

	e0: entity work.fifo_16x512 port map
	(
		clk         => clk,
		srst        => fifoClear,
		wr_en       => fifoWrite,
		rd_en       => fifoRead,
		din         => fifoIn,
		dout        => fifoOut, 
		full        => fifoWords(9),
		empty       => fifoEmpty
		--data_count => fifoWords(8 downto 0)
	);
			

	--avgOut <= avgOutInternal when avgReady = '1' else dataIn;
	process(clk)
	begin
		if(rising_edge(clk)) then
			dataInBuffer <= dataIn;
			avgSumScope <= avgSum;
			if(avgReady = '1') then
				avgOut <= avgOutInternal;
			else
				avgOut <= dataInBuffer;
			end if;
		end if;
	end process;

	avgOutInternal <= "00" & std_logic_vector(avgSum(17 downto 4));
	
--	with avgFactorIntern select
--		avgOutInternal <= std_logic_vector(avgSum(15 downto 0)) when x"0",
--				  std_logic_vector(avgSum(16 downto 1)) when x"1",
--				  std_logic_vector(avgSum(17 downto 2)) when x"2",
--				  std_logic_vector(avgSum(18 downto 3)) when x"3",
--				  std_logic_vector(avgSum(19 downto 4)) when x"4",
--				  std_logic_vector(avgSum(20 downto 5)) when x"5",
--				  std_logic_vector(avgSum(21 downto 6)) when x"6",
--				  std_logic_vector(avgSum(22 downto 7)) when x"7",
--				  std_logic_vector(avgSum(23 downto 8)) when x"8",
--				  std_logic_vector(avgSum(24 downto 9)) when x"9",
--				  std_logic_vector(avgSum(25 downto 10)) when x"a",
--				  std_logic_vector(avgSum(25 downto 10)) when others;

	fifoInBuffer <= signed("00"&fifoIn(13 downto 0));
	--fifoOutBuffer <= fifoOut(13 downto 0);

	process(clk)
	begin
		if(rising_edge(clk)) then
			fifoClear <= '0'; --autoreset
			fifoWrite <= '1'; --autoreset
			fifoRead <= '1'; --autoreset
			avgFactorOld <= avgFactor;
			avgReady <= '0'; -- autoreset
			--fifoInBuffer <= fifoIn;
			fifoOutBuffer <= signed("00"&fifoOut(13 downto 0));
			softReset <= '0'; -- autoreset
			if((reset = '1') or (softReset = '1')) then
				avrState <= debug0;
				--avrState <= sync0;
				avgSum <= (others=>'0');
				counter <= (others=>'0');
				fifoClear <= '1'; --autoreset
				fifoWrite <= '0'; --autoreset
				fifoRead <= '0'; --autoreset
			else
				case(avrState) is
					when debug0 =>
						counter <= counter + 1;
						if(counter >= x"fffe") then
							avrState <= sync0;
						end if;
					
					when sync0 =>
						fifoClear <= '1'; --autoreset
						fifoWrite <= '0'; --autoreset
						fifoRead <= '0'; --autoreset
						avrState <= sync1;
						counter <= (others=>'0');
						avgSum <= (others=>'0');
					
					when sync1 =>
						fifoRead <= '0'; --autoreset
						fifoWrite <= '0'; --autoreset
						avrState <= sync2;
					
					when sync2 =>
						fifoRead <= '0'; --autoreset
						avrState <= sync3;

					when sync3 =>
						avgSum <= avgSum + fifoInBuffer;
						fifoRead <= '0'; --autoreset
						counter <= counter + 1;
						--if(counter >= 2**to_integer(unsigned(avgFactorIntern))-3) then
						if(counter = to_unsigned(2,counter'length)) then
							fifoRead <= '1'; --autoreset
						end if;
						
						if(counter >= to_unsigned(15,counter'length)) then -- TODO: debuging: set to 2^^4
							avrState <= idle;
							fifoRead <= '1'; --autoreset
						end if;

					when idle =>
						avgSum <= avgSum + (fifoInBuffer - fifoOutBuffer);
						avrState <= idle;
						avgReady <= '1'; -- autoreset

				end case;
				
				--if(avgFactorOld /= avgFactor) then -- debug
				if((avgFactor(0) = '1') and (avgFactorOld(0) = '0')) then -- debug
					--avrState <= sync0;
					softReset <= '1'; -- autoreset
				end if;

			end if;
		end if;
	end process;

end architecture;
