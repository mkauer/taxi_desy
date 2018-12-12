-------------------------------------------------------
-- Design Name : l0_tb_v10_chip_07
-- File Name   : l0_tb_v10_chip_07_top.vhd
-- Device      : Spartan 6, XC6SLX9-2TQG144C
-- Function    : top level design of the L0_TB_V10 FPGA
--               trigger test design based on connected backplane
-- Coder       : K.-H. Sulanke, DESY, 2016-08-18
-------------------------------------------------------

-- 2014-02-14, DISCR_OUT_P/N(7) added
--  spares3    <= discr_out(7); -- dummy to keep the input termination
-- 2014-07-21, EXTCLK_P/N to lvds_io(1) added
-- 2015-09-03, changed to work together with des_3nn_008
-- added timepps check
-- 2015-09-07, added FPGA internal termination for several LVDS inputs (e.g. TRGL1_P/N) !!!
-- 2016-02-15, extclk -> lvds_io(0), ...
-- 2016-08-03, DTB-SPI bus control added (PPS delay, trigger input delay)


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all ;

library unisim ;
use unisim.vcomponents.all ;

entity l0_tb_v10_chip_07_top is
 generic (
            USE_LOCAL_CLOCK : boolean := true -- "false" -> diff. external clock is being used
            --N : integer := 8 ;   -- amount of serial data channel
           -- S	: integer := 8	 -- Parameter to set the serdes factor 1..8  
          ); 
  port
   (
     --RESETn          : in  std_logic ;  -- 2.5V CMOS, reset (low active) by charging 1uF with 10K     
     EXTCLK_P        : in  std_logic;   -- diff. clock, from trigger backplane, J11-C7
     EXTCLK_N        : in  std_logic;   -- diff. clock, from trigger backplane, J11-D7
 
     QOSC_OUT        : in  std_logic;   --2.5V CMOS, local 50 MHz TTL oscillator
     QOSC_ENA        : out std_logic;   --2.5V CMOS, oscillator enable
 
     RS232_RXD       : in  std_logic;   --2.5V CMOS, RS-232 communication
     RS232_TXD       : out std_logic;   --2.5V CMOS, RS-232 communication
      
     RS485_RXD       : in  std_logic;   --2.5V CMOS, RS-485 communication
     RS485_TXD       : out std_logic;   --2.5V CMOS, RS-485 communication
     RS485_TX_ENA    : out std_logic;   --2.5V CMOS, RS-485 communication
     ADM2483_PV      : out std_logic;   --2.5V CMOS, RS-485 transceiver-power-valid signal
   
     DAC_DIN         : out std_logic;   --2.5V CMOS, SPI interface to L0 trigger threshold dac
     DAC_SCLK        : out std_logic;   --2.5V CMOS 
     DAC_SYNC_N      : out std_logic;   --2.5V CMOS
     DAC_DOUT        : in  std_logic;   --2.5V CMOS 

     CMOS_IO         : out std_logic_vector (2 downto 0);  -- J4, 2x10 pin  header, inout,2.5V CMOS or LVDS, reserved, test pins
     CMOS_IO_IN      : in  std_logic_vector (7 downto 3);      -- 3 is low active RS485_enable,4..7 are being used as ADR_SW

     DISCR_OUT_P     : in  std_logic_vector (6 downto 0);      -- LVDS, from low level dicriminator
     DISCR_OUT_N     : in  std_logic_vector (6 downto 0);      -- 

     CL0_P           : out std_logic_vector (6 downto 0);   -- LVDS, from high level dicriminator
     CL0_N           : out std_logic_vector (6 downto 0);   -- 
  
     LVDS_IO_P       : out std_logic_vector(3 downto 0); -- J5-8,4,3,1, RJ45, LVDS bidir. test port
     LVDS_IO_N       : out std_logic_vector(3 downto 0); -- J5-7,5,6,2
   
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
 
     IDW_IPADDR      : out std_logic; -- 2.5V CMOS, bidir, 
     PROGRAM_B       : out std_logic; -- 2.5V CMOS, output, !!! low-active, prevent static low, otherwise
                                      --                        dig_trigger_v2 FPGA setup not possible !!! 
      
     ETH0_P          : out std_logic; -- LVDS, test output
     ETH0_N          : out std_logic; -- LVDS, test output
     ETH1_P          : out std_logic; -- LVDS, test output
     ETH1_N          : out std_logic; -- LVDS, test output
     ETH2_P          : out std_logic; -- LVDS, test output
     ETH2_N          : out std_logic; -- LVDS, test output
     ETH3_P          : out std_logic; -- LVDS, test output
     ETH3_N          : out std_logic; -- LVDS, test output
 
     ETH_LED1        : out std_logic;   --2.5V CMOS, part of the gigabit ethernet jack, located on the trigger backplane
     ETH_LED2        : out std_logic;   --2.5V CMOS, part of the gigabit ethernet jack, located on the trigger backplane 
 
     SPARES3_P       : out std_logic;  -- 2.5V CMOS inout / LVDS inout_P,
     SPARES3_N       : out std_logic  -- 2.5V CMOS inout / LVDS inout_N, 
   );
end entity;

architecture l0_tb_v10_chip_07_top_arch of l0_tb_v10_chip_07_top is
 
 type delay_array is array (0 to 7) of integer; 
  -- delays, calculated (EXCEL) from Post Map Static Timing report / 
  -- Data Sheet report, assuming 37ps/tap
  constant CL0_DELAY : delay_array := ( 21,22,3,1,6,5,1,0);

  component pll_100mhz is port
     (
      pll_reset   : IN  STD_LOGIC;
      pll_clkin   : IN  STD_LOGIC; -- clock input
      clk         : OUT STD_LOGIC; -- 100mhz, made from pll_clk2, global clock
      pll_locked  : OUT STD_LOGIC
   );
  end component pll_100mhz;
 
  component uart is port
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

component cmd_filter is
  port
   (
    clk                : in  std_logic;
    reset              : in  std_logic;
    rx_data_out        : in std_logic_vector (7 downto 0);  -- from UART
    rx_data_valid      : in std_logic;                      -- from UART, single clock length pulse
    cmd_data_rd        : in  std_logic;                     -- single clock length pulse
    cmd_data           : out std_logic_vector (7 downto 0); -- filtered data out
    cmd_avail          : out std_logic;                     -- at least one command available
    rx_empty           : out std_logic                     -- 
    );
end component cmd_filter;

component cmd_rd_exec is
  port(
    clk            : in  std_logic;
    reset          : in  std_logic;
    cmd_avail      : in  std_logic;
    rx_empty       : in  std_logic;                      -- command buffer status
    tx_data_sent   : in  std_logic;                      -- command acknowledge has been sent
    adr_sw         : in  std_logic_vector (3 downto 0);  -- board address switch
    
    cmd_data       : in  std_logic_vector (7 downto 0);  -- filtered ascii data (SP removed and converted to lower case) 
    cmd_data_rd    : out std_logic;                      -- single clock length pulse
  
    dac_chan       : out std_logic_vector (2 downto 0);  -- DAC channel
    dac_data       : out std_logic_vector (7 downto 0);  -- DAC value
    dac_load       : out std_logic;                      -- single pulse to initiate the DAC cycle
    dac_done       : in std_logic;                       -- DAC done
    
    spi_addr       : out std_logic_vector (6 downto 0); -- header, DTB register address
    spi_tx_data    : out std_logic_vector (7 downto 0); -- DTB register data to be sent
    spi_run        : out std_logic ;   -- initiate spi cycle
    spi_wr         : out std_logic ;   -- '0' if read cycle, header bit 27
    spi_done       : in  std_logic ;   -- spi cycle done
    
    cmd_used       : out std_logic_vector (3 downto 0);   -- last used command
    cmd_error      : out std_logic;                       -- ivalid command detected
    send_ena       : out std_logic;                       -- do send a message
    rs485_tx_ena   : out std_logic                        -- RS485 driver enable   
     );
end component cmd_rd_exec;

component DAC088S085 is
   port(
        reset          :in  std_logic; -- sets all channels to the zero value
        clk            :in  std_logic; -- 100 MHz
        dac_load       :in  std_logic; -- single pulse to initiate DAC load
        dac_chan       :in  std_logic_vector (2 downto 0); -- DAC channel 0..7 or 15 for all 8
        dac_data       :in  std_logic_vector (7 downto 0); -- parallel data
        dac_sync_n     :out std_logic; -- to be connected to DACs SYNCn input
        dac_din        :out std_logic; -- to be connected to DACs DIN input (serial)
        dac_sclk       :out std_logic; -- to be connected to DACs SCLK input
	      dac_done       :out std_logic  -- single pulse, dac ready
       );
end component DAC088S085;

component spi_master_8bit_01 is
  generic (CLOCK_DIVIDER : integer := 2); -- SPI_CLK = clk / (CLOCK_DIVIDER * 4)
  port
   (
     reset           : in  std_logic ;  -- synchronous or asynchrous reset for more than 2 clocks
     clk             : in  std_logic ;  -- 100 MHz clock
     tx_addr         : in  std_logic_vector (6 downto 0); -- header, destination address
     tx_data         : in  std_logic_vector (7 downto 0); -- data to be sent
     rx_data         : out std_logic_vector (7 downto 0); -- data received
     spi_run         : in  std_logic ;   -- initiate spi cycle
     spi_wr          : in  std_logic ;   -- '0' if read cycle, header bit 27
     spi_done        : out std_logic ;   -- spi cycle done
     spi_sync        : out  std_logic ;  -- backplane bus, low active sync signal
     spi_sclk        : out  std_logic ;  -- backplane bus, SPI clock
     spi_mosi        : out  std_logic ;  -- backplane bus, serial SPI tx-data
     spi_miso        : in   std_logic    -- backplane bus, serial SPI rx-data
   );
end component spi_master_8bit_01;


component send_msg is
  port
   (
    clk             : in  std_logic;
    send_ena        : in std_logic;                      -- '1' while sending
    adr_sw          : in std_logic_vector (3 downto 0);  -- board address switch
    cmd_used        : in std_logic_vector (3 downto 0);  -- pointer to start address of the message   
    tx_busy         : in std_logic; -- status signal from UART transmitter
    tx_ack          : in std_logic; -- single clock pulse from UART transmitter
    tx_data_in      : out std_logic_vector (7 downto 0); -- message bytes
    tx_data_valid   : out std_logic;                     -- single clock length pulse 
    tx_data_sent    : out std_logic;                     -- last message byte sent
    spi_rx_data     : in  std_logic_vector (7 downto 0) -- DTB register content via SPI read
   );
end component send_msg;

--  constant ETX       : std_logic_vector(7 downto 0) := X"03";


-- global signals

  signal reset         : std_logic := '0'; -- synchronous power up reset
  signal local_clk     : std_logic := '0'; -- by QOSC
  signal extclk        : std_logic := '0'; -- by DTB
  signal clkbuf_out    : std_logic := '0'; -- by external clock or local clock
 
  signal pll_clkin     : std_logic := '0'; -- pll input clock
  signal pll_locked    : std_logic := '0'; -- made by pll
  signal pll_reset     : std_logic := '1';
  signal clk           : std_logic := '0'; -- global clock made by pll (pll_clk2)
  
--  signal send_ena      : std_logic := '0';
--  signal rd_exec_ena   : std_logic := '0';
  
-- UART signals 

  signal tx_data_valid : std_logic;
  signal tx_data_in    : std_logic_vector (7 downto 0);
  signal tx_busy       : std_logic;
  signal tx_ack        : std_logic;
  signal tx_out        : std_logic;  -- connect to serial data output
  signal rs485_tx_en   : std_logic;  -- RS485 driver enable
  
  signal rx_in         : std_logic;  -- connect to serial data input
  signal rx_data_out   : std_logic_vector (7 downto 0);
  signal rx_data_valid   : std_logic;
  signal rx_data_out_msk : std_logic_vector (7 downto 0); -- bit7 set to '0'
 
 -- CMD_FILTER signals 
  signal cmd_data_rd    : std_logic;
  signal cmd_data       : std_logic_vector (7 downto 0);
  signal cmd_avail      : std_logic;
  signal rx_empty       : std_logic;

-- CMD_RD_EXEC signals
  signal dac_chan       : std_logic_vector (2 downto 0);
  signal dac_data       : std_logic_vector (7 downto 0);
  signal dac_load       : std_logic;
  signal spi_addr       : std_logic_vector (6 downto 0);
  signal spi_tx_data    : std_logic_vector (7 downto 0);
  signal spi_rx_data    : std_logic_vector (7 downto 0);
  signal spi_run        : std_logic; 
  signal spi_wr         : std_logic; 
  signal spi_done       : std_logic; 
  signal send_ena       : std_logic; 
  signal cmd_used       : std_logic_vector (3 downto 0); 

-- SPI signals (DTB register access)
  signal spi_sync        : std_logic;
  signal spi_sclk        : std_logic;
  signal spi_mosi        : std_logic;
  signal spi_miso        : std_logic; 

-- DAC DAC088S085 signals
  signal dac_sync_n_nd  : std_logic;
  signal dac_din_nd     : std_logic;
  signal dac_sclk_nd    : std_logic;
  signal dac_done       : std_logic;
  

-- SEND_MSG signals

  signal tx_data_sent   : std_logic;                      -- last message byte sent
  
  type  state_type is (IDLE, RD_EXEC, SEND);
  signal state : state_type := IDLE;

  --signal isd_fabricout   : std_logic_vector(7 downto 0) ; -- delayed LVDS discriminator outputs
  signal discr_out       : std_logic_vector(6 downto 0); 
  
  signal lvds_io         : std_logic_vector(3 downto 0) ; -- test pins
-- 
---- input / output lvds connections to the FE-board
--
  signal cl0_dld        : std_logic_vector(6 downto 0);

  signal eth_io         : std_logic_vector(3 downto 0);
  signal trgtype        : std_logic_vector(0 to 2);
  signal trgconf        : std_logic ;  
  signal timepps        : std_logic;
  signal spares3        : std_logic;
  signal busy_pipe      : std_logic_vector(15 downto 0);
  signal trgl1          : std_logic;


-- dummy counter ---------------------------------------------

  signal dummy_ct       : std_logic_vector(26 downto 0);
--  signal out_shrg       : std_logic_vector(8 downto 0);  -- to test input signals of the dig_trigger_v? board
--  signal in_rg          : std_logic_vector(8 downto 0);  -- read back of out_shrg via dig_trigger_v? board
  
-- iserdes2 signals -------------------------------------------

 --signal pdat_out          : std_logic_vector((N*S)-1 downto 0); -- parrallel data out
  
begin 
    
-- EXT_CLOCK: if (not USE_LOCAL_CLOCK) -- 100 mhz external LVDS clock
--  generate
   EXTCLK_ibufds_inst : IBUFDS --IBUFGDS
   generic map (IOSTANDARD => "LVDS_25")
   port map (
   O =>  extclk, -- Clock buffer output
   I =>  EXTCLK_P,    -- Diff_p clock buffer input
   IB => EXTCLK_N     -- Diff_n clock buffer input
   ); 
--  end generate EXT_CLOCK;

 LOCAL_CLOCK: if (USE_LOCAL_CLOCK) -- 100 MHz CMOS QOSC
  generate
  loc_clk_IBUFG_inst : IBUFG
   generic map (
   IOSTANDARD => "DEFAULT")
   port map (
   O => local_clk, -- Clock buffer output
   I => QOSC_OUT   -- Clock buffer input (connect directly to top-level port)
   );
  end generate LOCAL_CLOCK;
  
   QOSC_ENA  <= '1' when USE_LOCAL_CLOCK else '0';  -- generic used here 
   
   clkbuf_out <= local_clk;-- when USE_LOCAL_CLOCK else extclk; 
  
   bufio2_CLK_IN_inst : BUFIO2  generic map(
      DIVIDE         => 1,                    -- The DIVCLK divider divide-by value; default 1
      DIVIDE_BYPASS  => TRUE)             -- DIVCLK output sourced from Divider (FALSE) or from I input, by-passing Divider (TRUE); default TRUE
   port map (
      I              => clkbuf_out,             -- from FPGA clock input
      IOCLK          => open,                -- Output Clock
      DIVCLK         => pll_clkin,           -- Output Divided Clock
      SERDESSTROBE   => open) ;              -- Output SERDES strobe (Clock Enable)
 
 
  PLL_RESET_GEN: process (clkbuf_out)
      variable  pll_reset_ct : std_logic_vector (3 downto 0) := X"0"; -- used to generate the pll_reset
     begin
       if (rising_edge (clkbuf_out)) then
        if pll_reset_ct /= X"F" then
            pll_reset_ct := pll_reset_ct + 1;
            pll_reset <= '1';
        else  
            pll_reset <= '0';
        end if;
      end if; --(rising_edge (clkbuf_out))
     end process PLL_RESET_GEN; 

 pll_100mhz_port_map:
  pll_100mhz port map
   (
      pll_reset   => pll_reset,
      pll_clkin   => pll_clkin,
      clk         => clk,      -- global clock
      pll_locked  => pll_locked
   );
   
--  GLOBAL_RESET_GEN: process (clk, pll_locked)
--      variable  reset_ct : std_logic_vector (3 downto 0) := X"0"; -- used to generate the power up reset
--     begin
--       if pll_locked = '0' then
--        reset_ct    := X"0";
--        reset       <= '1'; 
--       elsif (rising_edge (clk)) then
--         if reset_ct /= X"F" then
--            reset_ct := reset_ct + 1;
--          else  
--            reset <= '0';
--         end if;
--       end if;
--     end process GLOBAL_RESET_GEN;
   
  GLOBAL_RESET_GEN: process (clk, pll_locked)
      variable  reset_ct : std_logic_vector (3 downto 0) := X"0"; -- used to generate the power up reset
     begin
       if pll_locked = '0' then
        reset_ct    := X"0";
       elsif (rising_edge (clk)) then
         if reset_ct /= X"F" then
            reset_ct := reset_ct + 1;
            reset    <= '1'; 
         else  
            reset <= '0';
         end if;
       end if;
     end process GLOBAL_RESET_GEN;
     
-- BUFG_inst : BUFG
--   port map (
--      O => reset, -- 1-bit output: Clock buffer output
--      I => reset_bufg  -- 1-bit input: Clock buffer input
--   );

     
 -- DAC control, signal mapping ---------------------------------------------------------------------

 uart_port_map:  
  uart port map
  (
    clk            => clk,
    reset          => reset,
    tx_data_valid  => tx_data_valid,
    tx_data_in     => tx_data_in,
    tx_busy        => tx_busy,
    tx_ack         => tx_ack,
    tx_out         => tx_out,
    rx_in          => rx_in,
    rx_data_out    => rx_data_out,
    rx_data_valid  => rx_data_valid
  );            

-- mask bit 7,  PC terminal,when set to 8 bit, showed bit7= (undefined) 1 or 0 here
-- rx_data_out   <= rx_data_out and X"7F"; 

    rx_data_out_msk  <= rx_data_out and X"7F";
  
 cmd_filter_port_map:
  cmd_filter port map
   (
    clk            => clk,
    reset          => reset,
    rx_data_out    => rx_data_out_msk,
    rx_data_valid  => rx_data_valid,
    cmd_data_rd    => cmd_data_rd,
    cmd_data       => cmd_data,
    cmd_avail      => cmd_avail,
    rx_empty       => rx_empty
   );

cmd_rd_exec_port_map: cmd_rd_exec port map
   (
    clk            => clk,
    reset          => reset,
    cmd_avail      => cmd_avail,
    rx_empty       => rx_empty,
    tx_data_sent   => tx_data_sent,
    adr_sw         => CMOS_IO_IN(7 downto 4),
    cmd_data       => cmd_data,
    cmd_data_rd    => cmd_data_rd, 
    dac_data       => dac_data,
    dac_chan       => dac_chan,
    dac_load       => dac_load,
    dac_done       => dac_done,
    spi_addr       => spi_addr,
    spi_tx_data    => spi_tx_data,
    spi_run        => spi_run,
    spi_wr         => spi_wr,
    spi_done       => spi_done,
    cmd_used       => cmd_used,
    cmd_error      => open,
    send_ena       => send_ena,
    rs485_tx_ena   => rs485_tx_en
   );
   
 spi_master_8bit_01_port_map: spi_master_8bit_01 port map
   (
     reset         => reset,
     clk           => clk,
     tx_addr       => spi_addr,
     tx_data       => spi_tx_data,
     rx_data       => spi_rx_data, 
     spi_run       => spi_run,
     spi_wr        => spi_wr,
     spi_done      => spi_done,
     spi_sync      => spi_sync,
     spi_sclk      => spi_sclk, 
     spi_mosi      => spi_mosi, 
     spi_miso      => spi_miso 
   );
  

 DAC088S085_port_map: DAC088S085 port map
   (
    clk            => clk,
    reset          => reset,
    dac_load       => dac_load,
    dac_chan       => dac_chan,
    dac_data       => dac_data,
    dac_sync_n     => dac_sync_n_nd, -- DAC_SYNC_n,
    dac_din        => dac_din_nd,  -- DAC_DIN,
    dac_sclk       => dac_sclk_nd, -- DAC_SCLK,
    dac_done       => dac_done
   );

  
 send_msg_port_map: send_msg port map
   (
    clk            => clk,
    send_ena       => send_ena,--not_reset
    adr_sw         => CMOS_IO_IN(7 downto 4),
    cmd_used       => cmd_used,
    
    tx_busy        => tx_busy,
    tx_ack         => tx_ack,
    tx_data_in     => tx_data_in,
    tx_data_valid  => tx_data_valid, 
    tx_data_sent   => tx_data_sent,
    spi_rx_data    => spi_rx_data
   );


-- Equations----------------------------------------------------------------------


-- enabling RS2323 or RS485 ------------------------------------------------------
 
     rx_in               <= (RS232_RXD and CMOS_IO_IN(3)) or (RS485_RXD and not CMOS_IO_IN(3)); -- 
     RS232_TXD           <= tx_out and CMOS_IO_IN(3) ; -- jumper set means '0'
    
     RS485_TXD           <= tx_out   and not CMOS_IO_IN(3);

     RS485_TX_ENA        <= rs485_tx_en and not CMOS_IO_IN(3);
--     RS485_TX_ENA        <= tx_busy and not CMOS_IO_IN(3);
     ADM2483_PV          <= not CMOS_IO_IN(3); -- ADM2483 (RS485 transceiver) power valid signal
   
    
--    dac_signals: process(clk)
--    begin
--      if (rising_edge(clk)) then
     DAC_SYNC_N          <=  dac_sync_n_nd; 
     DAC_SCLK            <=  dac_sclk_nd; 
     DAC_DIN             <=  dac_din_nd; 
--       end if;
--     end process dac_signals;
--     

 --    adr_sw(0 to 3)      <= CMOS_IO(7 downto 4); -- jumper set means '0'     
   
 --- FEB interface signals -------------------------------------------------    

  
    eth_io <= B"0000";
 
   ETH0_inst : OBUFDS generic map (IOSTANDARD => "LVDS_25")
      port map (O  => ETH0_P, OB => ETH0_N, I  => eth_io(0));  
   ETH1_inst : OBUFDS generic map (IOSTANDARD => "LVDS_25")
      port map (O  => ETH1_P, OB => ETH1_N, I  => eth_io(1));
   ETH2_inst : OBUFDS generic map (IOSTANDARD => "LVDS_25")
      port map (O  => ETH2_P, OB => ETH2_N, I  => eth_io(2)); 
   ETH3_inst : OBUFDS generic map (IOSTANDARD => "LVDS_25")
      port map (O  => ETH3_P, OB => ETH3_N, I  => eth_io(3));

   DISCR_OUT_gen : for i in 0 to 6 generate
     DISCR_OUT_inst : IBUFDS generic map (IOSTANDARD => "LVDS_25")
      port map (I  => DISCR_OUT_P(i), IB => DISCR_OUT_N(i), O  => discr_out(i));  
   end generate DISCR_OUT_gen;
   
   LVDS_IO_gen : for i in 0 to 3 generate
     LVDS_IO_inst : OBUFDS generic map (IOSTANDARD => "LVDS_25")
      port map (O  => LVDS_IO_P(i), OB => LVDS_IO_N(i), I  => lvds_io(i));  
   end generate LVDS_IO_gen;
   
   TRGL1_inst: IBUFDS generic map( IOSTANDARD => "LVDS_25")
      port map ( I => TRGL1_P, IB => TRGL1_N, O => trgl1); 
 
   TRGTYPE_gen: for i in 0 to 2 generate
    TRGTYPE_inst: IBUFDS generic map( IOSTANDARD => "LVDS_25")
      port map ( I => TRGTYPE_P(i), IB => TRGTYPE_N(i), O => trgtype(i));
    end generate TRGTYPE_gen;

   TRGCONF_inst: IBUFDS generic map( IOSTANDARD => "LVDS_25")
      port map ( I => TRGCONF_P, IB => TRGCONF_N, O => trgconf); 
 
   TIMEPPS_inst: IBUFDS generic map( IOSTANDARD => "LVDS_25")
      port map ( I => TIMEPPS_P, IB => TIMEPPS_N, O => timepps); 
      

-- testing ---------------------------------------------------------------

-- DISCR_to_LVDS_IO: for i in 0 to 3 generate
--   begin
--    
--   lvds_io_ODDR2_inst : ODDR2 generic map(
--      DDR_ALIGNMENT => "NONE", -- Sets output alignment to "NONE", "C0", "C1"
--      INIT => '0', -- Sets initial state of the Q output to '0' or '1'
--      SRTYPE => "ASYNC") -- Specifies "SYNC" or "ASYNC" set/reset
--   port map (
--      Q => lvds_io(i), -- 1-bit output data
--      C0 => pll_clk3,--io_clk0, -- 1-bit clock input
--      C1 => pll_clk4,--io_clk1, -- 1-bit clock input
--      CE => '1', -- 1-bit clock enable input
--      D0 => discr_out(i), -- 1-bit data input (associated with C0)
--      D1 => discr_out(i), -- 1-bit data input (associated with C1)
--      R => '0', -- 1-bit reset input
--      S => '0' -- 1-bit set input
--      );
--    
-- end generate DISCR_to_LVDS_IO;

-- gclk output for test purposes

--   gclk_out_ODDR2_inst : ODDR2 generic map(
--      DDR_ALIGNMENT => "NONE", -- Sets output alignment to "NONE", "C0", "C1"
--      INIT => '0', -- Sets initial state of the Q output to '0' or '1'
--      SRTYPE => "ASYNC") -- Specifies "SYNC" or "ASYNC" set/reset
--   port map (
--      Q => lvds_io(3), -- 1-bit output data
--      C0 => pll_clk3,--io_clk0, -- 1-bit clock input
--      C1 => pll_clk4,--io_clk1, -- 1-bit clock input
--      CE => '1', -- 1-bit clock enable input
--      D0 => '1',--discr_out(i), -- 1-bit data input (associated with C0)
--      D1 => '0',--discr_out(i), -- 1-bit data input (associated with C1)
--      R => '0', -- 1-bit reset input
--      S => '0' -- 1-bit set input
--      );


--- dummy equations ------------------------------------------------------    


 CL0_OUT_gen: for i in 0 to 6  generate -- bank2
    begin 

-- setup a fixed serial data ouput delay
    CL0_ODELAY_gen: IODELAY2
      generic map (
        DATA_RATE           => "SDR",
        ODELAY_VALUE        => CL0_DELAY(i), --37ps/tap
        COUNTER_WRAPAROUND  => "STAY_AT_LIMIT",
        DELAY_SRC           => "ODATAIN",
        SERDES_MODE         => "NONE",
        SIM_TAPDELAY_VALUE  => 75)
      port map (
        -- required datapath
        T                   => '0',
        DOUT                => cl0_dld(i),
        ODATAIN             => discr_out(i),
        IDATAIN             => '0',
        TOUT                => open,
        DATAOUT             => open,
        DATAOUT2            => open,
        IOCLK0              => '0',                 -- No calibration needed
        IOCLK1              => '0',                 -- No calibration needed
        CLK                 => '0',
        CAL                 => '0',
        INC                 => '0',
        CE                  => '0',
        BUSY                => open,
        RST                 => '0');

    CL0_inst : OBUFDS
      generic map (IOSTANDARD => "LVDS_25")
      port map (  O  => CL0_P(i), OB => CL0_N(i), I  => cl0_dld(i));
        
 end generate CL0_OUT_gen;



  FEB_BUSY_inst : OBUFDS generic map (IOSTANDARD => "LVDS_25")
      port map (O  => SPARES3_P, OB =>SPARES3_N, I  => spares3);
      
  IDW_IPADDR <= DAC_DOUT; -- dummy


 
  
  FEB_BUSY_gen: process(clk) -- dummy
       variable ct : std_logic_vector (15 downto 0) := X"0000";
     begin
      if rising_edge(clk) then 
       ct := ct + '1';
       if    ct = X"000f" then busy_pipe <= X"000f";
       elsif ct = X"00ff" then busy_pipe <= X"00ff";
       elsif ct = X"0fff" then busy_pipe <= X"0fff";
       elsif ct = X"ffff" then busy_pipe <= X"ffff"; ct := X"0000";
       else
        busy_pipe(0)           <= '0';
        busy_pipe(15 downto 1) <= busy_pipe(14 downto 0);
        spares3 <= busy_pipe(15);    -- used as FEB-BUSY signal
       end if; -- ct = X"000f" ..   
      end if; --rising_edge(clk)
     end process FEB_BUSY_gen;      
       

 
  
   process(clk) -- dummy
     begin
      if rising_edge(clk) then 
       if (timepps='1') and (trgconf='1') and (trgtype=B"111") then
         ETH_LED1         <= '1';
         ETH_LED2         <= '1';
       else
        ETH_LED1         <= '0'; 
        ETH_LED2         <= '0'; 
       end if;
      end if;
   end process;      
       
   FPGA_SLOW_CTRL2 <= spi_sync;
   FPGA_SLOW_CTRL0 <= spi_sclk;
   FPGA_SLOW_CTRL1 <= spi_mosi;
   spi_miso        <= FPGA_SLOW_CTRL3;
   
   -- temporary test signals --------------------------------------------------------------------
     
   lvds_io(0)          <= cmd_avail;--spi_miso; --clk;   --J5-1,2,  "not" to fix the part lib bug
   lvds_io(1)          <= rx_empty;--timepps; --J5-3,6,
   lvds_io(2)          <= rx_data_valid;--trgl1;  --J5-4,5, isd_fabricout(2 downto 0);
   lvds_io(3)          <= cmd_data_rd;--spares3;  --J5-8,7,
     
   CMOS_IO(0)          <= tx_data_sent;--spi_sync; --tx_data_sent;--tx_busy;--pdat_out(0);--isd_fabricout(7);
   CMOS_IO(1)          <= tx_out;--spi_sclk; --tx_out;--pdat_out(8);--isd_fabricout(6);
   CMOS_IO(2)          <= send_ena;--spi_mosi; --send_ena;--pdat_out(16);--isd_fabricout(5);
   --CMOS_IO(3)          <= pll_locked;--isd_fabricout(4);

   PROGRAM_B           <= '1'; --(!!!)
 
 end architecture l0_tb_v10_chip_07_top_arch;
 