-------------------------------------------------------
-- Design Name      : uvl_mb_pinout_top
-- File Name        : uvl_mb_pinout_top.vhd
-- Device           : Spartan 6, XC6SLX16CSG324-3
-- Migration Device : Spartan 6, XC6SLX45CSG324-3
-- Function         : UV-logger mainboard FPGA, top level design,
--                    dummy design to verify the initial pinout
-- Coder            : Kossatz, Sulanke, DESY, 2018-07-06
-------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.types.all;
use work.types_platformSpecific.all;

--use IEEE.std_logic_unsigned.all ;

library unisim;
use unisim.vcomponents.all;

entity uvl_mb_pinout_top is generic
    (
      S               : integer := 8;            -- Parameter to set the serdes factor 1..8
      PLL_DIV         : integer := 1;            -- Parameter to set division for PLL
      PLL_MULT        : integer := 40;           -- Parameter to set multiplier for PLL (7 for video links, 2 for DDR etc)
      CLKIN_PERIOD    : real    := 40.0          -- clock period (ns) of input clock on clkin_p
     );
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
      DRS4_WSROUT   : inout  std_logic; -- Double function: Write Shift Register
      --DRS4_WSROUT   : in  std_logic; -- Double function: Write Shift Register
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

      DISCR_OUTp  : in std_logic_vector(5 downto 0); -- LVDS, discriminator outputs
      DISCR_OUTn  : in std_logic_vector(5 downto 0);

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
      STAMP_DRXD    : out std_logic;  -- stamp debug uart
      STAMP_DTXD    : in std_logic; --
      STAMP_RXD1    : out std_logic;  -- PB5, stamp uart
      STAMP_TXD1    : in std_logic; -- PB4,

      HCM_DRDY      : in std_logic;  -- compass sensor status

      TEST_IO       : out std_logic_vector(3 downto 0) -- 3.3V CMOS / LVDS bidir. test port, p/n=1/0 or 3/2
     );
end uvl_mb_pinout_top ;

architecture arch_uvl_mb_pinout_top of uvl_mb_pinout_top is

	signal reset       : std_logic;
	signal reset_ct    : std_logic_vector(3 downto 0);

	-- ADC, 8 channel, LTM9007-14
	signal adc_enc     : std_logic;
	signal adc_outa    : std_logic_vector(1 to 8);
	signal adc_fra     : std_logic;
	signal adc_frb     : std_logic;
	signal adc_dcoa    : std_logic;
	signal adc_dcob    : std_logic;
	
	signal drs4_refclk : std_logic;

	--signal discr_out   : std_logic_vector(0 to 7) ; -- lvds inbuf outputs

	-- tristate signals
	signal i2c_data_in     : std_logic_vector(0 to 4); -- IO_BUF_O, data received
	signal i2c_data_out    : std_logic_vector(0 to 4); -- IO_BUF_I, data to be sent
	--signal i2c_data_trst   : std_logic_vector(0 to 4); -- IO_BUF_T, io buffer tristate

	--signal dac_sda_in      : std_logic;
	--signal dac_sda_out     : std_logic;
	--signal dac_sda_trst    : std_logic;

	--signal flb_i2c_data_in     : std_logic;
	--signal flb_i2c_data_out    : std_logic;
	--signal flb_i2c_data_trst   : std_logic;

------------------------

	signal clocks : clocks_t;
	signal clockConfig_debug : clockConfig_debug_t;
	signal commClock : std_logic;
	signal commClockReset : std_logic;
	
	signal ebiNotWrite : std_logic := '0';
	signal ebiNotRead : std_logic := '0';
	signal ebiNotChipSelect : std_logic := '0';
	signal ebiAddress : std_logic_vector(23 downto 0) := (others=>'0');
	signal ebiDataIn : std_logic_vector(15 downto 0) := (others=>'0');
	signal ebiDataOut : std_logic_vector(15 downto 0) := (others=>'0');

	signal addressAndControlBus : std_logic_vector(31 downto 0);

	signal adcNcsA : std_logic := '0';
	signal adcNcsB : std_logic := '0';
	signal adcSdi : std_logic := '0';
	signal adcSck : std_logic := '0';

	signal discriminatorSerdes_6 : std_logic_vector(6*8-1 downto 0) := (others=>'0');
	signal discriminatorSerdes : std_logic_vector(numberOfChannels_platformSpecific*8-1 downto 0) := (others=>'0');
	signal discriminatorSerdesDelayed : std_logic_vector(discriminatorSerdes'length-1 downto 0) := (others=>'0');
	signal discriminatorSerdesDelayed2 : std_logic_vector(discriminatorSerdes'length-1 downto 0) := (others=>'0');

	signal drs4_pins_A : drs4_pins_A_t; 
	signal drs4_pins_B : drs4_pins_B_t; 

	signal drs4_to_ltm9007_14 : drs4_to_ltm9007_14_t;
	signal drs4Data : ltm9007_14_to_eventFifoSystem_t;
	signal internalTiming : internalTiming_t;
	signal trigger : triggerLogic_t;
	signal triggerTiming : triggerTiming_t;
	signal pixelRates : pixelRateCounter_v2_t;
	signal dac1_stats : dac1_uvLogger_stats_t;
	
	signal ltm9007_14_0r : ltm9007_14_registerRead_t;
	signal ltm9007_14_0w : ltm9007_14_registerWrite_t;
	signal drs4_0r : drs4_registerRead_t;
	signal drs4_0w : drs4_registerWrite_t;
	signal internalTiming_0r : internalTiming_registerRead_t;
	signal internalTiming_0w : internalTiming_registerWrite_t;
	signal triggerDataDelay_0r : triggerDataDelay_registerRead_t;
	signal triggerDataDelay_0w : triggerDataDelay_registerWrite_t;
	signal triggerDataDelay_1r : triggerDataDelay_registerRead_t;
	signal triggerDataDelay_1w : triggerDataDelay_registerWrite_t;
	signal triggerLogic_0r : triggerLogic_registerRead_t;
	signal triggerLogic_0w : triggerLogic_registerWrite_t;
	signal triggerTimeToRisingEdge_0r : triggerTimeToRisingEdge_registerRead_t;
	signal triggerTimeToRisingEdge_0w : triggerTimeToRisingEdge_registerWrite_t;
	signal pixelRateCounter_0r : pixelRateCounter_v2_registerRead_t;
	signal pixelRateCounter_0w : pixelRateCounter_v2_registerWrite_t;
	signal eventFifoSystem_0r : eventFifoSystem_registerRead_t;
	signal eventFifoSystem_0w : eventFifoSystem_registerWrite_t;
	signal dac1_uvLogger_0r : dac1_uvLogger_registerRead_t;
	signal dac1_uvLogger_0w : dac1_uvLogger_registerWrite_t;
--	signal tmp10x_uvLogger_0r : tmp10x_uvLogger_registerRead_t;
--	signal tmp10x_uvLogger_0w : tmp10x_uvLogger_registerWrite_t;
	signal i2c_genericBus_0r : i2c_genericBus_registerRead_t;
	signal i2c_genericBus_0w : i2c_genericBus_registerWrite_t;
	signal i2c_genericBus_1r : i2c_genericBus_registerRead_t;
	signal i2c_genericBus_1w : i2c_genericBus_registerWrite_t;
	signal i2c_genericBus_2r : i2c_genericBus_registerRead_t;
	signal i2c_genericBus_2w : i2c_genericBus_registerWrite_t;
	signal i2c_genericBus_3r : i2c_genericBus_registerRead_t;
	signal i2c_genericBus_3w : i2c_genericBus_registerWrite_t;
	signal i2c_genericBus_4r : i2c_genericBus_registerRead_t;
	signal i2c_genericBus_4w : i2c_genericBus_registerWrite_t;
	signal i2c_genericBus_5r : i2c_genericBus_registerRead_t;
	signal i2c_genericBus_5w : i2c_genericBus_registerWrite_t;
	signal ledFlasher_0r : ledFlasher_registerRead_t;
	signal ledFlasher_0w : ledFlasher_registerWrite_t;
	signal houseKeeping_0r : houseKeeping_registerRead_t;
	signal houseKeeping_0w : houseKeeping_registerWrite_t;
	signal commDebug_0r : commDebug_registerRead_t;
	signal commDebug_0w : commDebug_registerWrite_t;

	signal deadTime : std_logic := '0';
	signal rateCounterTimeOut : std_logic := '0';
	signal irq2arm : std_logic := '0';

	signal testIo : std_logic_vector(3 downto 0);
	signal flasherSumOut : std_logic;
	
	signal enableJ24TestPins : std_logic;
	
	signal jumper : std_logic_vector(15 downto 0);
	
begin

	i00: IBUFDS generic map(DIFF_TERM => true) port map (I=>ADC_FRAP, IB=>ADC_FRAN, O=>open);
	i01: IBUFDS generic map(DIFF_TERM => true) port map (I=>ADC_FRBP, IB=>ADC_FRBN, O=>open);
	i02: IBUFDS generic map(DIFF_TERM => true) port map (I=>ADC_DCOAP, IB=>ADC_DCOAN, O=>open);
	i03: IBUFDS generic map(DIFF_TERM => true) port map (I=>ADC_DCOBP, IB=>ADC_DCOBN, O=>open);
	--i04: OBUFDS generic map (IOSTANDARD=>"LVDS_33") port map (O=>ADC_ENCp, OB=>ADC_ENCn, I=>adc_enc); 
	--g0: for i in 1 to 8 generate j0: IBUFDS port map (O=>adc_outa(i), I=>ADC_OUTAP(i), IB=>ADC_OUTAN(i)); end generate;
	--i04: OBUF port map(O => ADC_CSAn, I => adcNcsA); -- move to module
	--i04: OBUF port map(O => ADC_CSBn, I => adcNcsB); -- move to module
	i04a: OBUF port map(O => ADC_SDI, I => adcSdi);
	i04b: OBUF port map(O => ADC_SCK, I => adcSck);
	i04c: OBUF port map(O => ADC_PAR_SERn, I => '0'); -- ## has to be GND!!!

	--i06: OBUFDS port map (O=>FLB_TRIG1_P, OB=>FLB_TRIG1_N, I=>'0'); -- ##
	--i07: OBUFDS port map (O=>FLB_TRIG2_P, OB=>FLB_TRIG2_N, I=>'0'); -- ##

	--g1: for i in 0 to 5 generate
    --	j0: IBUFDS port map (O=>discr_out(i), I=>DISCR_OUTp(i), IB=>DISCR_OUTn(i));
	--end generate;

	id00: OBUFDS port map(O => DRS4_REFCLKp, OB => DRS4_REFCLKn, I => clocks.drs4RefClock);
	id01: OBUF port map(O => DRS4_RESETn, I => drs4_pins_A.notReset);
	g8: for i in 0 to 3 generate k: OBUF port map(O => DRS4_A(i), I => drs4_pins_A.address(i)); end generate;
	id03: OBUF port map(O => DRS4_SRIN, I => drs4_pins_A.mosi);
	id04: OBUF port map(O => DRS4_SRCLK, I => drs4_pins_A.sclk);
	id05: OBUF port map(O => DRS4_RSLOAD, I => drs4_pins_A.rsrload);
	id06: OBUF port map(O => DRS4_DWRITE, I => drs4_pins_A.dwrite);
	id07: OBUF port map(O => DRS4_DENABLE, I => drs4_pins_A.denable);
	id08: IBUF port map(I => DRS4_SROUT, O => drs4_pins_B.miso);
	id09: IBUF port map(I => DRS4_DTAP, O => drs4_pins_B.dtap);
	id10: IBUF port map(I => DRS4_PLLLCK, O => drs4_pins_B.plllck);
	id11: OBUF port map(O => DRS4_WSRIN, I => '0'); -- drs4_pins_A.wsrin);
--	id12: IBUF port map(I => DRS4_WSROUT, O => open); -- drs4_pins_B.wsrout);
	id12: IOBUF port map (O=>open, IO=>DRS4_WSROUT, I=> drs4_pins_A.address(0), T=>'1');

--	g2: for i in 1 to 4 generate
--		j0: IOBUF port map (O=>i2c_data_in(i), IO=>I2C_DATA(i), I=>i2c_data_out(i), T=>'1');
--		j1: OBUF port map(O => I2C_SCL(i), I => '0');
--	end generate;

	--i11a: IOBUF port map (O=>dac_sda_in, IO=>DAC_SDA, I=>dac_sda_out, T=>dac_sda_trst);
	--i11b: OBUF port map(O => DAC_SCL, I => '0');
	--i12a: IOBUF port map (O=>flb_i2c_data_in, IO=>FLB_I2C_DATA, I=>flb_i2c_data_out, T=>flb_i2c_data_trst);
	--i12b: OBUF port map(O => FLB_I2C_SCL, I => '0');

	-- EBI
	i21: IBUF port map(I => EBI1_NCS2, O => ebiNotChipSelect);
	i22: IBUF port map(I => EBI1_NWE, O => ebiNotWrite);
	i23: IBUF port map(I => EBI1_NRD, O => ebiNotRead);
	i24: OBUF port map(O => EBI1_NWAIT, I => '1');
	g4: for i in 0 to 15 generate k: IBUF port map(I => EBI1_ADDR(i), O => ebiAddress(i)); end generate;
	ebiAddress(23 downto 16) <= x"00";

	g5: for i in 0 to 15 generate
		k: IOBUF generic map(DRIVE => 2, IBUF_DELAY_VALUE => "0", IFD_DELAY_VALUE => "AUTO", IOSTANDARD => "DEFAULT", SLEW => "SLOW")
			port map(O => ebiDataIn(i), IO => EBI1_D(i), I => ebiDataOut(i), T => ebiNotRead);
	end generate;
	
	i29: OBUF port map(O => PC1_ARM_IRQ0, I => irq2arm);
	
	d0: for i in 0 to 3 generate k1: OBUF port map(O => TEST_IO(i), I => testIo(i)); end generate;
	d1: IBUF port map(I => HCM_DRDY, O => open);
	
	d8: OBUF port map(O => CFG_STAMPn, I => '0');
	--d9: OBUF port map(O => nLED_ENA, I => notPcbLedEnable);
	--d10: OBUF port map(O => nLED_GREEN, I => notLedGreen);
	--d11: OBUF port map(O => nLED_RED, I => notLedRed);

-- for: comm...
--	d2: IBUF port map(I => STAMP_DTXD, O => open);
--	d3: OBUF port map(O => STAMP_DRXD, I => '0');
--	d4: IBUF port map(I => STAMP_TXD1, O => open);
--	d5: OBUF port map(O => STAMP_RXD1, I => '0');
--
--	d6: for i in 0 to 11 generate k2: OBUF port map(O => COM_DAC_DB(i), I => '0'); end generate;
--	d7: OBUF port map(O => COM_DAC_CLOCK, I => '0');
--
--	i05: OBUFDS port map (O=>COM_ADC_CLK_P, OB=>COM_ADC_CLK_N, I=>'0'); -- ## 
--	d12: for i in 0 to 13 generate k3: IBUF port map(I => COM_ADC_D(i), O => open); end generate;
--	d13: IBUF port map(I => COM_ADC_OR, O => open);
	d14: OBUF port map(O => COM_ADC_SCLK, I => '0');
--	d15: OBUF port map(O => COM_ADC_CSBn, I => '0');
	d16: OBUF port map(O => COM_ADC_SDIO, I => '0');
	


-------------------------------------------------------------------------------
	testIo <= (0 => trigger.triggerNotDelayed, 3 => flasherSumOut, others=>'0') when enableJ24TestPins = '1' else (others=>'0');

	clockConfig_debug.drs4RefClockPeriod <= x"7f";
	x0: entity work.clockConfig port map(QOSC_OUT, '0', clocks.triggerSerdesClocks, clocks.adcClocks, commClock, commClockReset, open, clockConfig_debug, clocks.drs4RefClock);
	
	x1: entity work.smcBusWrapper port map("not"(ebiNotChipSelect), ebiAddress, "not"(ebiNotRead), "not"(ebiNotWrite), clocks.triggerSerdesClocks.serdesDivClockReset, clocks.triggerSerdesClocks.serdesDivClock, addressAndControlBus);
	
	x3: entity work.registerInterface_uvLogger port map(addressAndControlBus, ebiDataIn, ebiDataOut,
		internalTiming_0r,
		internalTiming_0w,
		triggerDataDelay_0r,
		triggerDataDelay_0w,
		triggerDataDelay_1r,
		triggerDataDelay_1w,
		drs4_0r,
		drs4_0w,
		ltm9007_14_0r,
		ltm9007_14_0w,
		triggerTimeToRisingEdge_0r,
		triggerTimeToRisingEdge_0w,
		eventFifoSystem_0r,
		eventFifoSystem_0w,
		pixelRateCounter_0r,
		pixelRateCounter_0w,
		triggerLogic_0r,
		triggerLogic_0w,
		dac1_uvLogger_0r,
		dac1_uvLogger_0w,
--		tmp10x_uvLogger_0r,
--		tmp10x_uvLogger_0w,
		i2c_genericBus_0r,
		i2c_genericBus_0w,
		i2c_genericBus_1r,
		i2c_genericBus_1w,
		i2c_genericBus_2r,
		i2c_genericBus_2w,
		i2c_genericBus_3r,
		i2c_genericBus_3w,
		i2c_genericBus_4r,
		i2c_genericBus_4w,
		i2c_genericBus_5r,
		i2c_genericBus_5w,
		ledFlasher_0r,
		ledFlasher_0w,
		houseKeeping_0r,
		houseKeeping_0w,
		--commDebug_0r,
		commDebug_0w,
		open
	);

	x6: entity work.serdesIn_1to8 generic map (D=>6) port map('0', DISCR_OUTp, DISCR_OUTn, clocks.triggerSerdesClocks, '0', "00", discriminatorSerdes_6, open);
	discriminatorSerdes <= x"0000" & not(discriminatorSerdes_6);
	
	x8: entity work.triggerLogic generic map(8) port map(discriminatorSerdes, flasherSumOut, deadTime, internalTiming, trigger, triggerLogic_0r, triggerLogic_0w);
	
	x9a: entity work.triggerDataDelay port map(discriminatorSerdes, discriminatorSerdesDelayed, triggerDataDelay_0r, triggerDataDelay_0w);
	x9b: entity work.triggerDataDelay port map(discriminatorSerdes, discriminatorSerdesDelayed2, triggerDataDelay_1r, triggerDataDelay_1w);
	
--	x10: entity work.triggerTimeToRisingEdge_v3 generic map(8) port map(discriminatorSerdesDelayed, trigger, triggerTimeToRisingEdge_0r, triggerTimeToRisingEdge_0w, triggerTiming);
	x10: entity work.triggerTimeToRisingEdge_v3 generic map(8) port map(discriminatorSerdes, trigger, triggerTimeToRisingEdge_0r, triggerTimeToRisingEdge_0w, triggerTiming);

	--x12: entity work.pixelRateCounter_v2 port map(discriminatorSerdesDelayed2, trigger, rateCounterTimeOut, pixelRates, internalTiming, pixelRateCounter_0r, pixelRateCounter_0w);
	x12: entity work.pixelRateCounter_v2 port map(discriminatorSerdes, trigger.flasherTriggerGate, rateCounterTimeOut, pixelRates, internalTiming, pixelRateCounter_0r, pixelRateCounter_0w);

	x11: entity work.eventFifoSystem port map(trigger, rateCounterTimeOut, irq2arm, triggerTiming, drs4Data, internalTiming, pixelRates, dac1_stats, eventFifoSystem_0r, eventFifoSystem_0w);
	
	x14a: entity work.internalTiming generic map(globalClockRate_kHz) port map(internalTiming, internalTiming_0r, internalTiming_0w);
	
	x16: entity work.drs4 port map(drs4_pins_A.notReset, drs4_pins_A.address, drs4_pins_A.denable, drs4_pins_A.dwrite, drs4_pins_A.dwriteSerdes, drs4_pins_A.rsrload, drs4_pins_B.miso, drs4_pins_A.mosi, drs4_pins_A.sclk, drs4_pins_B.dtap, drs4_pins_B.plllck, deadTime, trigger.timingAndDrs4, internalTiming, clocks.adcClocks, drs4_to_ltm9007_14, drs4_0r, drs4_0w);
	
--	x17: entity work.ltm9007_14 port map(ADC_ENCp, ADC_ENCn, ADC_OUTAP, ADC_OUTAN, ADC_CSAn, ADC_CSBn,
--		adcSdi, adcSck, drs4_to_ltm9007_14, drs4Data, clocks.adcClocks, ltm9007_14_0r, ltm9007_14_0w);
	
	x17: entity work.ltm9007_14 port map(ADC_ENCp, ADC_ENCn, ADC_OUTAP, ADC_OUTAN, ADC_CSAn, ADC_CSBn,
		adcSdi, adcSck, drs4_to_ltm9007_14, drs4Data, clocks.adcClocks, ltm9007_14_0r, ltm9007_14_0w);

	x20: entity work.i2c_dac1_uvLogger port map(DAC_SCL, DAC_SDA, dac1_stats, dac1_uvLogger_0r, dac1_uvLogger_0w);
	
	x21a: entity work.i2c_genericBus port map(I2C_SCL(0), I2C_DATA(0), i2c_genericBus_0r, i2c_genericBus_0w);
	x21b: entity work.i2c_genericBus port map(I2C_SCL(1), I2C_DATA(1), i2c_genericBus_1r, i2c_genericBus_1w);
	x21c: entity work.i2c_genericBus port map(I2C_SCL(2), I2C_DATA(2), i2c_genericBus_2r, i2c_genericBus_2w);
	x21d: entity work.i2c_genericBus port map(I2C_SCL(3), I2C_DATA(3), i2c_genericBus_3r, i2c_genericBus_3w);
	x21e: entity work.i2c_genericBus port map(I2C_SCL(4), I2C_DATA(4), i2c_genericBus_4r, i2c_genericBus_4w);
	
	x21f: entity work.i2c_genericBus port map(FLB_I2C_SCL, FLB_I2C_DATA, i2c_genericBus_5r, i2c_genericBus_5w);
	
	x22: entity work.ledFlasher port map(FLB_TRIG1_P, FLB_TRIG1_N, FLB_TRIG2_P, FLB_TRIG2_N, flasherSumOut, ledFlasher_0r, ledFlasher_0w);
	
	x23: entity work.houseKeeping port map(nLED_ENA, nLED_GREEN, nLED_RED, enableJ24TestPins, houseKeeping_0r, houseKeeping_0w);
	
--	x30: entity work.uvl_comm_top_01 port map
--	(
--	commClock,
--	commClock,
--	COM_ADC_D,
--	COM_ADC_OR,
--	COM_ADC_CSBn,
--	open, --COM_ADC_SCLK,
--	open, --COM_ADC_SDIO,
--	COM_ADC_DCO,
--	COM_ADC_CLK_P,
--	COM_ADC_CLK_N,
--	COM_DAC_DB,
--	COM_DAC_CLOCK,
--	STAMP_DRXD,
--	STAMP_DTXD,
--	STAMP_RXD1,
--	STAMP_TXD1,
--	open,
--	commDebug_0w
--	);

	x31a: entity work.syncTig generic map (commDebug_0w.jumper'length) port map (commClock, commDebug_0w.jumper, jumper);

	x31: entity work.uvl_readout_top_01 port map
	(	
		clk => commClock,
		reset => commClockReset,
		com_clk => commClock,
		com_reset => commClockReset,

		PWRENn => '0', --          : in  std_logic ;  --   
		FT_TEST => open, --         : out std_logic;   -- 
		FT_RESETn => open, --       : out std_logic;  -- 
		--CLK_6MHZ => open, --    : out  std_logic;  -- clock used by the USB to UART bridge
		TEST_IO0 => open, --        : out std_logic;   --
		TEST_IO1 => jumper(0), --        : in  std_logic;   --
		TEST_IO2 => open, --        : out std_logic;   --
		TEST_IO3 => jumper(1), --        : in  std_logic;   --
		TEST_IO4 => open, --        : out std_logic;   --
		TEST_IO5 => jumper(2), --        : in  std_logic;   --
		TEST_IO6 => open, --        : out std_logic;   --
		TEST_IO7 => open, --        : out std_logic;   --
		TEST_IO8 => open, --        : out std_logic;   --
		TEST_IO9 => jumper(3), --        : in  std_logic;   --
		TEST_IO10 => open, --       : out std_logic;   --
		TEST_IO11 => jumper(4), --       : in  std_logic;   --
		TEST_IO12 => open, --       : out std_logic;   --
		TEST_IO13 => jumper(5), --       : in  std_logic;   --
		TEST_IO14 => open, --       : out std_logic;   --
		TEST_IO15 => open, --       : out std_logic;   --
		I2C_DATA => open, --        : inout std_logic; --
		I2C_SCL => open, --         : out std_logic;   --

		-- bank_1, 1.8V
		COM_ADC_CSBn => COM_ADC_CSBn, --    : out std_logic;   --
		COM_ADC_SCLK => open, --    : out std_logic;   --
		COM_ADC_SDIO => open, --    : inout std_logic;   --
		COM_ADC_D => COM_ADC_D, --       : in  std_logic_vector (13 downto 0);
		--     COM_ADC_DCO     : in  std_logic;  -- 
		--     COM_ADC_OR      : in  std_logic;  -- 
		RX_LEDn => open, --         : out std_logic;   --
		QOSCL_SCL => open, --       : out std_logic;   --
		QOSCL_SDA => open, --       : inout std_logic;   --

		-- bank_2, 3.3V
		COM_DAC_DB => COM_DAC_DB, --      : out std_logic_vector (11 downto 0);
		COM_DAC_CLOCK => COM_DAC_CLOCK, --   : out std_logic;   --
		
		TX_LEDn => open, --         : out std_logic;   --
		COM_ADC_CLK_N => COM_ADC_CLK_N, --   : out std_logic;   --
		COM_ADC_CLK_P => COM_ADC_CLK_P, --   : out std_logic;   --

		-- bank_3, 3.3V
		BDBUS0 => STAMP_TXD1, --          : in  std_logic;   -- TXD_B
		BDBUS1 => STAMP_RXD1, --          : out std_logic;   -- RXD_B
		BCBUS2 => '0', --          : in  std_logic;   -- RXLEDn_B, transmitting data via USB
		BCBUS3 => '0', --          : in  std_logic;   -- TXLEDn_B, receiving data via USB   
		--     SI_WUB          : in  std_logic;   --
		ADBUS0 => STAMP_DTXD, --          : in  std_logic;   -- TXD_A
		ADBUS1 => STAMP_DRXD, --          : out std_logic;   -- RXD_A
		ACBUS2 => '0', --          : in  std_logic;   -- RXLEDn_A, transmitting data via USB
		ACBUS3 => '0' --          : in  std_logic   -- TXLEDn_A, receiving data via USB   
		--     SI_WUA
	);

end arch_uvl_mb_pinout_top;
