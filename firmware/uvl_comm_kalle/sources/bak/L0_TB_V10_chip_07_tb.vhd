-------------------------------------------------------
-- Design Name : L0_TB_V10_chip_07_tb
-- File Name   : L0_TB_V10_chip_07_tb.vhd
-- Function    : UART transmitter test bench
-- Coder       : K.-H. Sulanke, DESY
-- Date        : 2016-08-15
-------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
 
entity L0_TB_V10_chip_07_tb is
end L0_TB_V10_chip_07_tb;

architecture behavior of L0_TB_V10_chip_07_tb is
  
  component l0_tb_v10_chip_07_top
  generic (
            USE_LOCAL_CLOCK : boolean := true -- "false" -> diff. external clock is being used
            --N : integer := 8 ;   -- amount of serial data channel
           -- S	: integer := 8	 -- Parameter to set the serdes factor 1..8  
          );
  port
   (
     --RESETn             : in  std_logic ;   -- 2.5V CMOS, reset (low active) by charging 1uF with 10K     
     EXTCLK_P           : in  std_logic;    -- diff. clock, from trigger backplane, J11-C7
     EXTCLK_N           : in  std_logic;    -- diff. clock, from trigger backplane, J11-D7
 
     QOSC_OUT           : in  std_logic;    --2.5V CMOS, local 50 MHz TTL oscillator
     QOSC_ENA           : out std_logic;    --2.5V CMOS, oscillator enable
 
     RS232_RXD          : in  std_logic;   --2.5V CMOS, RS-232 communication
     RS232_TXD          : out std_logic;   --2.5V CMOS, RS-232 communication
      
     RS485_RXD          : in  std_logic;   --2.5V CMOS, RS-485 communication
     RS485_TXD          : out std_logic;   --2.5V CMOS, RS-485 communication
     RS485_TX_ENA       : out std_logic;   --2.5V CMOS, RS-485 communication
     ADM2483_PV         : out std_logic;   --2.5V CMOS, RS-485 transceiver-power-valid signal
   
     ETH_LED1           : out std_logic;   --2.5V CMOS, part of the gigabit ethernet jack, located on the trigger backplane
     ETH_LED2           : out std_logic;   --2.5V CMOS, part of the gigabit ethernet jack, located on the trigger backplane
   
     DAC_DIN            : out std_logic;   --2.5V CMOS, SPI interface to L0 trigger threshold dac
     DAC_SCLK           : out std_logic;   --2.5V CMOS 
     DAC_SYNC_N         : out std_logic;   --2.5V CMOS
     DAC_DOUT           : in  std_logic;   --2.5V CMOS 

     CMOS_IO            : out std_logic_vector (2 downto 0);  -- J4, 2x10 pin  header, inout,2.5V CMOS or LVDS, reserved, test pins
     CMOS_IO_IN         : in  std_logic_vector (7 downto 3);      --  3 is low active RS485_enable,7..4 are being used as ADR_SW
 
     DISCR_OUT_P     : in  std_logic_vector (6 downto 0);      -- LVDS, from low level dicriminator
     DISCR_OUT_N     : in  std_logic_vector (6 downto 0);      -- 

     CL0_P           : out std_logic_vector (6 downto 0);   -- LVDS, from high level dicriminator
     CL0_N           : out std_logic_vector (6 downto 0);   -- 
  
     LVDS_IO_P       : out std_logic_vector(3 downto 0); -- J5, RJ45, LVDS bidir. test port
     LVDS_IO_N       : out std_logic_vector(3 downto 0); -- 
   
     TIMEPPS_P       : in std_logic;  -- LVDS, 
     TIMEPPS_N       : in std_logic;  -- 
    
     TRGL1_P         : in std_logic;  -- LVDS, 
     TRGL1_N         : in std_logic;  -- 
    
     TRGCONF_P       : in std_logic;  -- LVDS, 
     TRGCONF_N       : in std_logic;  -- 

     TRGTYPE_P       : in std_logic_vector (0 to 2); -- LVDS, 
     TRGTYPE_N       : in std_logic_vector (0 to 2);
     
     FPGA_SLOW_CTRL0 : out std_logic ; -- 2.5V CMOS, SPI_CLK
     FPGA_SLOW_CTRL1 : out std_logic ; -- 2.5V CMOS, SPI_MOSI
     FPGA_SLOW_CTRL2 : out std_logic ; -- 2.5V CMOS, SPI_CE
     FPGA_SLOW_CTRL3 : in  std_logic ; -- 2.5V CMOS, SPI_MISO
     --FPGA_SLOW       : in std_logic_vector (0 to 3); -- 2.5V CMOS, bidir, 
 
     IDW_IPADDR      : out std_logic; -- 2.5V CMOS, bidir, 
     PROGRAM_B       : out std_logic;   -- 2.5V CMOS, bidir, 
      
     ETH0_P          : out std_logic; -- LVDS, test output
     ETH0_N          : out std_logic; -- LVDS, test output
     ETH1_P          : out std_logic; -- LVDS, test output
     ETH1_N          : out std_logic; -- LVDS, test output
     ETH2_P          : out std_logic; -- LVDS, test output
     ETH2_N          : out std_logic; -- LVDS, test output
     ETH3_P          : out std_logic; -- LVDS, test output
     ETH3_N          : out std_logic; -- LVDS, test output
  
     SPARES3_P       : out std_logic;  -- 2.5V CMOS inout / LVDS inout_P,
     SPARES3_N       : out std_logic  -- 2.5V CMOS inout / LVDS inout_N, 
   );
end component l0_tb_v10_chip_07_top;


--signal  RESETn             : std_logic := 'U';   -- 2.5V CMOS, reset (low active) by charging 1uF with 10K     
signal  EXTCLK_P           : std_logic;    -- diff. clock, from trigger backplane, J11-C7
signal  EXTCLK_N           : std_logic;    -- diff. clock, from trigger backplane, J11-D7

signal  QOSC_OUT           : std_logic := '0';    --2.5V CMOS, local 50 MHz TTL oscillator
signal  QOSC_ENA           : std_logic;    --2.5V CMOS, oscillator enable

signal  RS232_RXD          : std_logic;   --2.5V CMOS, RS-232 communication
signal  RS232_TXD          : std_logic;   --2.5V CMOS, RS-232 communication

signal  RS485_RXD          : std_logic;   --2.5V CMOS, RS-485 communication
signal  RS485_TXD          : std_logic;   --2.5V CMOS, RS-485 communication
signal  RS485_TX_ENA       : std_logic;   --2.5V CMOS, RS-485 communication
signal  ADM2483_PV         : std_logic;   --

signal  ETH_LED1           : std_logic;   --2.5V CMOS, part of the gigabit ethernet jack, located on the trigger backplane
signal  ETH_LED2           : std_logic;   --2.5V CMOS, part of the gigabit ethernet jack, located on the trigger backplane

signal  DAC_DIN            : std_logic;   --2.5V CMOS, SPI interface to L0 trigger threshold dac
signal  DAC_SCLK           : std_logic;   --2.5V CMOS 
signal  DAC_SYNC_N         : std_logic;   --2.5V CMOS
signal  DAC_DOUT           : std_logic;   --2.5V CMOS 

signal  CMOS_IO            : std_logic_vector (2 downto 0);  -- J4, 2x10 pin  header, inout,2.5V CMOS or LVDS, reserved, test pins
signal  CMOS_IO_IN         : std_logic_vector (7 downto 3);    -- 3 to select between RS232/485, 4..5 are being used as ADR_SW

signal  DISCR_OUT_P        : std_logic_vector (6 downto 0) := B"0000000";      -- LVDS, from low level dicriminator
signal  DISCR_OUT_N        : std_logic_vector (6 downto 0) := B"0000000";     -- 
  
signal  CL0_P              : std_logic_vector (6 downto 0);   -- LVDS, from high level dicriminator
signal  CL0_N              : std_logic_vector (6 downto 0);   -- 
  
signal  LVDS_IO_P          : std_logic_vector(3 downto 0); -- J5, RJ45, LVDS bidir. test port
signal  LVDS_IO_N          : std_logic_vector(3 downto 0); -- 
  
signal  TIMEPPS_P          : std_logic;  -- LVDS, 
signal  TIMEPPS_N          : std_logic;  -- 
  
signal  TRGL1_P            : std_logic;  -- LVDS, 
signal  TRGL1_N            : std_logic;  -- 
  
signal  TRGCONF_P          : std_logic;  -- LVDS, 
signal  TRGCONF_N          : std_logic;  -- 
  
signal  TRGTYPE_P          : std_logic_vector (0 to 2); -- LVDS, 
signal  TRGTYPE_N          : std_logic_vector (0 to 2);

signal  FPGA_SLOW_CTRL0    : std_logic ; -- 2.5V CMOS, SPI_CLK
signal  FPGA_SLOW_CTRL1    : std_logic ; -- 2.5V CMOS, SPI_MOSI
signal  FPGA_SLOW_CTRL2    : std_logic ; -- 2.5V CMOS, SPI_CE
signal  FPGA_SLOW_CTRL3    : std_logic ; -- 2.5V CMOS, SPI_MISO  
  
signal  IDW_IPADDR         : std_logic; -- 2.5V CMOS, bidir, 
signal  PROGRAM_B          : std_logic;   -- 2.5V CMOS, bidir, 
         
signal  ETH0_P             : std_logic; -- LVDS, test output
signal  ETH0_N             : std_logic; -- LVDS, test output
signal  ETH1_P             : std_logic; -- LVDS, test output
signal  ETH1_N             : std_logic; -- LVDS, test output
signal  ETH2_P             : std_logic; -- LVDS, test output
signal  ETH2_N             : std_logic; -- LVDS, test output
signal  ETH3_P             : std_logic; -- LVDS, test output
signal  ETH3_N             : std_logic; -- LVDS, test output
        
signal  SPARES3_P          : std_logic;  -- 2.5V CMOS inout / LVDS inout_P,
signal  SPARES3_N          : std_logic;  -- 2.5V CMOS inout / LVDS inout_N, 


  component uart
    port(
      reset         : in std_logic;
      clk           : in std_logic;

      tx_data_valid : in  std_logic;
      tx_data_in    : in  std_logic_vector (7 downto 0);
      tx_busy       : out std_logic;
      tx_ack        : out std_logic;
      tx_out        : out std_logic;

      rx_in         : in  std_logic;
      rx_data_out   : out std_logic_vector (7 downto 0);
      rx_data_valid : out std_logic
      );
  end component uart;


-- inputs
  signal reset         : std_logic                     := 'U';
  signal clk           : std_logic                     := '0';
  signal tx_data_valid : std_logic                     := '0';
  signal rx_in         : std_logic;
  signal tx_data_in    : std_logic_vector (7 downto 0) := (others => 'U');

-- outputs
  signal tx_ack        : std_logic := '0';
  signal tx_out        : std_logic := '0';
  signal tx_busy       : std_logic;
  signal rx_data_out   : std_logic_vector (7 downto 0) := (others => 'U');
  signal rx_data_valid : std_logic;
 
  constant clk_period      : time := 10 ns;
  constant qosc_clk_period : time := 10 ns;
  
  component spi_slave_8bit_01
  port
   (
     tx_data         : in  std_logic_vector (7 downto 0); -- data to be sent
     tx_done         : out std_logic;   -- tx data sent 
     rx_data         : out std_logic_vector (7 downto 0); -- data received
     rx_data_val     : out std_logic;   -- Rx data vaild
     rx_addr         : out std_logic_vector ( 6 downto 0); -- register address
     rx_addr_val     : out std_logic;   -- Rx data vaild
     rx_wr_nrd       : out  std_logic ; -- spi cycle is active
     spi_sync        : in  std_logic ;  -- backplane bus, low active sync signal
     spi_sclk        : in  std_logic ;  -- backplane bus, SPI clock
     spi_mosi        : in  std_logic ;  -- backplane bus, serial SPI tx-data
     spi_miso        : out std_logic ;   -- backplane bus, serial SPI rx-data
     spi_miso_trst   : out std_logic    -- to disable the LVDS bus driver
   );
  end component spi_slave_8bit_01;
  
component reg_array is
  generic (
           REG_WIDTH    : integer :=   8; -- register width
           BLOCK_SIZE   : integer :=   7  -- register array size
          );
  port
   (
    clk            : in  std_logic;
    reg_addr       : in  std_logic_vector (BLOCK_SIZE-1 downto 0);
    reg_wr_ena     : in  std_logic;                                -- synchronous write enable
    reg_data_in    : in  std_logic_vector (REG_WIDTH-1 downto 0);  -- 
    reg_data_out   : out std_logic_vector (REG_WIDTH-1 downto 0)  -- 
    );
end component reg_array; 

  constant REG_WIDTH    : integer :=   8; -- register width
  constant BLOCK_SIZE   : integer :=   7; 
   
  signal reg_addr       : std_logic_vector (BLOCK_SIZE-1 downto 0):= (others => '0');
  signal reg_wr_ena     : std_logic;                                -- synchronous write enable
  signal reg_data_in    : std_logic_vector (REG_WIDTH-1 downto 0);  -- 
  signal reg_data_out   : std_logic_vector (REG_WIDTH-1 downto 0);  --  

begin

  clk <= not clk after clk_period / 2;
 
  reset <= '1', '0' after 100 ns; --, '0' after 50 ns;
 
  --RESETn <= '0', '1' after 90 ns; --, '0' after 50 ns;
  
  QOSC_OUT <= not QOSC_OUT after qosc_clk_period / 2;


  RS232_RXD   <= tx_out;     -- not tx_out;   external UART connected for serilization / deserialization
  rx_in       <= RS232_TXD;  -- "not" due to the transceiver LTC1386 inverters

-- DISCR_OUT_gen: process
--   variable i   : integer;
--  begin
--    while (true) loop
--      for i in 0 to 6 loop
--       DISCR_OUT_P(i) <= '1';
--       DISCR_OUT_N(i) <= '0';
--      end loop;
--       wait for 2 ns;
--      for i in 0 to 6 loop
--       DISCR_OUT_P(i) <= '0';
--       DISCR_OUT_N(i) <= '1';
--      end loop;
--      wait for 8 ns;
--    end loop;
--  end process DISCR_OUT_gen;  
	
L0_TB_V10_test: process
  	
--	 variable message     : string (1 to message_len) := "  DAC  7  0 5 1234  " & cr & lf;
--  	constant DAC_CMD_STRG : string := "dac75123  " &cr; --&lf&"ver  " &cr&lf&cr&lf;
--  	constant VER_CMD_STRG : string := "ver7  " &cr; --&lf&"ver  " &cr&lf&cr&lf;
  	
    constant FWR_CMD_STRG : string := "fwr b7" &cr&lf;
    constant VER_CMD_STRG : string := "ver b7" &cr&lf;
  	constant DAC_CMD_STRG : string := "dacb7c5d123" &cr&lf;
    constant BWR_CMD_STRG : string := "bwr b7 a56 d234" &cr&lf;
    constant BRD_CMD_STRG : string := "brd b7 a56" &cr&lf;
    constant BWR_CMD_HEX_STRG : string := "bwr b7 a5b dcd" &cr&lf;
    constant BRD_CMD_HEX_STRG : string := "brd b7 a5b" &cr&lf;
    constant ILL_CMD_STRG : string := "abcd" &cr&lf;

  	variable message_len : integer;
  	variable i           : integer;
	variable char        : character;
	variable char_ascii  : integer range 0 to 255;
		   
	begin
	   tx_data_valid     <= '0';
     CMOS_IO_IN        <= B"01111";   -- board nr. #7, (DIP-switch), RS232 enabled, RS485 disabled
 	   wait until (reset = '0');
	   wait for clk_period * 10;

      message_len := ILL_CMD_STRG'length;
      tx_data_valid <= '1';
	    send_ill_cmd: for i in 1 to message_len loop
	       -- conversion to ASCII code by getting the position of char
	       -- in the ASCII table "CHARACTER" 
	       char          := ILL_CMD_STRG(i);
	       char_ascii    := CHARACTER'pos(char);
	       tx_data_in    <= std_logic_vector( to_unsigned ( char_ascii, 8));
	       wait until tx_ack = '1';
	       wait for clk_period *1; -- 
	    end loop send_ill_cmd;
	    tx_data_valid    <= '0';     
      wait until CMOS_IO(0) = '1'; -- tx_data_sent, command acknowlege message sent
      wait for clk_period * 100;  
     
      message_len := VER_CMD_STRG'length;
      tx_data_valid <= '1';
	    send_ver_cmd: for i in 1 to message_len loop
	       -- conversion to ASCII code by getting the position of char
	       -- in the ASCII table "CHARACTER" 
	       char          := VER_CMD_STRG(i);
	       char_ascii    := CHARACTER'pos(char);
	       tx_data_in    <= std_logic_vector( to_unsigned ( char_ascii, 8));
	       wait until tx_ack = '1';
	       wait for clk_period *1; -- 
	    end loop send_ver_cmd;
	    tx_data_valid    <= '0';     
      wait until CMOS_IO(0) = '1'; -- tx_data_sent, command acknowlege message sent
      wait for clk_period * 100;     
 
      message_len := FWR_CMD_STRG'length;
      tx_data_valid <= '1';
	    send_fwr_cmd: for i in 1 to message_len loop
	       -- conversion to ASCII code by getting the position of char
	       -- in the ASCII table "CHARACTER" 
	       char          := FWR_CMD_STRG(i);
	       char_ascii    := CHARACTER'pos(char);
	       tx_data_in    <= std_logic_vector( to_unsigned ( char_ascii, 8));
	       wait until tx_ack = '1';
	       wait for clk_period *1; -- 
	    end loop send_fwr_cmd;
	    tx_data_valid    <= '0';     
      wait until CMOS_IO(0) = '1'; -- tx_data_sent, command acknowlege message sent
      wait for clk_period * 100;   

      message_len := DAC_CMD_STRG'length;
      tx_data_valid <= '1';
	    send_dac_cmd: for i in 1 to message_len loop
	       -- conversion to ASCII code by getting the position of char
	       -- in the ASCII table "CHARACTER" 
	       char          := DAC_CMD_STRG(i);
	       char_ascii    := CHARACTER'pos(char);
	       tx_data_in    <= std_logic_vector( to_unsigned ( char_ascii, 8));
	       wait until tx_ack = '1';
	       wait for clk_period *1; -- 
	    end loop send_dac_cmd;
	    tx_data_valid    <= '0';     
      wait until CMOS_IO(0) = '1'; -- tx_data_sent, command acknowlege message sent
      wait for clk_period * 100;
 
      message_len := BWR_CMD_HEX_STRG'length;
      tx_data_valid <= '1';
	    send_bwr_cmd: for i in 1 to message_len loop
	       -- conversion to ASCII code by getting the position of char
	       -- in the ASCII table "CHARACTER" 
	       char          := BWR_CMD_HEX_STRG(i);
	       char_ascii    := CHARACTER'pos(char);
	       tx_data_in    <= std_logic_vector( to_unsigned ( char_ascii, 8));
	       wait until tx_ack = '1';
	       wait for clk_period *1; -- 
	    end loop send_bwr_cmd;
	    tx_data_valid    <= '0';     
      wait until CMOS_IO(0) = '1'; -- tx_data_sent, command acknowlege message sent
      wait for clk_period * 100;
           
      message_len := BRD_CMD_HEX_STRG'length;
      tx_data_valid <= '1';
      send_brd_cmd: for i in 1 to  message_len loop
	       char         := BRD_CMD_HEX_STRG(i);
	       char_ascii   := CHARACTER'pos(char);       
	       tx_data_in    <= std_logic_vector( to_unsigned ( char_ascii, 8));
         wait until tx_ack = '1';
	    end loop send_brd_cmd; 
  	  tx_data_valid    <= '0';
	    wait for clk_period * 100;
      wait until CMOS_IO(0) = '1'; -- tx_data_sent, command acknowlege message sent
      --wait until rising_edge(CMOS_IO(0)); -- tx_data_sent
      --wait for 300us;
      --wait for clk_period * 300 * 100;
      
	   wait;
  	    
	end process L0_TB_V10_test; 


	    
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

l0_tb_v10_chip_07_top_port_map:  component l0_tb_v10_chip_07_top
  generic map( USE_LOCAL_CLOCK => true )-- "false" -> diff. external clock is being used
   port map
   (
    --RESETn             =>     RESETn       ,
    EXTCLK_P           =>     EXTCLK_P     ,
    EXTCLK_N           =>     EXTCLK_N     ,
                          
    QOSC_OUT           =>     QOSC_OUT     ,
    QOSC_ENA           =>     QOSC_ENA     ,
                          
    RS232_RXD          =>     RS232_RXD    ,
    RS232_TXD          =>     RS232_TXD    ,
                               
    RS485_RXD          =>     RS485_RXD    ,
    RS485_TXD          =>     RS485_TXD    ,
    RS485_TX_ENA       =>     RS485_TX_ENA ,
                            
    ETH_LED1           =>     ETH_LED1     ,
    ETH_LED2           =>     ETH_LED2     ,
                            
    DAC_DIN            =>     DAC_DIN      ,
    DAC_SCLK           =>     DAC_SCLK     ,
    DAC_SYNC_N         =>     DAC_SYNC_N   ,
    DAC_DOUT           =>     DAC_DOUT     ,
                          
    CMOS_IO            =>     CMOS_IO      ,
    CMOS_IO_IN         =>     CMOS_IO_IN   ,
    
    DISCR_OUT_P        =>     DISCR_OUT_P  ,
    DISCR_OUT_N        =>     DISCR_OUT_N  ,
                              
    CL0_P              =>     CL0_P        ,
    CL0_N              =>     CL0_N        ,
                              
    LVDS_IO_P          =>     LVDS_IO_P    ,
    LVDS_IO_N          =>     LVDS_IO_N    ,
                              
    TIMEPPS_P          =>     TIMEPPS_P    ,
    TIMEPPS_N          =>     TIMEPPS_N    ,
                              
    TRGL1_P            =>     TRGL1_P      ,
    TRGL1_N            =>     TRGL1_N      ,
                              
    TRGCONF_P          =>     TRGCONF_P    ,
    TRGCONF_N          =>     TRGCONF_N    ,
                              
    TRGTYPE_P          =>     TRGTYPE_P    ,
    TRGTYPE_N          =>     TRGTYPE_N    ,
                              
    FPGA_SLOW_CTRL0    =>     FPGA_SLOW_CTRL0 ,
    FPGA_SLOW_CTRL1    =>     FPGA_SLOW_CTRL1 ,
    FPGA_SLOW_CTRL2    =>     FPGA_SLOW_CTRL2 ,
    FPGA_SLOW_CTRL3    =>     FPGA_SLOW_CTRL3 ,
                              
    IDW_IPADDR         =>     IDW_IPADDR   ,
    PROGRAM_B          =>     PROGRAM_B    ,
                               
    ETH0_P             =>     ETH0_P       ,
    ETH0_N             =>     ETH0_N       ,
    ETH1_P             =>     ETH1_P       ,
    ETH1_N             =>     ETH1_N       ,
    ETH2_P             =>     ETH2_P       ,
    ETH2_N             =>     ETH2_N       ,
    ETH3_P             =>     ETH3_P       ,
    ETH3_N             =>     ETH3_N       ,
                              
    SPARES3_P          =>     SPARES3_P    ,
    SPARES3_N          =>     SPARES3_N   
  
   );
   
  spi_slave_8bit_01_port_map: spi_slave_8bit_01
	  port map 
     (
       tx_data         => reg_data_out,
       tx_done         => open,
       rx_data         => reg_data_in,
       rx_data_val     => reg_wr_ena,
       rx_addr         => reg_addr,
       rx_addr_val     => open,
       rx_wr_nrd       => open,
       spi_sync        => FPGA_SLOW_CTRL2,
       spi_sclk        => FPGA_SLOW_CTRL0,
       spi_mosi        => FPGA_SLOW_CTRL1,
       spi_miso        => FPGA_SLOW_CTRL3,
       spi_miso_trst   => open
     );
     
 reg_array_port_map: reg_array 
  generic map (
               REG_WIDTH  =>  8, -- register width
               BLOCK_SIZE =>  7  -- register array size
               )
  port map
   (
    clk           => clk,
    reg_addr      => reg_addr,
    reg_wr_ena    => reg_wr_ena,
    reg_data_in   => reg_data_in,
    reg_data_out  => reg_data_out
    );

end architecture behavior;
  