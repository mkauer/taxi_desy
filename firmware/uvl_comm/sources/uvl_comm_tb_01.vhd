-------------------------------------------------------
-- Design Name : uvl_comm_tb_01
-- File Name   : uvl_comm_tb_01.vhd
-- Function    : UART transmitter test bench
-- Coder       : K.-H. Sulanke, DESY
-- Date        : 2018-11-13
-------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
 
entity uvl_comm_tb_01 is
end uvl_comm_tb_01;

architecture behavior of uvl_comm_tb_01 is
  
  component uvl_comm_top_01 is 
  port(    
      clk           : in  std_logic;  -- 60 MHz system clock
      com_clk       : in  std_logic;  -- 60 MHz communication clock

      -- ************************ Bank #1, VCCO = 2.5V  ****************************************************
     
      COM_ADC_D     : in  std_logic_vector(13 downto 0);    -- communication ADC output
      COM_ADC_OR    : in  std_logic;  -- out of range signal, NOT USED
      COM_ADC_CSBn  : out std_logic; --
      COM_ADC_SCLK  : out std_logic; --
      COM_ADC_SDIO  : inout std_logic; -- is inout
      COM_ADC_DCO   : in  std_logic; -- dedicated clock pin, data clock, NOT USED

      -- ************************ Bank #2, VCCO = 2.5V  ****************************************************

      COM_ADC_CLK_P : out std_logic;  -- LVDS, comm. ADC  clock     
      COM_ADC_CLK_N : out std_logic;  -- 

      -- ************************ Bank #3, VCCO = 3.3V  ****************************************************

      COM_DAC_DB    : out std_logic_vector(11 downto 0);    -- connected to communication DAC
      COM_DAC_CLOCK : out std_logic;  -- 
                                     -- naming based on stamp view
      STAMP_DRXD    : out std_logic;  -- stamp debug uart 
      STAMP_DTXD    : in  std_logic; --     
      STAMP_RXD1    : out std_logic; -- PB5, stamp uart
      STAMP_TXD1    : in  std_logic; -- PB4, 
     
      --TEST_IO       : out std_logic_vector(3 downto 0) -- 3.3V CMOS / LVDS bidir. test port, p/n=1/0 or 3/2   
      TEST_IO0       : out std_logic;
      TEST_IO1       : out std_logic;
      TEST_IO2       : out std_logic;
      TEST_IO3       : out std_logic

     );
  end component uvl_comm_top_01 ;


    signal clk             : std_logic := '0';
    signal com_clk         : std_logic := '0'; 

    signal  COM_ADC_CSBn   : std_logic; 
    signal  COM_ADC_SCLK   : std_logic; 
    signal  COM_ADC_SDIO   : std_logic; 
    signal  COM_ADC_D      : std_logic_vector (13 downto 0); 
    signal  COM_ADC_DCO    : std_logic; 
    signal  COM_ADC_OR     : std_logic; 
    signal  COM_DAC_DB     : std_logic_vector (11 downto 0);    -- 3 to select between RS232/485, 4..5 are being used as ADR_SW
    signal  COM_DAC_CLOCK  : std_logic; 
    signal  COM_ADC_CLK_N  : std_logic;   -- 
    signal  COM_ADC_CLK_P  : std_logic; -- J5, RJ45, LVDS bidir. test port

    signal TEST_IO0        : std_logic;   --
    signal TEST_IO1        : std_logic;   --
    signal TEST_IO2        : std_logic;   --
    signal TEST_IO3        : std_logic;   --

    signal STAMP_DRXD      : std_logic;   --
    signal STAMP_DTXD      : std_logic;   --
    signal STAMP_RXD1      : std_logic;   --
    signal STAMP_TXD1      : std_logic;   --



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
  signal uart_reset    : std_logic                     := 'U';
  signal tx_data_valid : std_logic                     := '0';
  signal rx_in         : std_logic;
  signal tx_data_in    : std_logic_vector (7 downto 0) := (others => 'U');

-- ext. uart, outputs
  signal tx_ack        : std_logic := '0';
  signal tx_out        : std_logic := '0';
  signal tx_busy       : std_logic;
  signal rx_data_out   : std_logic_vector (7 downto 0) := (others => 'U');
  signal rx_data_valid : std_logic;
 
  constant clk_period      : time := 16.7 ns; -- 60 MHz system clock
  constant com_clk_period  : time := 16.7 ns; -- 60 MHz system clock
   

begin

  clk          <= not clk after clk_period / 2;
  com_clk      <= not com_clk after clk_period / 2;


  STAMP_DTXD   <= tx_out;  -- external UART connected for serilization / deserialization
  rx_in        <= STAMP_DRXD;  

	
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
  
--    TEST_IO7 <= '1'; -- baudrate setting
--    TEST_IO5 <= '1'; -- baudrate setting
--    TEST_IO3 <= '1'; -- baudrate setting
--    TEST_IO1 <= '1'; -- baudrate setting
    
--    com_thr_adj(0)  <= TEST_IO9;
--    com_thr_adj(1)  <= TEST_IO11;
--    com_thr_adj(2)  <= TEST_IO13;

    
      tx_data_valid     <= '0';
    
      uart_reset <= '1';
      wait for clk_period * 100;
      uart_reset <= '0';
 	  
--    wait until (reset = '1');
--    wait until (reset = '0');
    
	   wait for clk_period * 1000;

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
      reset      => uart_reset,
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

  uvl_comm_top_01_port_map: component uvl_comm_top_01
   port map
   (
    clk           => clk,
    com_clk       => com_clk,
    COM_ADC_CSBn  => COM_ADC_CSBn,
    COM_ADC_SCLK  => COM_ADC_SCLK,
    COM_ADC_SDIO  => COM_ADC_SDIO,
    COM_ADC_D     => COM_ADC_D,
    COM_ADC_OR    => COM_ADC_OR,
    COM_ADC_DCO   => COM_ADC_DCO,
    COM_ADC_CLK_N => COM_ADC_CLK_N, 
    COM_ADC_CLK_P => COM_ADC_CLK_P, 
    COM_DAC_DB    => COM_DAC_DB,
    COM_DAC_CLOCK => COM_DAC_CLOCK, 
    STAMP_DRXD    => STAMP_DRXD,
    STAMP_DTXD    => STAMP_DTXD,
    STAMP_RXD1    => STAMP_RXD1,
    STAMP_TXD1    => STAMP_TXD1,
    TEST_IO0      => TEST_IO0, 
    TEST_IO1      => TEST_IO1, 
    TEST_IO2      => TEST_IO2, 
    TEST_IO3      => TEST_IO3 
   );
  
 --  TEST_IO12     <= TEST_IO13;
--  (TEST_IO7, TEST_IO5, TEST_IO3, TEST_IO1) <= B"1111"; -- baudrate setting

end architecture behavior;
  