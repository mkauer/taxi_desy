-------------------------------------------------------
-- Design Name      : uvl_mb_pinout_top 
-- File Name        : uvl_mb_pinout_top.vhd
-- Device           : Spartan 6, XC6SLX16CSG324-3
-- Migration Device : Spartan 6, XC6SLX45CSG324-3
-- Function         : UV-logger mainboard FPGA, top level design,
--                    dummy design to verify the initial pinout
-- Coder            : K.-H. Sulanke, DESY, 2018-07-06
-------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all ;

library unisim ;
use unisim.vcomponents.all ;

entity uvl_mb_pinout_top is generic 
    (
      S               : integer := 8 ;            -- Parameter to set the serdes factor 1..8
      PLL_DIV         : integer := 1 ;            -- Parameter to set division for PLL 
      PLL_MULT        : integer := 40 ;           -- Parameter to set multiplier for PLL (7 for video links, 2 for DDR etc)
      CLKIN_PERIOD    : real    := 40.0          -- clock period (ns) of input clock on clkin_p
     ) ;
port(    

      -- ************************ Bank #0, VCCO = 1.8V ****************************************************

      -- Stamp9G45, 1.8V signals
      EBI1_ADDR    : in std_logic_vector(15 downto 0);    -- memory bus address signals
      EBI1_D       : inout std_logic_vector(15 downto 0); -- memory bus data signals
      EBI1_NWE     : in std_logic;  -- dedicated clock pin, EBI1_NWE/NWR0/CFWE, low active write strobe 
      EBI1_NCS2    : in std_logic;  -- dedicated clock pin, PC13/NCS2, low active Chip Select 2
      EBI1_NRD     : in std_logic;  -- dedicated clock pin, EBI1_NRD/CFOE, low active read strobe
      EBI1_NWAIT   : out std_logic; -- PC15/NWAIT, low active
      --PC1_ARM_IRQ0 : out std_logic; --   bank #3     

      -- ************************ Bank #1, VCCO = 2.5V  ****************************************************
     
      COM_ADC_D     : in  std_logic_vector(13 downto 0);    -- communication ADC output
      COM_ADC_OR    : in  std_logic;  -- out of range signal
      COM_ADC_CSBn  : out std_logic; --
      COM_ADC_SCLK  : out std_logic; --
      COM_ADC_SDIO  : out std_logic; -- is inout
      COM_ADC_DCO   : in  std_logic; -- dedicated clock pin, data clock
      nLED_ENA      : out std_logic; --
      nLED_RED      : out std_logic; --
      nLED_GREEN    : out std_logic; --
      
      CFG_STAMPn    : out std_logic; -- when '0', FPGA (passive serial) configuration by Stamp possible
      
      DRS4_DENABLE  : out std_logic;  -- Domino Enable Input. A low-to-high transition starts the Domino
                                      -- Wave. Setting this input low stops the Domino Wave
      DRS4_DWRITE   : out std_logic;  -- Connects the Domino Wave Circuit to the Sampling Cells to enable sampling
      DRS4_WSRIN    : out std_logic;  -- 
      DRS4_WSROUT   : in  std_logic; -- Double function: Write Shift Register  
                                     -- Output if DWRITE=1, Read Shift Register Output if DWRITE=0
                                    
      DRS4_DTAP     : in  std_logic; -- dedicated clock pin, Domino Tap Signal Output toggling on each domino revolution
      DRS4_PLLLCK   : in  std_logic; -- PLL Lock Indicator Output
      DRS4_RESETn   : out std_logic; -- external Reset, leave open when using internal ..
      DRS4_A        : out std_logic_vector(3 downto 0); -- shared address bits
      DRS4_SROUT    : in  std_logic; -- Multiplexed Shift Register Output      
      DRS4_SRIN     : out std_logic;  -- Shared Shift Register Input   
      DRS4_SRCLK    : out std_logic;  -- Multiplexed Shift Register Clock Input      
      DRS4_RSLOAD   : out std_logic;  -- Read Shift Register Load Input      

 
      -- ************************ Bank #2, VCCO = 2.5V  ****************************************************

      COM_ADC_CLK_P : out std_logic;  -- LVDS, comm. ADC  clock     
      COM_ADC_CLK_N : out std_logic;  -- 

      ADC_OUTAP     : in  std_logic_vector(1 to 8); -- LVDS, oserdes data outputs
      ADC_OUTAN     : in  std_logic_vector(1 to 8); -- DRS4 channel counting starts with '0' !!!
                
      ADC_FRAP      : in  std_logic; -- Frame Start Outputs for Channels 1, 4, 5 and 8
      ADC_FRAN      : in  std_logic;
      ADC_FRBP      : in  std_logic; -- Frame Start Outputs for Channels 2, 3, 6 and 7
      ADC_FRBN      : in  std_logic;
      ADC_DCOAP     : in  std_logic; -- Data Clock Outputs for Channels 1, 4, 5 and 8
      ADC_DCOAN     : in  std_logic;     
      ADC_DCOBP     : in  std_logic; -- Data Clock Outputs for Channels 2, 3, 6 and 7
      ADC_DCOBN     : in  std_logic; 
      ADC_ENCp      : out std_logic; -- LVDS, conversion clock, conversion starts at rising edge    
      ADC_ENCn      : out std_logic;
      ADC_PAR_SERn  : out std_logic; -- 
      ADC_SDI       : out std_logic;  -- serial interface data input 
      ADC_SCK       : out std_logic;  -- serial interface clock input     
      ADC_CSAn      : out std_logic; -- serial interface chip select, channels 1, 4, 5 and 8
      ADC_CSBn      : out std_logic; -- serial interface chip select, channels 2, 3, 6 and 7
  
      DISCR_OUTp  : in std_logic_vector(0 to 5); -- LVDS, discriminator outputs
      DISCR_OUTn  : in std_logic_vector(0 to 5);
  
      DRS4_REFCLKp : out std_logic;  -- Reference Clock Input LVDS (+)    
      DRS4_REFCLKn : out std_logic;  -- Reference Clock Input LVDS (-)  
      
      FLB_TRIG1_P : out std_logic;  -- flasher board, blue LED, trigger LVDS     
      FLB_TRIG1_N : out std_logic;   
      FLB_TRIG2_P : out std_logic;  -- flasher board, ultra violett LED, trigger LVDS     
      FLB_TRIG2_N : out std_logic;   

      -- ************************ Bank #3, VCCO = 3.3V  ****************************************************

      QOSC_OUT      : in std_logic ;   -- 3.3V CMOS, 25MHz by local CMOS clock osc.
 
      COM_DAC_DB    : out std_logic_vector(11 downto 0);    -- connected to communication DAC
      COM_DAC_CLOCK : out std_logic;  -- 
 
      
      I2C_SCL       : out   std_logic_vector(0 to 4);  -- connected to J4..8, the power supply board and local sensors
      I2C_DATA      : inout std_logic_vector(0 to 4);  -- 
      DAC_SCL       : out   std_logic;  -- connected to two DACs, discriminator thresholds and ananlog + DRS4 tuning
      DAC_SDA       : inout std_logic;  -- 
      FLB_I2C_SCL   : out   std_logic;  -- connected to J26 (flasher board)
      FLB_I2C_DATA  : inout std_logic;  --      
 
      PC1_ARM_IRQ0  : out std_logic; -- stamp PIO port PC1, used as edge (both) triggered interrupt signal
      STAMP_DRXD    : in std_logic;  -- stamp debug uart 
      STAMP_DTXD    : out std_logic; --     
      STAMP_RXD1    : in std_logic;  -- PB5, stamp uart
      STAMP_TXD1    : out std_logic; -- PB4,

      HCM_DRDY      : in std_logic;  -- compass sensor status
       
      TEST_IO       : out std_logic_vector(3 downto 0) -- 3.3V CMOS / LVDS bidir. test port, p/n=1/0 or 3/2           
     );
end uvl_mb_pinout_top ;

architecture arch_uvl_mb_pinout_top of uvl_mb_pinout_top is
 
  constant CTRL_ADDR  : std_logic_vector := X"1234"; 
  constant ADC_ADDR   : std_logic_vector := X"5678"; 
  constant DISCR_ADDR : std_logic_vector := X"9abc"; 
  constant STAT_ADDR  : std_logic_vector := X"def0"; 
  
  signal reset       : std_logic;
  signal reset_ct    : std_logic_vector(3 downto 0);
  signal qosc_clk    : std_logic;
  
  -- plls and clocks
  signal pll_rst         : std_logic;
  signal pll_clkin       : std_logic;    -- primary clock input
  signal pll_clkfbin     : std_logic;    -- 
  signal pll_clkfbout    : std_logic;    -- 
  
  signal pll_clkout0     : std_logic;    -- pll output,
  signal pll_clkout2     : std_logic;    -- pll output,
  signal pll_locked      : std_logic;    -- active high pll lock signal

  signal gclk2           : std_logic;  -- made from pll_clkout2
  
-- bufpll
  signal iserdes_stb2    : std_logic;
  signal iserdes_ioclk2  : std_logic; -- index according to the bank
  
  -- ADC, 8 channel, LTM9007-14
  signal adc_enc     : std_logic;  
  signal adc_outa    : std_logic_vector(1 to 8);  
  signal adc_fra     : std_logic; 
  signal adc_frb     : std_logic;
  signal adc_dcoa    : std_logic; 
  signal adc_dcob    : std_logic;

  signal drs4_refclk : std_logic; 
 
  signal discr_out   : std_logic_vector(0 to 7) ; -- lvds inbuf outputs 
 
  -- tristate signals
  signal i2c_data_in     : std_logic_vector(0 to 4); -- IO_BUF_O, data received
  signal i2c_data_out    : std_logic_vector(0 to 4); -- IO_BUF_I, data to be sent
  signal i2c_data_trst   : std_logic_vector(0 to 4); -- IO_BUF_T, io buffer tristate

  signal dac_sda_in      : std_logic;  
  signal dac_sda_out     : std_logic;  
  signal dac_sda_trst    : std_logic;  

  signal flb_i2c_data_in     : std_logic;  
  signal flb_i2c_data_out    : std_logic;  
  signal flb_i2c_data_trst   : std_logic;  
  
  signal ebi1_d_in    : std_logic_vector(15 downto 0); -- IO_BUF_O, data from memory
  signal ebi1_d_out   : std_logic_vector(15 downto 0); -- IO_BUF_I, data to memory
  signal ebi1_d_trst  : std_logic;                     -- IO_BUF_T, io buffer tristate
 
  signal reg_addr     : std_logic_vector(15 downto 0); -- address latch
  
  -- status and control registers
  
  signal ctrl_reg    : std_logic_vector(15 downto 0); -- global control register
  signal stat_reg    : std_logic_vector(13 downto 0); -- global control register
  signal adc_reg     : std_logic_vector(7 downto 0); 
  signal discr_reg   : std_logic_vector(7 downto 0); 
  
    
  type   iserdes_pdat_8x8 is array (1 to 8) of std_logic_vector(0 to 7);
  type   iserdes_pdat_6x8 is array (0 to 5) of std_logic_vector(0 to 7);
  
  signal adc_pdat   : iserdes_pdat_8x8;
  signal discr_pdat : iserdes_pdat_6x8;
  
  signal com_adc_clk : std_logic;
  signal flb_trig1   : std_logic;
  signal flb_trig2   : std_logic;
  
    
  component iserdes_in_del is  
   generic (
            S           : integer                      := 8;	 -- Parameter to set the serdes factor 1..8
            INIT_DELAY  : std_logic_vector(4 downto 0) := B"0_0001"
           );        -- clock period (ns) of input clock on clkin_p
   port (
        reset 		            :  in std_logic ;   -- reset (active high)
        clk                   :  in std_logic ;   -- global clock input
        del_data              :  in std_logic_vector (7 downto 0);  -- delay value, 4..0 => ps, 7..5 => ns
        del_load              :  in std_logic;   -- to initiate the DELAY cycle, single pulse, synchronous state machine reset 
        del_busy              :  out std_logic;  -- delay status
        sdat_in_p           	:  in std_logic;   -- lvds serial data inputs
        sdat_in_n	            :  in std_logic;   -- lvds serial data inputs
        iserdes_ioclk         :  in std_logic ;   -- high speed i/o clock
        iserdes_stb           :  in std_logic ;   --       
        pdat_out              :  out std_logic_vector (7 downto 0)  -- synchronized (clk) iserdes par. data output
        );
  end component iserdes_in_del ;
  
begin

   ADC_FRA_inst : IBUFDS
      port map (
       O  => adc_fra,        -- buffer output
       I  => ADC_FRAP, -- buffer input (connect directly to top-level port)
       IB => ADC_FRAN  -- buffer input (connect directly to top-level port)
       );

   ADC_FRB_inst : IBUFDS
      port map (
       O  => adc_frb,        -- buffer output
       I  => ADC_FRBP, -- buffer input (connect directly to top-level port)
       IB => ADC_FRBN  -- buffer input (connect directly to top-level port)
       );

   ADC_DCOA_inst : IBUFDS
      port map (
       O  => adc_dcoa,        -- buffer output
       I  => ADC_DCOAP, -- buffer input (connect directly to top-level port)
       IB => ADC_DCOAN  -- buffer input (connect directly to top-level port)
       );

  ADC_DCOB_inst : IBUFDS
      port map (
       O  => adc_dcob,        -- buffer output
       I  => ADC_DCOBP, -- buffer input (connect directly to top-level port)
       IB => ADC_DCOBN  -- buffer input (connect directly to top-level port)
       ); 
   
  ADC_ENC_inst : OBUFDS
      generic map (IOSTANDARD => "LVDS_33")
       port map (  O  => ADC_ENCp, OB => ADC_ENCn, I  => adc_enc);
 

  ADC_OUTA_inbufs: for i in 1 to 8 generate 
    ADC_OUTA_inst : IBUFDS
       port map (
       O  => adc_outa(i),        -- buffer output
       I  => ADC_OUTAP(i), -- buffer input (connect directly to top-level port)
       IB => ADC_OUTAN(i)  -- buffer input (connect directly to top-level port)
       );
     end generate ADC_OUTA_inbufs;

   COM_ADC_CLK_inst : OBUFDS
       port map (  O  => COM_ADC_CLK_P, OB => COM_ADC_CLK_N, I  => com_adc_clk);   

  FLB_TRIG1_inst : OBUFDS
       port map (  O  => FLB_TRIG1_P, OB => FLB_TRIG1_N, I  => flb_trig1);  
  FLB_TRIG2_inst : OBUFDS
       port map (  O  => FLB_TRIG2_P, OB => FLB_TRIG2_N, I  => flb_trig2);  

  DISCR_OUT_inbufs: for i in 0 to 5 generate 
    DISCR_OUT_inst : IBUFDS
     port map (
       O  => discr_out(i),        -- buffer output
       I  => DISCR_OUTp(i), -- buffer input (connect directly to top-level port)
       IB => DISCR_OUTn(i)  -- buffer input (connect directly to top-level port)
       );
     end generate DISCR_OUT_inbufs;
 
   DRS4_REFCLK_inst : OBUFDS
       port map (  O  => DRS4_REFCLKp, OB => DRS4_REFCLKn, I  => drs4_refclk);
 
   LOCAL_CLK_inst:  IBUFG generic map ( IOSTANDARD => "DEFAULT")
    port map (I => QOSC_OUT, O => qosc_clk);
   
   BUFIO2_CLK_IN_inst : BUFIO2  generic map(
      DIVIDE			  => 1,         		-- The DIVCLK divider divide-by value; default 1
      DIVIDE_BYPASS	=> TRUE)    			-- DIVCLK output sourced from Divider (FALSE) or from I input, by-passing Divider (TRUE); default TRUE
   port map (
      I				      => qosc_clk,      -- from FPGA clock input
      IOCLK			    => open,      	  -- Output Clock
      DIVCLK			  => pll_clkin,     -- Output Divided Clock
      SERDESSTROBE	=> open) ;       	-- Output SERDES strobe (Clock Enable)

   PLL_RESET_GEN: process(qosc_clk) -- 25 MHz
     variable pll_reset_ct : integer range 0 to 65535 := 0;
   begin
     if rising_edge (qosc_clk) then
      if (pll_reset_ct /= 65535) then
        pll_reset_ct := pll_reset_ct + 1;
        if (pll_reset_ct = 65500) then 
         pll_rst <= '1';
        else 
         pll_rst <= '0'; 
        end if; -- (pll_reset_ct = 65500) 
      end if; --(pll_reset_ct /= 65535) 
     end if; -- rising_edge (gclkb_dld)
   end process PLL_RESET_GEN; 
  
   PLL_BASE_inst : PLL_BASE
   generic map (
   BANDWIDTH          => "OPTIMIZED", -- "HIGH", "LOW" or "OPTIMIZED" !!! "LOW" gives 2x more jitter !!!
   CLKFBOUT_MULT      => PLL_MULT, -- 50Mhz->1Ghz (max.), multiplication factor for all output clocks
   CLK_FEEDBACK       => "CLKFBOUT",--"CLKOUT0", -- needed (!) to phase align with the input clock was "CLKFBOUT" before w. no pps
   CLKFBOUT_PHASE     =>  0.0, -- Phase shift (degrees) of all output clocks
   CLKIN_PERIOD       => CLKIN_PERIOD, -- Clock period (ns) of input clock on CLKIN
   CLKOUT0_DIVIDE     =>   1, -- Division factor for CLKOUT0 (1 to 128), used as fast I/O clock 
   CLKOUT0_DUTY_CYCLE => 0.5, -- Duty cycle for CLKOUT0 (0.01 to 0.99)
   CLKOUT0_PHASE      => 0.0, -- Phase shift (degrees) for CLKOUT0 (0.0 to 360.0)
   CLKOUT1_DIVIDE     =>   1,   -- Division factor for CLKOUT1 (1 to 128), used as fast I/O clock
   CLKOUT1_DUTY_CYCLE => 0.5, -- Duty cycle for CLKOUT1 (0.01 to 0.99)
   CLKOUT1_PHASE      => 0.0, -- Phase shift (degrees) for CLKOUT1 (0.0 to 360.0)
   CLKOUT2_DIVIDE     =>   S,   -- Division factor for CLKOUT2 (1 to 128)
   CLKOUT2_DUTY_CYCLE => 0.5, -- Duty cycle for CLKOUT2 (0.01 to 0.99)
   CLKOUT2_PHASE      => 0.0, -- Phase shift (degrees) for CLKOUT2 (0.0 to 360.0)
   CLKOUT3_DIVIDE     =>  S, -- Division factor for CLKOUT3 (1 to 128)
   CLKOUT3_DUTY_CYCLE => 0.5, -- Duty cycle for CLKOUT3 (0.01 to 0.99)
   CLKOUT3_PHASE      => 0.0, -- Phase shift (degrees) for CLKOUT3 (0.0 to 360.0)
   CLKOUT4_DIVIDE     =>   S, -- Division factor for CLKOUT4 (1 to 128)
   CLKOUT4_DUTY_CYCLE => 0.5, -- Duty cycle for CLKOUT4 (0.01 to 0.99)
   CLKOUT4_PHASE      => 180.0, -- Phase shift (degrees) for CLKOUT4 (0.0 to 360.0)
   CLKOUT5_DIVIDE     =>  S, -- Division factor for CLKOUT5 (1 to 128)
   CLKOUT5_DUTY_CYCLE => 0.5, -- Duty cycle for CLKOUT5 (0.01 to 0.99)
   CLKOUT5_PHASE      => 90.0,-- 
   COMPENSATION       => "INTERNAL", -- "SYSTEM_SYNCHRONOUS",
                         -- "SOURCE_SYNCHRONOUS", "INTERNAL",
                         -- "EXTERNAL", "DCM2PLL", "PLL2DCM"
   DIVCLK_DIVIDE      => PLL_DIV,--1,--5,--PLL_DIV, -- Division factor for all clocks (1 to 52)
   REF_JITTER         => 0.1) -- Input reference jitter (0.000 to 0.999 UI%)
   port map (
   CLKFBOUT           => pll_clkfbout, -- General output feedback signal
   CLKOUT0            => pll_clkout0, -- One of six general clock output signals
   CLKOUT1            => open, -- One of six general clock output signals
   CLKOUT2            => pll_clkout2, -- One of six general clock output signals
   CLKOUT3            => open, -- One of six general clock output signals
   CLKOUT4            => open, -- One of six general clock output signals+
   CLKOUT5            => open,--pll_clkout5, -- One of six general clock output signals
   LOCKED             => pll_locked, -- Active high PLL lock output signal
   CLKFBIN            => pll_clkfbout, -- Clock feedback input
   CLKIN              => pll_clkin, -- dcm_clkfx,--,Clock input
   RST                => pll_rst --open -- Asynchronous PLL reset
   );  


  SYNC_RESET: process ( pll_locked, gclk2)
    begin                                  -- do power on reset, just once !
     if rising_edge(gclk2) then   
      if (pll_locked ='1') then
       if reset_ct /= B"1111" then
        reset_ct <= reset_ct + '1';
       end if;
       if (reset_ct = B"1110") then
        reset <= '1';
       else
        reset <= '0';
       end if;
      end if; -- (pll_locked ='1')
     end if; -- rising_edge(gclk2)
   end process SYNC_RESET;      
 
  GCKL2_inst : BUFG
  port map (
    I => pll_clkout2, -- 1-bit Clock buffer input
    O => gclk2        -- 1-bit Clock buffer output
   );


  BUFPLL_bank1_iserdes_inst : BUFPLL generic map(
         DIVIDE		   => S)  -- PLLIN0 divide-by value to produce rx_serdesstrobe (1 to 8); default 1
      port map (
         PLLIN		    => pll_clkout0,   -- input, PLL clock by PLL_ADV
         GCLK			    => gclk2, 		    -- input, Global Clock input
         LOCKED		    => pll_locked,    -- input, Clock0 locked input
         IOCLK		    => iserdes_ioclk2, -- output, PLL Clock
         LOCK			    => open,          -- output, BUFPLL Clock and strobe locked
         serdesstrobe => iserdes_stb2) ; -- output, SERDES strobe


 ADC_DEL_ISERDES_bank2 :  for i in 1 to 8  generate 
  ADC_ISERDES_inst: iserdes_in_del
   generic map (
                S	         => 8, 	-- Parameter to set the serdes factor 1..8
                INIT_DELAY => B"0_1111" -- global input delay 
                ) 
   port map
      (
        reset 		            => reset,   -- reset (active high)
        clk                   => gclk2,   -- gclk2, global clock input
        del_data              => ctrl_reg(7 downto 0),  -- delay value
        del_load              => ctrl_reg(8),   -- to initiate the DELAY cycle, single pulse  
        del_busy              => stat_reg(i-1),  -- delay done, single pulse
        sdat_in_p           	=> ADC_OUTAP(i),   -- lvds serial data inputs
        sdat_in_n	            => ADC_OUTAN(i),   -- lvds serial data inputs
        iserdes_ioclk         => iserdes_ioclk2,   -- serdes_ioclk1, high speed i/o clock
        iserdes_stb           => iserdes_stb2,   -- iserdes_stb1,       
        pdat_out              => adc_pdat(i)   -- synchronized (clk) iserdes par. data output
       );
  end generate ADC_DEL_ISERDES_bank2 ;

 DISCR_DEL_ISERDES_bank2 :  for i in 0 to 5  generate 
  DISCR_ISERDES_inst: iserdes_in_del
   generic map (
                S	         => 8, 	 -- Parameter to set the serdes factor 1..8
                INIT_DELAY => B"1_1110"-- global cl0 input delay 
                ) 
   port map
      (
        reset 		            => reset,   -- reset (active high)
        clk                   => gclk2,   -- gclk2, global clock input
        del_data              => ctrl_reg(7 downto 0),  -- delay value
        del_load              => ctrl_reg(9),   -- to initiate the DELAY cycle, single pulse  
        del_busy              => stat_reg(i+8),  -- delay done, single pulse
        sdat_in_p           	=> DISCR_OUTp(i),   -- lvds serial data inputs
        sdat_in_n	            => DISCR_OUTn(i),   -- lvds serial data inputs
        iserdes_ioclk         => iserdes_ioclk2,   -- serdes_ioclk1, high speed i/o clock
        iserdes_stb           => iserdes_stb2,   -- iserdes_stb1,       
        pdat_out              => discr_pdat(i)   -- synchronized (clk) iserdes par. data output
       );
  end generate DISCR_DEL_ISERDES_bank2 ;
  
  
  

  DUMMY_SUM: process(gclk2)
   begin
    if rising_edge(gclk2) then
     adc_reg   <= adc_pdat(1) or adc_pdat(2) or adc_pdat(3) or adc_pdat(4) or adc_pdat(5) or adc_pdat(6) or adc_pdat(7) or adc_pdat(8);
     discr_reg <= discr_pdat(0) or discr_pdat(1) or discr_pdat(2) or discr_pdat(3) or discr_pdat(4) or discr_pdat(5);
    end if;
   end process DUMMY_SUM;    


 -- instantiate bidir pins, in / out naming according to the FPGA-core view !!!
 
  I2C_DATA_bufs :  for i in 0 to 4  generate 
   I2C_DATA_IOBUF_inst : IOBUF
    port map (
    O =>  i2c_data_in(i),  -- Buffer output
    IO => I2C_DATA(i),     -- Buffer inout port (connect directly to top-level port)
    I =>  i2c_data_out(i), -- Buffer input
    T =>  i2c_data_trst(i) -- 3-state enable input, high=input, low=output
    );
   end generate  I2C_DATA_bufs;

   DAC_SDA_IOBUF_inst : IOBUF
    port map (
    O =>  dac_sda_in,  -- Buffer output
    IO => DAC_SDA,     -- Buffer inout port (connect directly to top-level port)
    I =>  dac_sda_out, -- Buffer input
    T =>  dac_sda_trst -- 3-state enable input, high=input, low=output
    );   

  FLB_I2C_DATA_IOBUF_inst : IOBUF
    port map (
    O =>  flb_i2c_data_in,  -- Buffer output
    IO => FLB_I2C_DATA,     -- Buffer inout port (connect directly to top-level port)
    I =>  flb_i2c_data_out, -- Buffer input
    T =>  flb_i2c_data_trst -- 3-state enable input, high=input, low=output
    );     
   
  EBI1_D_bufs :  for i in 0 to 15  generate 
   EBI1_D_iobuf_inst : IOBUF
    port map (
    O =>  ebi1_d_in(i),      -- Buffer output, memory -> FPGA 
    IO => EBI1_D(i),         -- memory data bus
    I =>  ebi1_d_out(i),     -- Buffer input, FPGA -> memory
    T =>  ebi1_d_trst        -- disable FPGA -> memory
    );
   end generate  EBI1_D_bufs; 

  REG_ADDR_LATCH: process(EBI1_NCS2, reset)
   begin
    if (reset='1') then
     reg_addr <= X"0000";
    elsif falling_edge (EBI1_NCS2) then
     reg_addr <= EBI1_ADDR;
    end if;
   end process REG_ADDR_LATCH;
   
   REG_WRITE : process (EBI1_NWE, reset)
    begin
     if (reset='1') then
      ctrl_reg <= X"0000";
     elsif rising_edge (EBI1_NWE) then
      if reg_addr = CTRL_ADDR then
       ctrl_reg <= ebi1_d_in;
      end if; 
     end if; --(reset='1')
    end process REG_WRITE;     
      
  REG_READ_SEL : process (reg_addr, ctrl_reg, adc_reg, discr_reg, stat_reg)
    begin     
      if reg_addr  = CTRL_ADDR then
       ebi1_d_out <= ctrl_reg;
      elsif reg_addr = ADC_ADDR then
       ebi1_d_out <= X"00" & adc_reg;
      elsif reg_addr = DISCR_ADDR then
       ebi1_d_out <= X"00" & discr_reg;
      elsif reg_addr = STAT_ADDR then
       ebi1_d_out <= B"00" & stat_reg;
      else 
       ebi1_d_out <= X"0000";             -- to avoid latches
      end if; --reg_addr  = CTRL_ADDR
     end process REG_READ_SEL; 

    ebi1_d_trst <= EBI1_NRD;   
 
 
DUMMY1: process (COM_ADC_DCO)
  begin
   if rising_edge(COM_ADC_DCO) then
    if(COM_ADC_D = B"11" & X"ABC") and (COM_ADC_OR = '1')  then
     COM_ADC_CSBn <= '0';
     COM_ADC_SCLK <= '1';
     COM_ADC_SDIO <= '1';
     com_adc_clk  <= '0';
    else
     COM_ADC_CSBn <= '1';
     COM_ADC_SCLK <= '0';
     COM_ADC_SDIO <= '0';
     com_adc_clk  <= '1';     
    end if;
   end if;
  end process DUMMY1;

DUMMY2: process (DRS4_DTAP)
  begin
   if rising_edge(DRS4_DTAP) then
    if(DRS4_WSROUT = '1') and (DRS4_SROUT = '1') and (DRS4_PLLLCK = '1')  then
     drs4_refclk <= '1';
    else
     drs4_refclk <= '0';
    end if;
   end if;
  end process DUMMY2; 
 
DUMMY3: process (gclk2, reset)
   variable ct: std_logic_vector(25 downto 0);
  begin 
    if rising_edge (gclk2) then
      if reset = '1' then
        ct           := (others =>'0');
         ADC_SCK      <= '0';
         ADC_SDI      <= '0';
 
         DRS4_RESETn  <= '0';
         DRS4_A       <= X"0";         
         DRS4_SRIN    <= '0';
         DRS4_WSRIN   <= '0';
         DRS4_SRCLK   <= '0';
         DRS4_RSLOAD  <= '0';
         DRS4_DWRITE  <= '0';
         DRS4_DENABLE <= '0';

         I2C_SCL       <= B"00000";
         i2c_data_out  <= B"00000";
         i2c_data_trst <= B"11111";
         
         DAC_SCL      <= '0';
         dac_sda_out  <= '0';
         dac_sda_trst <= '1';
         
         FLB_I2C_SCL  <= '0';
         flb_i2c_data_out  <= '0';
         flb_i2c_data_trst <= '1';
             
         STAMP_TXD1   <= '0';
         STAMP_DTXD   <= '0';
  
         TEST_IO       <= X"0";
         
         
         adc_enc      <= '0'; 
         nLED_ENA     <= '0';              
         nLED_RED     <= '0';           
         nLED_GREEN   <= '0';        
         CFG_STAMPn   <= '0';
         PC1_ARM_IRQ0 <= '0';
         EBI1_NWAIT   <= '0';
 
       else          -- ELSE ...
          ct := ct + 1;
 
         nLED_ENA    <= ct(2);              
         nLED_RED    <= ct(1);           
         nLED_GREEN  <= ct(0);           
         CFG_STAMPn  <= ct(3);
         
         DRS4_RESETn  <= '1';
         DRS4_A       <= ct(7 downto 4);         
         DRS4_SRIN    <= ct(8);
         DRS4_WSRIN   <= ct(9);
         DRS4_SRCLK   <= ct(10);
         DRS4_RSLOAD  <= ct(11);
         DRS4_DWRITE  <= ct(12);
         DRS4_DENABLE <= ct(13);
         
         I2C_SCL       <= ct(4 downto 0);
         i2c_data_out  <= ct(9 downto 5);
         i2c_data_trst <= B"00000";
         
         DAC_SCL      <= ct(10);
         dac_sda_out  <= ct(11);
         dac_sda_trst <= ct(12);
         
         FLB_I2C_SCL       <= ct(13);
         flb_i2c_data_out  <= ct(14);
         flb_i2c_data_trst <= '0';    
    
         ADC_SCK      <= ct(15);
         ADC_SDI      <= ct(16);
          
         adc_enc      <= ct(17);
         flb_trig1    <= ct(18);
         flb_trig2    <= ct(19);
         COM_DAC_DB   <= ct(11 downto 0);
         COM_DAC_CLOCK <= ct(20);
                  
         STAMP_DTXD <= STAMP_DRXD;
         STAMP_TXD1 <= STAMP_RXD1;
         TEST_IO    <= ct(24 downto 21);
         PC1_ARM_IRQ0 <= HCM_DRDY;
         EBI1_NWAIT <= ct(25);
          
       end if; -- clk_if
     end if; -- reset_if
   end process DUMMY3;
 

 
  DUMMY4: process (gclk2)
  begin 
    if rising_edge (gclk2) then
     if adc_fra='1' and adc_frb='1' and adc_dcoa='1' and adc_dcob='1' then
      ADC_CSAn <='0';
      ADC_CSBn <='1';
     else
      ADC_CSAn <='1';
      ADC_CSBn <='0';     
     end if;
    end if;
   end process DUMMY4;     

  ADC_PAR_SERn <= '0'; -- on the board needs to be connected to GND !!!

 
end arch_uvl_mb_pinout_top ;
