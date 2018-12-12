-------------------------------------------------------
-- Design Name : uvl_readout_01
-- File Name   : uvl_readout_top_01.vhd
-- Device      : Spartan 6, XC6SLX9-2TQG144C
-- Function    : top level design of the uvl_readout FPGA
-- Coder       : K.-H. Sulanke, DESY, 2018-12-03
-------------------------------------------------------
-- IceCube gen1 like encoding is being used now

library IEEE;
    use IEEE.std_logic_1164.all;
    --use IEEE.std_logic_unsigned.all ;
    --use ieee.numeric_bit.all;
    --use ieee.std_logic_arith.all;

library unisim;
    use unisim.vcomponents.all;

entity uvl_readout_top_02 is
  port
   (
     -- bank_0, 3.3V  
     PWRENn          : in  std_logic ;  --   
     FT_TEST         : out std_logic;   -- 
     FT_RESETn       : out std_logic;  -- 
     CLK_6MHZ        : out  std_logic;  -- clock used by the USB to UART bridge
     TEST_IO0        : out std_logic;   --
     TEST_IO1        : in  std_logic;   --
     TEST_IO2        : out std_logic;   --
     TEST_IO3        : in  std_logic;   --
     TEST_IO4        : out std_logic;   --
     TEST_IO5        : in  std_logic;   --
     TEST_IO6        : out std_logic;   --
     TEST_IO7        : out std_logic;   --
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

architecture behavior of uvl_readout_top_02 is
 
  signal reset         : std_logic; -- synchronous power up reset
  signal clk           : std_logic; -- by PLL
  signal com_reset     : std_logic; -- synchronous power up reset
  signal com_clk       : std_logic; -- by PLL, 8b10b communication clock domain
  --signal clk_6MHz_nd   : std_logic; -- by PLL
  
 begin 
 
	w0: entity work.pll port map
	(
		qosc_25MHz    => QOSC_25MHZ,
		clk           => clk,
		com_clk       => com_clk,
		com_reset     => com_reset,
		clk_6MHz      => CLK_6MHZ,
		reset         => reset
	);

    --CLK_6MHZ <= clk_6MHz_nd; 

	w1: entity work.uvl_readout_top_01 port map
	(
		clk => clk,
		reset => reset,
		com_clk => com_clk,
		com_reset => com_reset,


		PWRENn => PWRENn, --          : in  std_logic ;  --   
		FT_TEST => FT_TEST, --         : out std_logic;   -- 
		FT_RESETn => FT_RESETn, --       : out std_logic;  -- 
		TEST_IO0 => TEST_IO0, --        : out std_logic;   --
		TEST_IO1 => TEST_IO1, --        : in  std_logic;   --
		TEST_IO2 => TEST_IO2, --        : out std_logic;   --
		TEST_IO3 => TEST_IO3, --        : in  std_logic;   --
		TEST_IO4 => TEST_IO4, --        : out std_logic;   --
		TEST_IO5 => TEST_IO5, --        : in  std_logic;   --
		TEST_IO6 => TEST_IO6, --        : out std_logic;   --
		TEST_IO7 => TEST_IO7, --        : out std_logic;   --
		TEST_IO8 => TEST_IO8, --        : out std_logic;   --
		TEST_IO9 => TEST_IO9, --        : in  std_logic;   --
		TEST_IO10 => TEST_IO10, --       : out std_logic;   --
		TEST_IO11 => TEST_IO11, --       : in  std_logic;   --
		TEST_IO12 => TEST_IO12, --       : out std_logic;   --
		TEST_IO13 => TEST_IO13, --       : in  std_logic;   --
		TEST_IO14 => TEST_IO14, --       : out std_logic;   --
		TEST_IO15 => TEST_IO15, --       : out std_logic;   --
		I2C_DATA => I2C_DATA, --        : inout std_logic; --
		I2C_SCL => I2C_SCL, --         : out std_logic;   --

		-- bank_1, 1.8V
		COM_ADC_CSBn => COM_ADC_CSBn, --    : out std_logic;   --
		COM_ADC_SCLK => COM_ADC_SCLK, --    : out std_logic;   --
		COM_ADC_SDIO => COM_ADC_SDIO, --    : inout std_logic;   --
		COM_ADC_D => COM_ADC_D, --       : in  std_logic_vector (13 downto 0);
		RX_LEDn => RX_LEDn, --         : out std_logic;   --
		QOSCL_SCL => QOSCL_SCL, --       : out std_logic;   --
		QOSCL_SDA => QOSCL_SDA, --       : inout std_logic;   --

		-- bank_2, 3.3V
		COM_DAC_DB => COM_DAC_DB, --      : out std_logic_vector (11 downto 0);
		COM_DAC_CLOCK => COM_DAC_CLOCK, --   : out std_logic;   --
		--QOSC_25MHZ => QOSC_25MHZ, --      : in  std_logic;   -- local oscillator
		TX_LEDn => TX_LEDn, --         : out std_logic;   --
		COM_ADC_CLK_N => COM_ADC_CLK_N, --   : out std_logic;   --
		COM_ADC_CLK_P => COM_ADC_CLK_P, --   : out std_logic;   --

		-- bank_3, 3.3V
		BDBUS0 => BDBUS0, --      : in  std_logic;   -- TXD_B
		BDBUS1 => BDBUS1, --      : out std_logic;   -- RXD_B
		BCBUS2 => BCBUS2, --      : in  std_logic;   -- RXLEDn_B, transmitting data via USB
		BCBUS3 => BCBUS3, --      : in  std_logic;   -- TXLEDn_B, receiving data via USB   
		--     SI_WUB          : in  std_logic;   --
		ADBUS0 => ADBUS0, --   : in  std_logic;   -- TXD_A
		ADBUS1 => ADBUS1, --   : out std_logic;   -- RXD_A
		ACBUS2 => ACBUS2, --   : in  std_logic;   -- RXLEDn_A, transmitting data via USB
		ACBUS3 => ACBUS3 --    : in  std_logic   -- TXLEDn_A, receiving data via USB   
		--     SI_WUA
   );
 
   
 end architecture behavior;
 
