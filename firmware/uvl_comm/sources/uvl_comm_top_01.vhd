-------------------------------------------------------
-- Design Name      : uvl_comm_top_01 
-- File Name        : uvl_comm_top_01.vhd
-- Device           : Spartan 6, XC6SLX16CSG324-3
-- Migration Device : Spartan 6, XC6SLX45CSG324-3
-- Function         : UV-logger mainboard FPGA, communication module, top level design,
-- Coder            : K.-H. Sulanke, DESY, 2018-11-13
-------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;
library unisim ;
use unisim.vcomponents.all ;

entity uvl_comm_top_01 is 
	port(    
		clk           : in  std_logic;  -- 60 MHz system clock
		com_clk       : in  std_logic;  -- 60 MHz communication clock

	  -- ************************ Bank #1, VCCO = 2.5V  ****************************************************

		COM_ADC_D     : in  std_logic_vector(13 downto 0);    -- communication ADC output
		COM_ADC_OR    : in  std_logic;  -- out of range signal
		COM_ADC_CSBn  : out std_logic; --
		COM_ADC_SCLK  : out std_logic; --
		COM_ADC_SDIO  : out std_logic; -- is inout
		COM_ADC_DCO   : in  std_logic; -- dedicated clock pin, data clock

	  -- ************************ Bank #2, VCCO = 2.5V  ****************************************************

		COM_ADC_CLK_P : out std_logic;  -- LVDS, comm. ADC  clock     
		COM_ADC_CLK_N : out std_logic;  -- 

	  -- ************************ Bank #3, VCCO = 3.3V  ****************************************************

		COM_DAC_DB    : out std_logic_vector(11 downto 0);    -- connected to communication DAC
		COM_DAC_CLOCK : out std_logic;  -- 
										-- naming based on stamp view
		uartCableToArm0    : out std_logic;  -- stamp debug uart 
		uartArmToCable0    : in  std_logic; --     
		uartCableToArm1    : out std_logic; -- PB5, stamp uart
		uartArmToCable1    : in  std_logic; -- PB4, 
		
		debugOut : out std_logic_vector(7 downto 0);

	  --TEST_IO       : out std_logic_vector(3 downto 0) -- 3.3V CMOS / LVDS bidir. test port, p/n=1/0 or 3/2  
--		TEST_IO0       : out std_logic;
--		TEST_IO1       : out std_logic;
--		TEST_IO2       : out std_logic;
--		TEST_IO3       : out std_logic
--		commDebug_0r : out commDebug_registerRead_t;
		commDebug_0w_x : in commDebug_registerWrite_t
	);
end uvl_comm_top_01;

architecture arch_uvl_comm_top_01 of uvl_comm_top_01 is

	signal reset         : std_logic := '0'; -- synchronous power up reset
  --signal clk           : std_logic := '0'; -- by PLL
	signal com_reset     : std_logic := '0'; -- synchronous power up reset
  --signal com_clk       : std_logic := '0'; -- by PLL, 8b10b communication clock domain

  -- UART signals, rx/tx by FPGA view

	signal rx_uart_ena            : std_logic; -- from baudrate generator
	signal tx_uart_ena            : std_logic;

	signal tx_uart_data_valid_a   : std_logic;
	signal tx_uart_data_in_a      : std_logic_vector (7 downto 0);
	signal tx_uart_ack_a          : std_logic;
	signal tx_uart_out_a          : std_logic;  -- connect to serial data output

	--signal rx_uart_in_a           : std_logic;  -- connect to serial data input
	signal rx_uart_data_out_a     : std_logic_vector (7 downto 0);
	signal rx_uart_data_valid_a   : std_logic;

	signal tx_uart_data_valid_b   : std_logic;
	signal tx_uart_data_in_b      : std_logic_vector (7 downto 0);
	signal tx_uart_ack_b          : std_logic;
	signal tx_uart_out_b          : std_logic;  -- connect to serial data output

	signal rx_uart_data_out_b     : std_logic_vector (7 downto 0);
	signal rx_uart_data_valid_b   : std_logic;

  -- TxFIFO signals

	signal tx_fifo_rd_en_a        : std_logic;
	signal tx_fifo_dout_a         : std_logic_vector (7 downto 0);
	signal tx_fifo_full_a         : std_logic;
	signal tx_fifo_almost_full_a  : std_logic;
	signal tx_fifo_empty_a        : std_logic;

	--signal tx_fifo_wr_en_b        : std_logic;
	signal tx_fifo_rd_en_b        : std_logic;
	signal tx_fifo_dout_b         : std_logic_vector (7 downto 0);
	signal tx_fifo_full_b         : std_logic;
	signal tx_fifo_almost_full_b  : std_logic;
	signal tx_fifo_empty_b        : std_logic;

  -- RxFIFO signals

	signal rx_fifo_wr_en_a        : std_logic;
	signal rx_fifo_rd_en_a        : std_logic;
	signal rx_fifo_dout_a         : std_logic_vector (7 downto 0);
	signal rx_fifo_full_a         : std_logic;
	signal rx_fifo_almost_full_a  : std_logic;
	signal rx_fifo_empty_a        : std_logic;

	signal rx_fifo_wr_en_b        : std_logic;
	signal rx_fifo_rd_en_b        : std_logic;
	signal com_adc_data            : std_logic_vector (7 downto 0);
	signal rx_fifo_dout_b         : std_logic_vector (7 downto 0);
	signal rx_fifo_full_b         : std_logic;
	signal rx_fifo_almost_full_b  : std_logic;
	signal rx_fifo_empty_b        : std_logic;

  -- 8b10b signals

	signal enc_8b10b_reset        : std_logic;
	signal enc_8b10b_in           : std_logic_vector (7 downto 0);
	signal enc_8b10b_ena          : std_logic;
	signal enc_comma_stb          : std_logic;
	--signal tx_ena_8b10b           : std_logic;
	signal tx_data_in_8b10b       : std_logic_vector (9 downto 0);
	signal tx_run_8b10b           : std_logic;
	signal tx_done_8b10b          : std_logic;
	signal tx_ack_8b10b           : std_logic;
	signal tx_out_8b10b           : std_logic;
	signal tx_out_8b10b_valid     : std_logic;
	signal tx_quiet_8b10b         : std_logic;

	--signal rx_in_8b10b            : std_logic;
	signal rx_ena_8b10b           : std_logic;
	signal rx_data_out_8b10b      : std_logic_vector (9 downto 0);
	signal dec_8b10b_reset        : std_logic;
	signal dec_8b10b_out          : std_logic_vector (7 downto 0);
	signal rx_data_valid_8b10b    : std_logic;
	signal dec_8b10b_ko           : std_logic;
	signal dec_8b10b_valid        : std_logic;

	signal rx_lh                  : std_logic;        -- for debugging only
	signal rx_hl                  : std_logic;        --
	signal rx_syncd               : std_logic;        --
	signal rx_data_stb            : std_logic;       --
	signal bit_length_ct_ena      : std_logic;       --
	--signal com_thr_adj            : std_logic_vector(2 downto 0);

	signal com_adc_sdout : std_logic; -- comm. ADC decoder output
	signal edge_valid : std_logic;
		
	signal commDebug_0w : commDebug_registerWrite_t;
	
	signal uartCableToArm0_i : std_logic;
	signal uartCableToArm1_i : std_logic;
	
	signal uart0_10b : std_logic_vector(9 downto 0);
	signal uart0_8b : std_logic_vector(7 downto 0);
	signal uart0_fifoRead : std_logic;
	signal uart0_fifoEmpty : std_logic;
	signal uart1_8b : std_logic_vector(7 downto 0);
	signal uart1_fifoRead : std_logic;
	signal uart1_fifoEmpty : std_logic;
	signal comAdcDataReady0 : std_logic;
	signal comAdcDataReady1 : std_logic;
	
	signal byte_out_debug : std_logic;
	
	signal uartDebugLoop0Enable : std_logic;
	signal uartDebugLoop1Enable : std_logic;
	signal uartArmToCable0_i : std_logic;
	signal uartArmToCable1_i : std_logic;
	
	attribute keep : string;
	attribute DONT_TOUCH : string;
	--signal adcAvg : std_logic_vector(15 downto 0);
	--attribute keep of adcAvg : signal is "true";
	--attribute DONT_TOUCH of adcAvg : signal is "true";
	
	signal baudRateDivisorRx : unsigned(15 downto 0);	
	signal baudRateDivisorTx : unsigned(15 downto 0);	

begin

	uartCableToArm0 <= uartCableToArm0_i;
	uartCableToArm1 <= uartCableToArm1_i;

	uartArmToCable0_i <= uartArmToCable0 when uartDebugLoop0Enable = '0' else uartCableToArm0_i; 
	uartArmToCable1_i <= uartArmToCable1 when uartDebugLoop1Enable = '0' else uartCableToArm1_i; 

	commDebug_0w <= commDebug_0w_x;
	
	uartDebugLoop0Enable <= commDebug_0w.uartDebugLoop0Enable;
	uartDebugLoop1Enable <= commDebug_0w.uartDebugLoop1Enable;
	
	--constant BAUD_RATE    : natural :=  115_200; --3_000_000; -- 256_000, 2_000_000
	--constant TX_BAUD_DIV  : natural := (59_375_000 / BAUD_RATE) -1; -- ~514
	--constant RX_BAUD_DIV : natural := (SYSTEM_FREQUENCY_HZ / BAUD_RATE / OVERSAMPLING_RATE) - 1; -- 60M, 115200, 10
	--115200
	baudRateDivisorTx <= i2u(514,16); 
	baudRateDivisorRx <= i2u(51,16); 
	--115200 +2.75%
	--baudRateDivisorTx <= i2u(500,16);
	--baudRateDivisorRx <= i2u(51,16); 
	--57600
	--baudRateDivisorTx <= i2u(1029,16); 
	--baudRateDivisorRx <= i2u(102,16); 
	
	y01: entity work.sync_reset_gen port map
	(
		clk           => clk,
		com_clk       => com_clk,
		com_reset     => com_reset,
		reset         => reset
	);

--	y05: entity work.uart_receiver_v2 port map
--	(
--		reset          => reset,
--		clk            => clk,
--		rx_in          => uartArmToCable0_i,
--		fifoOut8B      => uart0_8b,
--		fifoRead       => uart0_fifoRead,
--		fifoEmpty      => uart0_fifoEmpty,
--		baudRateDivisor => baudRateDivisorRx
--	);
--
--	y06: entity work.uart_receiver_v2 port map
--	(
--		reset          => reset,
--		clk            => clk,
--		rx_in          => uartArmToCable1_i,
--		fifoOut8B      => uart1_8b,
--		fifoRead       => uart1_fifoRead,
--		fifoEmpty      => uart1_fifoEmpty,
--		baudRateDivisor => baudRateDivisorRx
--	);

	z0: entity work.uart_v2 port map
	(
		com_reset,
		com_clk,
		uartArmToCable0_i,
		uartCableToArm0_i,
		uart0_8b,
		uart0_fifoRead,
		uart0_fifoEmpty,
		com_adc_data,
		comAdcDataReady0,
		open
	);

	z1: entity work.uart_v2 port map
	(
		com_reset,
		com_clk,
		uartArmToCable1_i,
		uartCableToArm1_i,
		uart1_8b,
		uart1_fifoRead,
		uart1_fifoEmpty,
		com_adc_data,
		comAdcDataReady1,
		open
	);

	y11: entity work.com_dac_enc port map
	(
		reset           => com_reset,
		clk             => com_clk,
		
		dataIn0         => uart0_8b,
		fifoEmpty0    	=> uart0_fifoEmpty,
		fifoRead0       => uart0_fifoRead,
		
		dataIn1         => uart1_8b,
		fifoEmpty1    	=> uart1_fifoEmpty,
		fifoRead1       => uart1_fifoRead,
		
		com_dac_data    => COM_DAC_DB, -- upper 8 bits used only here
		com_dac_clock   => COM_DAC_CLOCK,
		commDebug_0w => commDebug_0w
	);

	y12: entity work.com_adc_dec_v3 port map
	(
		reset           => com_reset,
		clk             => com_clk,           -- 60 MHz comm. clock
		--com_thr_adj     => com_thr_adj, 
		COM_ADC_CSBn    => COM_ADC_CSBn, 
		COM_ADC_SCLK    => COM_ADC_SCLK, 
		COM_ADC_SDIO    => COM_ADC_SDIO, 
		COM_ADC_D       => COM_ADC_D,    
		COM_ADC_CLK_N   => COM_ADC_CLK_N,
		COM_ADC_CLK_P   => COM_ADC_CLK_P,
		byte_out_debug => byte_out_debug,
		word_out => com_adc_data,
		word_ready0 => comAdcDataReady0,
		word_ready1 => comAdcDataReady1,
		notSync => dec_8b10b_reset,
		commDebug_0w => commDebug_0w
	);

--	x18: entity work.uart_transmitter_v2 port map
--	(
--		reset          		=> reset,
--		clk            		=> clk,
--		tx_out         		=> uartCableToArm0_i,
--		dataIn 				=> com_adc_data,
--		writeEnableDataIn 	=> comAdcDataReady0,
--		fifoAlmostFull 		=> open,
--		baudRateDivisor		=> baudRateDivisorTx
--	);
--
--	x19: entity work.uart_transmitter_v2 port map
--	(
--		reset          		=> reset,
--		clk            		=> clk,
--		tx_out         		=> uartCableToArm1_i,
--		dataIn 				=> com_adc_data,
--		writeEnableDataIn 	=> comAdcDataReady1,
--		fifoAlmostFull 		=> open,
--		baudRateDivisor		=> baudRateDivisorTx
--	);


	--baudrate_adj(0) <= '1'; --TEST_IO1;
	--baudrate_adj(1) <= '1'; --TEST_IO3;
	--baudrate_adj(2) <= '1'; --TEST_IO5;
	--baudrate_adj(3) <= '1'; --TEST_IO7;

	--com_thr_adj(0)  <= '0'; --TEST_IO9;
	--com_thr_adj(1)  <= '0'; --TEST_IO11;
	--com_thr_adj(2)  <= '0'; --TEST_IO13;

	debugOut <= (
		--0=>com_adc_sdout,
		--1=>edge_valid,
		2=>byte_out_debug, --dec_8b10b_valid,
		--3=>dec_8b10b_ko,
		--4=>rx_fifo_wr_en_a,
		--5=>rx_fifo_wr_en_b,
		6=>uartCableToArm0_i,
		7=>uartCableToArm1_i,
		others=>'0'
	);

end arch_uvl_comm_top_01 ;
