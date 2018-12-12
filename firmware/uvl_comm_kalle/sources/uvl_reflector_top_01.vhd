-------------------------------------------------------
-- Design Name : uvl_reflector_01
-- File Name   : uvl_reflector_top_01.vhd
-- Device      : Spartan 6, XC6SLX9-2TQG144C
-- Function    : top level test design of the uvl_readout FPGA,
--               faking the inice module, reflecting data
-- Coder       : K.-H. Sulanke, DESY, 2018-11-10
-------------------------------------------------------

--


library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.std_logic_unsigned.all ;
    use ieee.numeric_bit.all;
    use ieee.std_logic_arith.all;

library unisim ;
    use unisim.vcomponents.all ;

entity uvl_reflector_top_01 is
-- generic (
--            --USE_LOCAL_CLOCK : boolean := true -- "false" -> diff. external clock is being used
--            --N : integer := 8 ;   -- amount of serial data channel
--           -- S	: integer := 8	 -- Parameter to set the serdes factor 1..8  
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

architecture uvl_reflector_top_01_arch of uvl_reflector_top_01 is
 
 
 component pll_01 IS
   PORT
   (
      qosc_25MHz  : IN  STD_LOGIC; -- local clock
      clk         : OUT STD_LOGIC; -- system clock, made by pll_clkout2
      com_clk     : OUT STD_LOGIC; -- communication clock made by pll_clkout4
      not_com_clk : OUT STD_LOGIC; -- communication clock made by pll_clkout5, 180° phase shifted
      com_reset   : OUT STD_LOGIC; -- communication reset, synchronous to com_clk
      clk_6MHz    : OUT STD_LOGIC; -- USB to UART bridge made by pll_clkout3
      reset       : OUT STD_LOGIC
    );
  end component pll_01;  

  component uart_baudrate_generator is
   port ( 
         reset    : in  std_logic;
         clk      : in  std_logic;
         tx_ena   : out std_logic;
         rx_ena   : out std_logic
        );
  end component uart_baudrate_generator;
    
  component uart_receiver is
   port(
    reset           : in  std_logic;
    clk             : in  std_logic;
    rx_ena          : in  std_logic;        -- single clock length pulse from baudrate generator
    rx_in           : in  std_logic;        -- serial data on the line
    rx_data_out     : out std_logic_vector (7 downto 0);  -- parallel out
    rx_data_valid   : out std_logic         -- single clock length pulse
    );
  end component uart_receiver;  
 
  component uart_transmitter is
   port(
        reset          :in  std_logic;
        clk            :in  std_logic;
        tx_data_valid  :in  std_logic; -- like tx_fifo_not_empty
        tx_data_in     :in  std_logic_vector (7 downto 0);
        tx_ena         :in  std_logic;
        tx_ack         :out std_logic; -- single clock pulse
		    tx_out         :out std_logic  -- serial data out
       );
  end component uart_transmitter;

  component fifo_4KB_dual_clock is port
   (
    rst         : IN STD_LOGIC;
    wr_clk      : IN STD_LOGIC;
    rd_clk      : IN STD_LOGIC;
    din         : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    wr_en       : IN STD_LOGIC;
    rd_en       : IN STD_LOGIC;
    dout        : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    full        : OUT STD_LOGIC;
    almost_full : OUT STD_LOGIC;
    empty       : OUT STD_LOGIC
  );
  end component fifo_4KB_dual_clock;

  component free_8b10b_enc is	port
    (
		RESET                                  : in std_logic ;		-- Global asynchronous reset (active high) 
		SBYTECLK                               : in std_logic ;	-- Master synchronous send byte clock
		KI                                     : in std_logic ;			-- Control (K) input(active high)
		AI, BI, CI, DI, EI, FI, GI, HI         : in std_logic ;	-- Unencoded input data
		ENA                                    : in std_logic;			-- Global enable input
		JO, HO, GO, FO, IO, EO, DO, CO, BO, AO : out std_logic 	-- Encoded out
	  );
  end component free_8b10b_enc;
 
  component var_baudrate_generator_8b10b is
  port ( reset          : in  std_logic;
         clk            : in  std_logic;
         baudrate_adj   : in std_logic_vector(3 downto 0);
         tx_ena         : out std_logic
         );
  end component var_baudrate_generator_8b10b;
 
  component tx_ctrl_8b10b is port
  (
        com_reset       : in  std_logic;   -- communication com_reset
        com_clk         : in  std_logic;   -- communication clock
        tx_fifo_empty_a : in  std_logic;
        tx_fifo_rd_en_a : out std_logic;   -- pulse of one clock length
        tx_fifo_dout_a  : in  std_logic_vector (7 downto 0);
        tx_fifo_empty_b : in  std_logic;
        tx_fifo_rd_en_b : out std_logic;   -- pulse of one clock length
        tx_fifo_dout_b  : in  std_logic_vector (7 downto 0);       
        STF_COMMA_a     : in  std_logic_vector (7 downto 0); -- start of frame comma
        EOF_COMMA_a     : in  std_logic_vector (7 downto 0); -- end of frame comma
        STF_COMMA_b     : in  std_logic_vector (7 downto 0); -- start of frame comma
        EOF_COMMA_b     : in  std_logic_vector (7 downto 0); -- end of frame comma
        enc_8b10b_reset : out std_logic;  -- 
        enc_8b10b_ena   : out std_logic;  --
        enc_8b10b_in    : out std_logic_vector (7 downto 0); --
        enc_comma_stb   : out std_logic;  -- encoder input is a comma operator
        tx_run_8b10b    : out std_logic;  -- start 8b10 transmitter         
        tx_ack_8b10b    : in  std_logic;  -- one clock length ready pulse
        tx_done_8b10b   : in  std_logic   -- 
   );
  end component tx_ctrl_8b10b;
  
  component transmitter_8b10b is port
   (
        com_reset        : in  std_logic;
        com_clk          : in  std_logic;
        tx_run_8b10b     : in  std_logic; -- like tx_fifo_not_empty
        tx_data_in_8b10b : in  std_logic_vector (9 downto 0);
        tx_ena_8b10b     : in  std_logic; -- from baudrate generator
        tx_ack_8b10b     : out std_logic; -- single clock pulse
        tx_done_8b10b    : out std_logic; --      
        tx_quiet_8b10b   : out std_logic; -- when in IDLE state, to control the com_dac
		    tx_out_8b10b     : out std_logic  -- serial data out
    );
  end component transmitter_8b10b;

  component com_dac_enc is
   port(
        reset           : in  std_logic;
        clk             : in  std_logic;
        sdin            : in  std_logic; -- serial data input
        com_dac_quiet   : in  std_logic; -- get zero baseline value, when comm. is inactive
        com_dac_in      : out std_logic_vector (11 downto 0); 
        com_dac_clock   : out std_logic
       );
  end component com_dac_enc;

  component com_adc_dec is
   port(
         reset           : in  std_logic;
         clk             : in  std_logic; -- 60 MHz comm. clock
         com_thr_adj     : in  std_logic_vector (2 downto 0); -- set the comm. threshold
         COM_ADC_CSBn    : out std_logic;   --
         COM_ADC_SCLK    : out std_logic;   --
         COM_ADC_SDIO    : inout std_logic; --
         COM_ADC_D       : in  std_logic_vector (13 downto 0); -- available 3ns after COM_ADC_CLK-LH edge
         COM_ADC_CLK_N   : out std_logic;  --
         COM_ADC_CLK_P   : out std_logic;  -- 
         com_adc_sdout   : out std_logic   -- decoder serial data output      
       );
  end component com_adc_dec;


  component receiver_8b10b is port
   (
    reset           : in  std_logic;
    clk             : in  std_logic;
    baudrate_adj    : in std_logic_vector(3 downto 0);
    dec_8b10b_reset : out std_logic;
    rx_in           : in  std_logic;        -- serial data on the line
    rx_data_out     : out std_logic_vector (9 downto 0);  -- parallel out
    rx_data_valid   : out std_logic;        -- single clock length pulse
    dec_8b10b_valid : out std_logic;         -- delayed by one clock rx_data_valid to deal with the decoder latency
    rx_lh_nd           : out std_logic;        -- for debugging only
    rx_hl_nd           : out std_logic;        --
    rx_syncd_nd        : out std_logic;        --
    rx_data_stb        : out std_logic
    );
  end component receiver_8b10b;

  component free_8b10b_dec is	port
   (
		RESET : in std_logic ;	-- Global asynchronous reset (AH) 
		RBYTECLK : in std_logic ;	-- Master synchronous receive byte clock
		AI, BI, CI, DI, EI, II : in std_logic ;
		FI, GI, HI, JI : in std_logic ; -- Encoded input (LS..MS)		
		KO : out std_logic ;	-- Control (K) character indicator (AH)
		HO, GO, FO, EO, DO, CO, BO, AO : out std_logic 	-- Decoded out (MS..LS)
	 );
  end component free_8b10b_dec;
  
  component rx_ctrl_8b10b is
   port(
        com_reset              :in  std_logic;   -- communication com_reset
        com_clk                :in  std_logic;   -- communication clock
        dec_8b10b_out          :in  std_logic_vector (7 downto 0); --
        dec_8b10b_valid        :in  std_logic;   --
        dec_8b10b_ko           :in  std_logic;   -- decoder output is comma
        STF_COMMA_a            :in  std_logic_vector (7 downto 0); -- start of frame comma
        EOF_COMMA_a            :in  std_logic_vector (7 downto 0);  -- end of frame comma        
        rx_fifo_almost_full_a  :in  std_logic;
        rx_fifo_wr_en_a        :out std_logic;   -- pulse of one clock length
        STF_COMMA_b            :in  std_logic_vector (7 downto 0); -- start of frame comma
        EOF_COMMA_b            :in  std_logic_vector (7 downto 0);  -- end of frame comma
        rx_fifo_almost_full_b  :in  std_logic;
        rx_fifo_wr_en_b        :out std_logic;   -- pulse of one clock length
        rx_fifo_din            :out std_logic_vector (7 downto 0) -- shared by both Rx_fifos
       );
  end component rx_ctrl_8b10b;

  constant K28_0    : std_logic_vector(7 downto 0) := B"000_11100"; -- H...A
  constant K28_2    : std_logic_vector(7 downto 0) := B"010_11100"; -- H...A
  constant K28_4    : std_logic_vector(7 downto 0) := B"100_11100"; -- H...A
  constant K28_6    : std_logic_vector(7 downto 0) := B"110_11100"; -- H...A
  
  constant K28_0M   : std_logic_vector(9 downto 0) := B"0010_111100"; -- j...a
  constant K28_0P   : std_logic_vector(9 downto 0) := B"1101_000011"; -- j...a
  
  constant COM_ADC_THR_mV    : natural range 0 to 255 := 2;  -- ADC data difference between consecutive ADC samples to detect signal edges
  constant COM_ADC_THRESHOLD : std_logic_vector :=  CONV_STD_LOGIC_VECTOR((COM_ADC_THR_mV * 1000)/ 61, 9); -- 14bit, Vref=1V, 0.061mV / digit


-- global signals

  signal reset         : std_logic := '0'; -- synchronous power up reset
  signal clk           : std_logic := '0'; -- by PLL
  signal com_reset     : std_logic := '0'; -- synchronous power up reset
  signal com_clk       : std_logic := '0'; -- by PLL, 8b10b communication clock domain
  signal not_com_clk   : std_logic := '0'; -- by PLL
  
  
-- UART signals, rx/tx by FPGA view

  signal rx_uart_ena            : std_logic; -- from baudrate generator
  signal tx_uart_ena            : std_logic;
                             
  signal tx_uart_data_valid_a   : std_logic;
  signal tx_uart_data_in_a      : std_logic_vector (7 downto 0);
  signal tx_uart_ack_a          : std_logic;
  signal tx_uart_out_a          : std_logic;  -- connect to serial data output
                             
  signal rx_uart_in_a           : std_logic;  -- connect to serial data input
  signal rx_uart_data_out_a     : std_logic_vector (7 downto 0);
  signal rx_uart_data_valid_a   : std_logic;
                             
  signal tx_uart_data_valid_b   : std_logic;
  signal tx_uart_data_in_b      : std_logic_vector (7 downto 0);
  signal tx_uart_ack_b          : std_logic;
  signal tx_uart_out_b          : std_logic;  -- connect to serial data output
                             
  signal rx_uart_in_b           : std_logic;  -- connect to serial data input
  signal rx_uart_data_out_b     : std_logic_vector (7 downto 0);
  signal rx_uart_data_valid_b   : std_logic;

-- TxFIFO signals

  --signal tx_fifo_wr_en_a        : std_logic;
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
  signal rx_fifo_din            : std_logic_vector (7 downto 0);
  signal rx_fifo_dout_b         : std_logic_vector (7 downto 0);
  signal rx_fifo_full_b         : std_logic;
  signal rx_fifo_almost_full_b  : std_logic;
  signal rx_fifo_empty_b        : std_logic;
  
-- 8b10b signals

  signal enc_8b10b_reset        : std_logic;
  signal enc_8b10b_in           : std_logic_vector (7 downto 0);
  signal enc_8b10b_ena          : std_logic;
  signal enc_comma_stb          : std_logic;
  signal tx_ena_8b10b           : std_logic;
  signal tx_data_in_8b10b       : std_logic_vector (9 downto 0);
  signal tx_data_valid_8b10b    : std_logic;
  signal tx_run_8b10b           : std_logic;
  signal tx_done_8b10b          : std_logic;
  signal tx_ack_8b10b           : std_logic;
  signal tx_out_8b10b           : std_logic;
  signal tx_quiet_8b10b         : std_logic;
  signal baudrate_adj           : std_logic_vector(3 downto 0);
  
  signal rx_in_8b10b            : std_logic;
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
  signal com_thr_adj            : std_logic_vector(2 downto 0);
-- 8b10 encoder test
--  signal enc_test_d             : std_logic_vector (7 downto 0);
--  signal enc_test_ko            : std_logic;

  signal com_adc_sdout         : std_logic; -- comm. ADC decoder output
  
 begin 
 
  -- clock, reset generation and baudrates ------------------------------------------------------- 
 
  pll_01_port_map:
   pll_01 port map
   (
     qosc_25MHz    => QOSC_25MHZ,
     clk           => clk,
     com_clk       => com_clk,
     not_com_clk   => not_com_clk,
     com_reset     => com_reset,
     clk_6MHz      => CLK_6MHZ,
     reset         => reset
   );

   uart_baudrate_generator_port_map:
    uart_baudrate_generator port map
   ( 
     reset    => reset,
     clk      => clk,
     tx_ena   => tx_uart_ena,
     rx_ena   => rx_uart_ena
   );

  var_baudrate_generator_8b10b_port_map:
   var_baudrate_generator_8b10b port map
    ( 
     reset        => com_reset,
     clk          => com_clk,
     baudrate_adj => baudrate_adj,
     tx_ena       => tx_ena_8b10b
    );
 
  -- USB to comm. DAC chain, see below -----------------------------------------------------------
  
  rx_uart_in_a <= tx_uart_out_a;--ADBUS0;
  
  uart_receiver_a_port_map:
   uart_receiver port map
   (
    reset          => reset,
    clk            => clk,
    rx_ena         => rx_uart_ena,
    rx_in          => rx_uart_in_a,
    rx_data_out    => rx_uart_data_out_a,
    rx_data_valid  => rx_uart_data_valid_a
    );

  --tx_fifo_wr_en_a  <= rx_uart_data_valid_a;
   
  tx_fifo_a_port_map:
   fifo_4KB_dual_clock port map
   (
    rst         => reset,
    wr_clk      => clk,
    rd_clk      => com_clk,
    din         => rx_uart_data_out_a,
    wr_en       => rx_uart_data_valid_a,
    rd_en       => tx_fifo_rd_en_a,
    dout        => tx_fifo_dout_a, 
    full        => tx_fifo_full_a,
    almost_full => tx_fifo_almost_full_a,
    empty       => tx_fifo_empty_a
  );
  
 rx_uart_in_b <= tx_uart_out_b; --BDBUS0;

 uart_receiver_b_port_map:
   uart_receiver port map
   (
    reset          => reset,
    clk            => clk,
    rx_ena         => rx_uart_ena,
    rx_in          => rx_uart_in_b,
    rx_data_out    => rx_uart_data_out_b,
    rx_data_valid  => rx_uart_data_valid_b
    );

  --tx_fifo_wr_en_b  <= rx_uart_data_valid_b;
  
  tx_fifo_b_port_map:
   fifo_4KB_dual_clock port map
   (
    rst         => reset,
    wr_clk      => clk,
    rd_clk      => com_clk,
    din         => rx_uart_data_out_b,
    wr_en       => rx_uart_data_valid_b,
    rd_en       => tx_fifo_rd_en_b,
    dout        => tx_fifo_dout_b, 
    full        => tx_fifo_full_b,
    almost_full => tx_fifo_almost_full_b,
    empty       => tx_fifo_empty_b
  );


  tx_ctrl_8b10b_port_map:
   tx_ctrl_8b10b port map
  (
    com_reset       => com_reset, 
    com_clk         => com_clk,         
    tx_fifo_empty_a => tx_fifo_empty_a,   
    tx_fifo_rd_en_a => tx_fifo_rd_en_a,   
    tx_fifo_dout_a  => tx_fifo_dout_a,
    tx_fifo_empty_b => tx_fifo_empty_b,   
    tx_fifo_rd_en_b => tx_fifo_rd_en_b,   
    tx_fifo_dout_b  => tx_fifo_dout_b,    
    STF_COMMA_a     => K28_0,       
    EOF_COMMA_a     => K28_2,       
    STF_COMMA_b     => K28_4,       
    EOF_COMMA_b     => K28_6,       
    enc_8b10b_reset => enc_8b10b_reset,
    enc_8b10b_ena   => enc_8b10b_ena,
    enc_8b10b_in    => enc_8b10b_in,    
    enc_comma_stb   => enc_comma_stb,   
    tx_run_8b10b    => tx_run_8b10b,
    tx_ack_8b10b    => tx_ack_8b10b,
    tx_done_8b10b   => tx_done_8b10b   
   );
 
  free_8b10b_enc_port_map:
   free_8b10b_enc port map
    (
		RESET    => enc_8b10b_reset,
		SBYTECLK => com_clk,
		KI       => enc_comma_stb,
		AI       => enc_8b10b_in(0),
    BI       => enc_8b10b_in(1),
    CI       => enc_8b10b_in(2),
    DI       => enc_8b10b_in(3),
    EI       => enc_8b10b_in(4),
    FI       => enc_8b10b_in(5),
    GI       => enc_8b10b_in(6),
    HI       => enc_8b10b_in(7), 
		ENA      => enc_8b10b_ena,			-- Global enable input
		JO       => tx_data_in_8b10b(9),
    HO       => tx_data_in_8b10b(8),
    GO       => tx_data_in_8b10b(7),
    FO       => tx_data_in_8b10b(6),
    IO       => tx_data_in_8b10b(5),
    EO       => tx_data_in_8b10b(4),
    DO       => tx_data_in_8b10b(3),
    CO       => tx_data_in_8b10b(2),
    BO       => tx_data_in_8b10b(1),
    AO       => tx_data_in_8b10b(0) -- Encoded out
	  );
 
-- free_8b10b_enc_test_port_map:
--   free_8b10b_dec port map
--    (
--		RESET    => com_reset, --dec_8b10b_reset, --
--		RBYTECLK => com_clk,
--		AI       => tx_data_in_8b10b(0),
--    BI       => tx_data_in_8b10b(1),
--    CI       => tx_data_in_8b10b(2),
--    DI       => tx_data_in_8b10b(3),
--    EI       => tx_data_in_8b10b(4),
--    II       => tx_data_in_8b10b(5),
--    FI       => tx_data_in_8b10b(6),
--    GI       => tx_data_in_8b10b(7),
--    HI       => tx_data_in_8b10b(8),
--    JI       => tx_data_in_8b10b(9),   
--   	KO       => enc_test_ko,
--    HO       => enc_test_d(7),
--    GO       => enc_test_d(6),
--    FO       => enc_test_d(5),
--    EO       => enc_test_d(4),
--    DO       => enc_test_d(3),
--    CO       => enc_test_d(2),
--    BO       => enc_test_d(1),
--    AO       => enc_test_d(0) -- decoded out
--	  );
 
  transmitter_8b10b_port_map:
   transmitter_8b10b port map
   (
     com_reset         => com_reset,
     com_clk           => com_clk,
     tx_run_8b10b      => tx_run_8b10b,
     tx_data_in_8b10b  => tx_data_in_8b10b,
     tx_ena_8b10b      => tx_ena_8b10b,
     tx_ack_8b10b      => tx_ack_8b10b,
     tx_done_8b10b     => tx_done_8b10b,
     tx_quiet_8b10b    => tx_quiet_8b10b,
		 tx_out_8b10b      => tx_out_8b10b
    );

  com_dac_enc_port_map:
   com_dac_enc port map
   (
        reset           => com_reset,
        clk             => com_clk,
        sdin            => tx_out_8b10b,
        com_dac_quiet   => tx_quiet_8b10b,  
        com_dac_in      => COM_DAC_DB, -- upper 8 bits used only here
        com_dac_clock   => COM_DAC_CLOCK
    );
  

 -- comm. ADC to USB chain, see below ------------------------------------------------------------
 
 
  
  
  
 com_adc_dec_port_map:
  com_adc_dec port map
  (
     reset           => com_reset,
     clk             => com_clk,           -- 60 MHz comm. clock
     com_thr_adj     => com_thr_adj, 
     COM_ADC_CSBn    => COM_ADC_CSBn, 
     COM_ADC_SCLK    => COM_ADC_SCLK, 
     COM_ADC_SDIO    => COM_ADC_SDIO, 
     COM_ADC_D       => COM_ADC_D,    
     COM_ADC_CLK_N   => COM_ADC_CLK_N,
     COM_ADC_CLK_P   => COM_ADC_CLK_P,
     com_adc_sdout   => com_adc_sdout     -- decoder serial data output      
   );

   --rx_in_8b10b  <= tx_out_8b10b; -- for simulation
--  rx_in_8b10b  <= com_adc_sdout;

  receiver_8b10b_port_map:
   receiver_8b10b port map
   (
    reset           => com_reset,
    clk             => com_clk,
    baudrate_adj    => baudrate_adj,
    dec_8b10b_reset => dec_8b10b_reset,
    rx_in           => rx_in_8b10b,
    rx_data_out     => rx_data_out_8b10b,
    rx_data_valid   => rx_data_valid_8b10b,
    dec_8b10b_valid => dec_8b10b_valid,
    rx_lh_nd             => rx_lh,            
    rx_hl_nd             => rx_hl,            
    rx_syncd_nd          => rx_syncd,         
    rx_data_stb          => rx_data_stb      
    );

 free_8b10b_dec_port_map:
   free_8b10b_dec port map
    (
		RESET    => com_reset, --dec_8b10b_reset, --
		RBYTECLK => com_clk,
		AI       => rx_data_out_8b10b(0),
    BI       => rx_data_out_8b10b(1),
    CI       => rx_data_out_8b10b(2),
    DI       => rx_data_out_8b10b(3),
    EI       => rx_data_out_8b10b(4),
    II       => rx_data_out_8b10b(5),
    FI       => rx_data_out_8b10b(6),
    GI       => rx_data_out_8b10b(7),
    HI       => rx_data_out_8b10b(8),
    JI       => rx_data_out_8b10b(9),  
   	KO       => dec_8b10b_ko,
    HO       => dec_8b10b_out(7),
    GO       => dec_8b10b_out(6),
    FO       => dec_8b10b_out(5),
    EO       => dec_8b10b_out(4),
    DO       => dec_8b10b_out(3),
    CO       => dec_8b10b_out(2),
    BO       => dec_8b10b_out(1),
    AO       => dec_8b10b_out(0) -- decoded out
	  );

  rx_fifo_a_port_map:
   fifo_4KB_dual_clock port map
   (
    rst         => reset,
    wr_clk      => com_clk,
    rd_clk      => clk,
    din         => rx_fifo_din,
    wr_en       => rx_fifo_wr_en_a,
    rd_en       => rx_fifo_rd_en_a,
    dout        => rx_fifo_dout_a, 
    full        => rx_fifo_full_a,
    almost_full => rx_fifo_almost_full_a,
    empty       => rx_fifo_empty_a
  );
  
   rx_fifo_b_port_map:
   fifo_4KB_dual_clock port map
   (
    rst         => reset,
    wr_clk      => com_clk,
    rd_clk      => clk,
    din         => rx_fifo_din,
    wr_en       => rx_fifo_wr_en_b,
    rd_en       => rx_fifo_rd_en_b,
    dout        => rx_fifo_dout_b, 
    full        => rx_fifo_full_b,
    almost_full => rx_fifo_almost_full_b,
    empty       => rx_fifo_empty_b
  );
  
  rx_ctrl_8b10b_port_map:
   rx_ctrl_8b10b port map
   (
    com_reset              => com_reset,
    com_clk                => com_clk,
    dec_8b10b_out          => dec_8b10b_out,  
    dec_8b10b_valid        => dec_8b10b_valid,
    dec_8b10b_ko           => dec_8b10b_ko,   
    STF_COMMA_a            => K28_0,
    EOF_COMMA_a            => K28_2,
    rx_fifo_almost_full_a  => rx_fifo_almost_full_a,
    rx_fifo_wr_en_a        => rx_fifo_wr_en_a,
    STF_COMMA_b            => K28_4,
    EOF_COMMA_b            => K28_6,
    rx_fifo_almost_full_b  => rx_fifo_almost_full_a,
    rx_fifo_wr_en_b        => rx_fifo_wr_en_b,
    rx_fifo_din            => rx_fifo_din
   );


   tx_uart_data_valid_a <= not rx_fifo_empty_a;
  
  uart_transmitter_a_port_map:
   uart_transmitter port map
  (
    reset          => reset,
    clk            => clk,
    tx_data_valid  => tx_uart_data_valid_a,
    tx_data_in     => rx_fifo_dout_a,
    tx_ena         => tx_uart_ena,
    tx_ack         => rx_fifo_rd_en_a,
		tx_out         => tx_uart_out_a
   );

   ADBUS1         <= tx_uart_out_a;

   tx_uart_data_valid_b <= not rx_fifo_empty_b;
  
  uart_transmitter_b_port_map:
   uart_transmitter port map
  (
    reset          => reset,
    clk            => clk,
    tx_data_valid  => tx_uart_data_valid_b,
    tx_data_in     => rx_fifo_dout_b,
    tx_ena         => tx_uart_ena,
    tx_ack         => rx_fifo_rd_en_b,
		tx_out         => tx_uart_out_b
   );
           
   BDBUS1         <= tx_uart_out_b;

   --rx_uart_in_a     <= ADBUS0;
  --ADBUS1           <= tx_uart_out_a;
  RX_LEDn          <= '0' when ACBUS2 = '0' else 'Z';
  TX_LEDn          <= '0' when ACBUS3 = '0' else 'Z';
  
  FT_TEST   <= '0';
  FT_RESETn <= not reset;
 
  baudrate_adj(0) <= TEST_IO1;
  baudrate_adj(1) <= TEST_IO3;
  baudrate_adj(2) <= TEST_IO5;
  baudrate_adj(3) <= TEST_IO7;

  com_thr_adj(0)  <= TEST_IO9;
  com_thr_adj(1)  <= TEST_IO11;
  com_thr_adj(2)  <= TEST_IO13;

  TEST_IO0  <= '0';--reset;
  TEST_IO2  <= '0';--tx_uart_out_a;
  TEST_IO4  <= '0';--tx_fifo_wr_en_a;
  TEST_IO6  <= '0';--tx_ack_8b10b;
  TEST_IO8  <= '0';
  --TEST_IO9  <= rx_lh            ;--rx_data_valid_8b10b;
  TEST_IO10 <= '0';--dec_8b10b_valid;
  -- TEST_IO11 <= rx_syncd         ;--dec_8b10b_ko;
  TEST_IO12 <= '0';--rx_fifo_wr_en_a;
  -- TEST_IO13 <= dec_8b10b_reset;--rx_in_8b10b;
  TEST_IO14 <= rx_data_stb;
  
  TEST_IO15 <= com_adc_sdout;
  
  
  
               
  rx_in_8b10b <= com_adc_sdout;--tx_out_8b10b;--TEST_IO12 or TEST_IO14;
 
   
 end architecture uvl_reflector_top_01_arch;
 