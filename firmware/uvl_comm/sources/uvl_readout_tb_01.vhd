-------------------------------------------------------
-- Design Name : uvl_readout_tb_01
-- File Name   : uvl_readout_tb_01.vhd
-- Function    : UART transmitter test bench
-- Coder       : K.-H. Sulanke, DESY
-- Date        : 2018-10-16
-------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
 
entity uvl_readout_tb_01 is
end uvl_readout_tb_01;

architecture behavior of uvl_readout_tb_01 is
  
component uvl_readout_top_01 is
-- generic (
--            --USE_LOCAL_CLOCK : boolean := true -- "false" -> diff. external clock is being used
--          ); 
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
     TEST_IO7        : in  std_logic;   --
     TEST_IO8        : out std_logic;   --
     TEST_IO9        : in  std_logic;   --
     TEST_IO10       : out std_logic;   --
     TEST_IO11       : in  std_logic;   --
     TEST_IO12       : out std_logic;   --
     TEST_IO13       : in  std_logic;   --
     TEST_IO14       : out std_logic;   --
     TEST_IO15       : out std_logic;   --
    
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
     BCBUS2          : in  std_logic;   -- RXLEDn_B, transmitting data via USB
     BCBUS3          : in  std_logic;   -- TXLEDn_B, receiving data via USB   

     ADBUS0          : in  std_logic;  -- TXD_A
     ADBUS1          : out std_logic;  -- RXD_A
     ACBUS2          : in  std_logic;  -- RXLEDn_A, transmitting data via USB
     ACBUS3          : in  std_logic   -- TXLEDn_A, receiving data via USB   

   );
end component uvl_readout_top_01 ;

signal  PWRENn         : std_logic;
signal  FT_TEST        : std_logic;
signal  FT_RESETn      : std_logic;
signal  CLK_6MHZ       : std_logic;
signal  COM_ADC_CSBn   : std_logic; 
signal  COM_ADC_SCLK   : std_logic; 
signal  COM_ADC_SDIO   : std_logic; 
signal  COM_ADC_D      : std_logic_vector (13 downto 0); 
--signal COM_ADC_DCO      : std_logic; 
--signal COM_ADC_OR       : std_logic; 
signal  RX_LEDn        : std_logic;
signal  QOSCL_SCL      : std_logic;
signal  QOSCL_SDA      : std_logic;
signal  COM_DAC_DB     : std_logic_vector (11 downto 0);    -- 3 to select between RS232/485, 4..5 are being used as ADR_SW
signal  COM_DAC_CLOCK  : std_logic; 
signal  QOSC_25MHZ     : std_logic := '0';     -- 
signal  TX_LEDn        : std_logic ;   -- LVDS, from high level dicriminator
signal  COM_ADC_CLK_N  : std_logic;   -- 
signal  COM_ADC_CLK_P  : std_logic; -- J5, RJ45, LVDS bidir. test port
signal  BDBUS0         : std_logic := '1';  -- TXD_B 
signal  BDBUS1         : std_logic;  -- RXD_B
signal  BCBUS2         : std_logic;  --
signal  BCBUS3         : std_logic;  --
signal  ADBUS0         : std_logic;  -- TXD_A
signal  ADBUS1         : std_logic;  -- RXD_A
signal  ACBUS2         : std_logic;  -- 
signal  ACBUS3         : std_logic;  -- 

signal TEST_IO0        : std_logic;   --
signal TEST_IO1        : std_logic;   --
signal TEST_IO2        : std_logic;   --
signal TEST_IO3        : std_logic;   --
signal TEST_IO4        : std_logic;   --
signal TEST_IO5        : std_logic;   --
signal TEST_IO6        : std_logic;   --
signal TEST_IO7        : std_logic;   --
signal TEST_IO8        : std_logic;   --
signal TEST_IO9        : std_logic;   --
signal TEST_IO10       : std_logic;   --
signal TEST_IO11       : std_logic;   --
signal TEST_IO12       : std_logic;   --
signal TEST_IO13       : std_logic;   --
signal TEST_IO14       : std_logic;   --
signal TEST_IO15       : std_logic;   --

--signal    : std_logic; -- 
--signal    : std_logic; -- 
--        
--signal    : std_logic; -- 
--signal    : std_logic; -- 
--signal    : std_logic; -- 
--signal    : std_logic; -- 
--signal    : std_logic; -- 
--signal    : std_logic; -- 
--signal    : std_logic; -- 
--signal    : std_logic; -- 
--        
--signal    : std_logic;  --
--signal    : std_logic;  --


  component uart is port -- to emulate the USB to UART bridge 
   (
    clk                : in std_logic;
    reset              : in std_logic;

    tx_data_valid      : in  std_logic;                     -- handshake signal with tx_ack
    tx_data_in         : in  std_logic_vector (7 downto 0); -- parallel tx data input
    tx_busy            : out std_logic;                     -- busy with sending a byte
    tx_ack             : out std_logic;                     -- handshake signal with tx_data_valid
    tx_out             : out std_logic;                     -- serial data output

    rx_in              : in  std_logic;                     -- serial data input
    rx_data_out        : out std_logic_vector (7 downto 0); -- parallel rx data output
    rx_data_valid      : out std_logic                      -- single clock length pulse
    );
   end component uart;
   
   

-- ext. uart, inputs
  signal reset         : std_logic                     := 'U';
  signal clk           : std_logic                     := '0';
  signal tx_data_valid : std_logic                     := '0';
  signal rx_in         : std_logic;
  signal tx_data_in    : std_logic_vector (7 downto 0) := (others => 'U');

-- ext. uart, outputs
  signal tx_ack        : std_logic := '0';
  signal tx_out        : std_logic := '0';
  signal tx_busy       : std_logic;
  signal rx_data_out   : std_logic_vector (7 downto 0) := (others => 'U');
  signal rx_data_valid : std_logic;
 
  constant qosc_clk_period : time := 40 ns;
  constant clk_period      : time := 16.7 ns; -- 60 MHz system clock
   

begin

   QOSC_25MHZ <= not QOSC_25MHZ after qosc_clk_period / 2;
   clk        <= not clk after clk_period / 2;


  ADBUS0   <= tx_out;  -- external UART connected for serilization / deserialization
  rx_in    <= ADBUS1;  

	
  UVL_READOUT_test: process
  	
--	 variable message     : string (1 to message_len) := "  DAC  7  0 5 1234  " & cr & lf;

 --   constant TEST_STRG : string := "Started : ""Generate Programming File""." &cr&lf;
    constant TEST_STRG : string := "123456789" &cr&lf;
--    constant TEST_STRG : string := "if (eof_rcvd = '1') or (no_edge_ct = NO_EDGES_TIME_OUT) or (no_comma_ct = NO_COMMA_TIME_OUT) then";
--    constant TEST_STRG : string := "a";
    
  	variable message_len : integer;
  	variable i           : integer;
	  variable char        : character;
	  variable char_ascii  : integer range 0 to 255;
		   
	begin
  
    TEST_IO7 <= '1'; -- baudrate setting
    TEST_IO5 <= '1'; -- baudrate setting
    TEST_IO3 <= '1'; -- baudrate setting
    TEST_IO1 <= '1'; -- baudrate setting
    
--    com_thr_adj(0)  <= TEST_IO9;
--    com_thr_adj(1)  <= TEST_IO11;
--    com_thr_adj(2)  <= TEST_IO13;

    
    tx_data_valid     <= '0';
    
    
    reset <= '1';
    wait until (FT_RESETn = '0');
    wait until (FT_RESETn = '1');
    reset <= '0';
 	  
--    wait until (reset = '1');
--    wait until (reset = '0');
    
	   wait for clk_period * 10;

      message_len := TEST_STRG'length;
      tx_data_valid <= '1';
	    send_test_strg: for i in 1 to message_len loop
	       -- conversion to ASCII code by getting the position of char
	       -- in the ASCII table "CHARACTER" 
	       char          := TEST_STRG(i);
	       char_ascii    := CHARACTER'pos(char);
	       tx_data_in    <= std_logic_vector( to_unsigned ( char_ascii, 8));
	       wait until tx_ack = '1';
	       wait for clk_period *1; -- 
	    end loop send_test_strg;
	    tx_data_valid    <= '0';     
      wait for clk_period * 100;   

   wait;
  	    
	end process UVL_READOUT_test;


	    
-- instantiate the units under test (uut)

uart_inst: uart port map
    (
      reset      => reset,
      clk        => clk,
      tx_data_valid   => tx_data_valid,
      tx_data_in => tx_data_in,
      tx_busy    => tx_busy,
      tx_ack     => tx_ack,
      tx_out     => tx_out,
      rx_in      => rx_in,
      rx_data_out   => rx_data_out,
      rx_data_valid => rx_data_valid
     );

   COM_ADC_D <= COM_DAC_DB & B"00";

  uvl_readout_top_01_port_map: component uvl_readout_top_01
  --generic map( USE_LOCAL_CLOCK => true )-- "false" -> diff. external clock is being used
   port map
   (
    PWRENn        => PWRENn ,
    FT_TEST       => FT_TEST ,
    FT_RESETn     => FT_RESETn ,
    CLK_6MHZ      => CLK_6MHZ ,
    COM_ADC_CSBn  => COM_ADC_CSBn,
    COM_ADC_SCLK  => COM_ADC_SCLK,
    COM_ADC_SDIO  => COM_ADC_SDIO,
    COM_ADC_D     => COM_ADC_D,   
    COM_ADC_CLK_N => COM_ADC_CLK_N, 
    COM_ADC_CLK_P => COM_ADC_CLK_P, 
    RX_LEDn       => RX_LEDn ,
    QOSCL_SCL     => QOSCL_SCL ,
    QOSCL_SDA     => QOSCL_SDA ,
    QOSC_25MHZ    => QOSC_25MHZ ,
    TX_LEDn       => TX_LEDn ,
    BDBUS0        => BDBUS0 ,
    BDBUS1        => BDBUS1 ,
    BCBUS2        => BCBUS2 ,
    BCBUS3        => BCBUS3 ,
    ADBUS0        => ADBUS0 ,
    ADBUS1        => ADBUS1 ,
    ACBUS2        => ACBUS2 ,
    ACBUS3        => ACBUS3 ,
    COM_DAC_DB    => COM_DAC_DB,
    COM_DAC_CLOCK => COM_DAC_CLOCK, 
    TEST_IO0      => TEST_IO0, 
    TEST_IO1      => TEST_IO1, 
    TEST_IO2      => TEST_IO2, 
    TEST_IO3      => TEST_IO3, 
    TEST_IO4      => TEST_IO4, 
    TEST_IO5      => TEST_IO5, 
    TEST_IO6      => TEST_IO6, 
    TEST_IO7      => TEST_IO7, 
    TEST_IO8      => TEST_IO8, 
    TEST_IO9      => TEST_IO9, 
    TEST_IO10     => TEST_IO10,
    TEST_IO11     => TEST_IO11,
    TEST_IO12     => TEST_IO12,
    TEST_IO13     => TEST_IO13,
    TEST_IO14     => TEST_IO14,
    TEST_IO15     => TEST_IO15 
   );
  
 --  TEST_IO12     <= TEST_IO13;
--  (TEST_IO7, TEST_IO5, TEST_IO3, TEST_IO1) <= B"1111"; -- baudrate setting

end architecture behavior;
  