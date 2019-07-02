-------------------------------------------------------
-- Design Name : uvl_readout_01
-- File Name   : uvl_readout_top_01.vhd
-- Device      : Spartan 6, XC6SLX9-2TQG144C
-- Function    : top level design of the uvl_readout FPGA, reflecting data
--               for test purposes     
-- Coder       : K.-H. Sulanke, DESY, 2018-11-12
-------------------------------------------------------

--


library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

library unisim ;
use unisim.vcomponents.all ;

entity uvl_readout_top_01 is
	port
	(
	 -- bank_0, 3.3V  
		PWRENn          : in  std_logic ;  --   
		FT_TEST         : out std_logic;   -- 
		FT_RESETn       : out std_logic;  -- 
		CLK_6MHZ        : out  std_logic;  -- clock used by the USB to UART bridge
		TEST_IO0        : out std_logic;   --
		TEST_IO1        : inout  std_logic;   --
		TEST_IO2        : out std_logic;   --
		TEST_IO3        : inout  std_logic;   --
		TEST_IO4        : out std_logic;   --
		TEST_IO5        : inout  std_logic;   --
		TEST_IO6        : out std_logic;   --
		TEST_IO7        : inout  std_logic;   --
		TEST_IO8        : out std_logic;   --
		TEST_IO9        : in  std_logic;   --
		TEST_IO10       : out std_logic;   --
		TEST_IO11       : in  std_logic;   --
		TEST_IO12       : out std_logic;   --
		TEST_IO13       : in  std_logic;   --
		TEST_IO14       : out std_logic;   --
		TEST_IO15       : out std_logic;   --
		I2C_DATA        : inout std_logic; --
		I2C_SCL         : out std_logic;   --

	 -- bank_1, 1.8V
		COM_ADC_CSBn    : out std_logic;   --
		COM_ADC_SCLK    : out std_logic;   --
		COM_ADC_SDIO    : inout std_logic;   --
		COM_ADC_D       : in  std_logic_vector (13 downto 0);
	 --     COM_ADC_DCO     : in  std_logic;  -- 
	 --     COM_ADC_OR      : in  std_logic;  -- 
		RX_LEDn         : out std_logic;   --
		QOSCL_SCL       : out std_logic;   --
		QOSCL_SDA       : inout std_logic;   --

	 -- bank_2, 3.3V
		COM_DAC_DB      : out std_logic_vector (11 downto 0);
		COM_DAC_CLOCK   : out std_logic;   --
		QOSC_25MHZ      : in  std_logic;   -- local oscillator
		TX_LEDn         : out std_logic;   --
		COM_ADC_CLK_N   : out std_logic;   --
		COM_ADC_CLK_P   : out std_logic;   --

	 -- bank_3, 3.3V
		BDBUS0          : in  std_logic;   -- TXD_B
		BDBUS1          : out std_logic;   -- RXD_B
										   --     BDBUS2          : in  std_logic;   -- RTSn_B
										   --     BDBUS3          : in  std_logic;   -- CTSn_B
										   --     BDBUS4          : in  std_logic;   --
										   --     BDBUS5          : in  std_logic;   --
										   --     BDBUS6          : in  std_logic;   --
										   --     BDBUS7          : in  std_logic;   --
										   --     
										   --     BCBUS0          : in  std_logic;   --
										   --     BCBUS1          : in  std_logic;   --
		BCBUS2          : in  std_logic;   -- RXLEDn_B, transmitting data via USB
		BCBUS3          : in  std_logic;   -- TXLEDn_B, receiving data via USB   

	 --     SI_WUB          : in  std_logic;   --

		ADBUS0          : in  std_logic;   -- TXD_A
		ADBUS1          : out std_logic;   -- RXD_A
										   --     ADBUS2          : in  std_logic;   -- RTSn_A
										   --     ADBUS3          : in  std_logic;   -- CTSn_A
										   --     ADBUS4          : in  std_logic;   --
										   --     ADBUS5          : in  std_logic;   --
										   --     ADBUS6          : in  std_logic;   --
										   --     ADBUS7          : in  std_logic;   --    
										   --     
										   --     ACBUS0          : in  std_logic;   --
										   --     ACBUS1          : in  std_logic;   --
		ACBUS2          : in  std_logic;   -- RXLEDn_A, transmitting data via USB
		ACBUS3          : in  std_logic   -- TXLEDn_A, receiving data via USB   

   --     SI_WUA          : in  std_logic    --

	);
end entity;

architecture uvl_readout_top_01_arch of uvl_readout_top_01 is
	
	attribute keep : string;
	
	signal reset         : std_logic; -- synchronous power up reset
	signal clk           : std_logic; -- by PLL
	signal com_reset     : std_logic; -- synchronous power up reset
	signal com_clk       : std_logic; -- by PLL, 8b10b communication clock domain
	signal not_com_clk   : std_logic; -- by PLL
	
	signal baudrate_adj : std_logic_vector(3 downto 0);
	signal com_thr_adj : std_logic_vector(2 downto 0);
	signal debugOut : std_logic_vector(7 downto 0);
	
	signal commDebug_0w : commDebug_registerWrite_t;
	attribute keep of commDebug_0w : signal is "true";
	
	signal fifo_avrFactor : std_logic_vector(3 downto 0);

begin 

	x0: entity work.pll_01 port map
	(
		qosc_25MHz    => QOSC_25MHZ,
		clk           => clk,
		com_clk       => com_clk,
		not_com_clk   => not_com_clk,
		com_reset     => com_reset,
		clk_6MHz      => CLK_6MHZ,
		reset         => reset
	);

	x1: entity work.uvl_comm_top_01 port map
	(
		clk,
		com_clk,
		COM_ADC_D,
		'0', --COM_ADC_OR
		COM_ADC_CSBn,
		COM_ADC_SCLK,
		COM_ADC_SDIO,
		'0', --COM_ADC_DCO
		COM_ADC_CLK_P,
		COM_ADC_CLK_N,
		COM_DAC_DB,
		COM_DAC_CLOCK,
										-- naming based on stamp view
		ADBUS1, --STAMP_DRXD    : out std_logic;  -- stamp debug uart 
		ADBUS0, --STAMP_DTXD    : in  std_logic; --     
		BDBUS1, --STAMP_RXD1    : out std_logic; -- PB5, stamp uart
		BDBUS0, --STAMP_TXD1    : in  std_logic -- PB4, 
		debugOut,
		commDebug_0w
	);

	process(clk)
	begin
		if(rising_edge(clk)) then	
			fifo_avrFactor <= not(TEST_IO7 & TEST_IO5 & TEST_IO3 & TEST_IO1);
		end if;
	end process;


	commDebug_0w.tx_baud_div <= i2v(300,16); 
--	commDebug_0w.tx_baud_div <= x"0100"; 
	commDebug_0w.dU_1mV <= x"0190";
	commDebug_0w.com_adc_thr <= x"0083";
	commDebug_0w.dac_incDacValue <= x"200";
	commDebug_0w.dac_valueIdle <= x"800";
	commDebug_0w.dac_valueLow <= x"001";
	commDebug_0w.dac_valueHigh <= x"ffe";
	commDebug_0w.dac_time1 <= i2v(60,16);
	commDebug_0w.dac_time2 <= i2v(62,16);
	commDebug_0w.dac_time3 <= i2v(10,16);
	commDebug_0w.dac_clkTime <= x"0001";
	commDebug_0w.com_thr_adj <= "000";
	commDebug_0w.adc_deadTime <= x"0f0";
	commDebug_0w.adc_syncTimeout <= x"1000";
	commDebug_0w.adc_baselineAveragingTime <= x"03ff";
	--commDebug_0w.adc_threshold_p <= i2v(8500,16);
	--commDebug_0w.adc_threshold_n <= i2v(7900,16);
	commDebug_0w.adc_threshold_p <= i2v(8400,16);
	commDebug_0w.adc_threshold_n <= i2v(8000,16);
	commDebug_0w.fifo_avrFactor <= fifo_avrFactor;
	commDebug_0w.uartDebugLoop0Enable <= not(TEST_IO9);
	commDebug_0w.uartDebugLoop1Enable <= not(TEST_IO11);

  -- USB to comm. DAC chain, see below -----------------------------------------------------------

	RX_LEDn <= '0' when ACBUS2 = '0' else 'Z';
	TX_LEDn <= '0' when ACBUS3 = '0' else 'Z';

	FT_TEST <= '0';
	FT_RESETn <= not reset;

	baudrate_adj(0) <= TEST_IO1;
	baudrate_adj(1) <= TEST_IO3;
	baudrate_adj(2) <= TEST_IO5;
	baudrate_adj(3) <= TEST_IO7;
	TEST_IO1 <= 'Z';
	TEST_IO3 <= 'Z';
	TEST_IO5 <= 'Z';
	TEST_IO7 <= 'Z';
	
	com_thr_adj(0) <= TEST_IO9;
	com_thr_adj(1) <= TEST_IO11;
	com_thr_adj(2) <= TEST_IO13;

	TEST_IO0 <= '0'; --debugOut(0);
	TEST_IO2 <= '0'; --debugOut(1);
	TEST_IO4 <= '0'; --debugOut(2);
	TEST_IO6 <= '0'; --debugOut(3);
	TEST_IO8 <= '0'; --debugOut(4);
  --TEST_IO9 <= rx_lh            ;--rx_data_valid_8b10b;
	TEST_IO10 <= '0'; --dec_8b10b_valid;
					 -- TEST_IO11 <= rx_syncd         ;--dec_8b10b_ko;
	TEST_IO12 <= '0'; --rx_fifo_wr_en_a;
					 -- TEST_IO13 <= dec_8b10b_reset;--rx_in_8b10b;
	TEST_IO14 <= '0'; --tx_fifo_empty_a; --rx_data_stb;

	TEST_IO15 <= '0'; --com_adc_sdout;
	
--	rx_in_8b10b <= com_adc_sdout; --tx_out_8b10b; --TEST_IO12 or TEST_IO14;


end architecture uvl_readout_top_01_arch;

