--------------------------------------------------------------------------------
-- Design Name : uart_v2
-- File Name   : uart_v2.vhd
-- Function    : UART with FIFO and echo loops for debuging
-- Coder       : Marko Kossatz, DESY
-- Date        : 2019
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

entity uart_v2 is
  port(
    reset          : in std_logic;
    clk            : in std_logic;
	
    uartIn : in std_logic;
    uartOut : out std_logic;
	
	dataOut : out std_logic_vector(7 downto 0);
	fifoOutRead : in std_logic;
	fifoOutEmpty : out std_logic;
	
	dataIn : in std_logic_vector(7 downto 0);
	fifoInWrite : in std_logic;
	fifoInFull : out std_logic
	
	--baudRx : in std_logic_vector (7 downto 0);
	--baudTx : in std_logic_vector (7 downto 0);
	--echoModes : in std_logic_vector (7 downto 0);
	
	--debug : out std_logic
     );
end entity;

architecture uart_v2_arch of uart_v2 is

	attribute keep : string;
	
	signal uartFifo0 : std_logic_vector(7 downto 0);
	signal uartFifoWrite0 : std_logic;
	signal baudRateDivisorRx : unsigned(15 downto 0);
	signal baudRateDivisorTx : unsigned(15 downto 0);
	signal uartFifo1 : std_logic_vector(7 downto 0);
	signal uartFifoRead1 : std_logic;
	signal fifoEmpty1 : std_logic;
	
	signal fifoWords0 : std_logic_vector(11 downto 0);
	attribute keep of fifoWords0 : signal is "true";
	signal fifoWords1 : std_logic_vector(11 downto 0);
	attribute keep of fifoWords1 : signal is "true";
	
	--signal uartOut_i : std_logic;
	--signal uartIn_i : std_logic;

begin

	baudRateDivisorRx <= i2u(51,16);
	baudRateDivisorTx <= i2u(500,16); -- +2,75%

	--uartIn_b <= uartIn when echoModes(2) = '0' else '0';
	--uartIn_c <= uartOut_i when echoModes(1) = '1' else '0';
	--uartOut <= uartIn when echoModes(0) = '1' else uartOut_i;

	--uartIn_a <= uartIn_b or uartIn_c;

	x0: entity work.uart_receiver_v2 port map
	(
		reset          => reset,
		clk            => clk,
		rxIn           => uartIn,
		dataOut        => uartFifo0,
		newData        => uartFifoWrite0,
		baudRateDivisor => baudRateDivisorRx
	);

	x1: entity work.fifo_4kx8 port map
	(
		clk         => clk,
		srst        => reset,
		din         => uartFifo0,
		wr_en       => uartFifoWrite0,
		rd_en       => fifoOutRead,
		dout        => dataOut, 
		full        => open,
		empty       => fifoOutEmpty,
		data_count	=> fifoWords0
	);

	x2: entity work.uart_transmitter_v2 port map
	(
		reset          		=> reset,
		clk            		=> clk,
		txOut         		=> uartOut,
		dataIn 				=> uartFifo1,
		fifoRead	 		=> uartFifoRead1,
		fifoEmpty	 		=> fifoEmpty1,
		baudRateDivisor		=> baudRateDivisorTx
	);

	x3: entity work.fifo_4kx8 port map
	(
		clk         => clk,
		srst        => reset,
		din         => dataIn,
		wr_en       => fifoInWrite,
		rd_en       => uartFifoRead1,
		dout        => uartFifo1, 
		full        => fifoInFull,
		empty       => fifoEmpty1,
		data_count	=> fifoWords1
	);

end architecture;
