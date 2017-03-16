-------------------------------------------------------
-- Design Name      : taxi_003_top 
-- File Name        : taxi_003_top.vhd
-- Device           : Spartan 6, XC6SLX45FGG484-2
-- Migration Device : Spartan 6, XC6SLX100FGG484-2
-- Function         : taxi top level test design rev-003
-- Coder(s)         : K.-H. Sulanke & S. Kunwar, DESY, 2015-08-05
-------------------------------------------------------
-- compiling duration = min
-- implementing minimal functionality, needed for triggering / timestamping of events
-- DRS4 + serial ADCs disabled
-- QOSC1_OUT, 25 MHz, 3.3V CMOS 2.5 ppm
-- 2015-03-18
-- GPS_TIMEPULSE, GPS_TIMEPULSE2 connected to test pins LVDS_IO_0,5

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.types.all;
 
library unisim;
use unisim.vcomponents.all;

entity taxiTop is generic (
     BASE_ADDR       : std_logic_vector(20 downto  8) := '0' & X"000";
     S               : integer := 8 ;            -- Parameter to set the serdes factor 1..8
   DIFF_TERM         : boolean := TRUE) ;            -- Enable or disable internal differential termination
port(
      PON_RESETn      : in std_logic ;   -- 2.5V CMOS with pullup, reset (active low, by power monitor LTC2903-A1)
                                         -- 200 ms after all power lines are settled, might be useless due to race condition
                                         -- with FPGA configuration time
      QOSC1_OUT       : in std_logic ;   -- 2.5V CMOS, local CMOS clock osc.
      QOSC1_DAC_SYNCn : out std_logic ;  -- 2.5V CMOS, local CMOS clock
      
      QOSC2_OUT       : in std_logic ;   -- 2.5V CMOS, local CMOS clock osc.
      QOSC2_ENA       : out std_logic ;  -- 2.5V CMOS, local CMOS clock
      QOSC2_DAC_SYNCn : out std_logic ;  -- 2.5V CMOS,      
      QOSC2_DAC_SCKL  : out std_logic ;  -- 2.5V CMOS,   
      QOSC2_DAC_SDIN  : out std_logic ;  -- 2.5V CMOS,
       
      EXT_CLK_P       : in std_logic;    -- LVDS
      EXT_CLK_N       : in std_logic;    -- LVDS
      EXT_PPS_P       : in std_logic;    -- LVDS
      EXT_PPS_N       : in std_logic;    -- LVDS
      EXT_TRIG_OUT_P  : out std_logic;   -- LVDS
      EXT_TRIG_OUT_N  : out std_logic;   -- LVDS      
      EXT_TRIG_IN_P   : in std_logic;    -- LVDS
      EXT_TRIG_IN_N   : in std_logic;    -- LVDS      
 
       -- Discriminator output signals
      DISCR_OUT_1P  : in std_logic_vector(7 downto 0); -- LVDS, discriminator outputs
      DISCR_OUT_1N  : in std_logic_vector(7 downto 0);
      DISCR_OUT_2P  : in std_logic_vector(7 downto 0); -- LVDS, discriminator outputs
      DISCR_OUT_2N  : in std_logic_vector(7 downto 0);
      DISCR_OUT_3P  : in std_logic_vector(7 downto 0); -- LVDS, discriminator outputs
      DISCR_OUT_3N  : in std_logic_vector(7 downto 0);

      -- trigger to be used by the AERA board
      AERA_TRIG_P   : out std_logic;    -- LVDS
      AERA_TRIG_N   : out std_logic;    -- LVDS      
             
        -- ADC #1..3, LTM9007-14, 8 channel, ser out, 40 MSPS max., LVDS outputs
      ADC_OUTA_1P   : in  std_logic_vector(0 to 7); -- LVDS, iserdes inputs
      ADC_OUTA_1N   : in  std_logic_vector(0 to 7); 
      ADC_OUTA_2P   : in  std_logic_vector(0 to 7); -- LVDS, iserdes inputs
      ADC_OUTA_2N   : in  std_logic_vector(0 to 7); 
      ADC_OUTA_3P   : in  std_logic_vector(0 to 7); -- LVDS, iserdes inputs
      ADC_OUTA_3N   : in  std_logic_vector(0 to 7); 

      ADC_FRA_P    : in  std_logic_vector(1 to 3); -- Frame Start for Channels 1, 4, 5 and 8
      ADC_FRA_N    : in  std_logic_vector(1 to 3);
      ADC_FRB_P    : in  std_logic_vector(1 to 3); -- Frame Start for Channels 2, 3, 6 and 7
      ADC_FRB_N    : in  std_logic_vector(1 to 3);
      ADC_DCOA_P   : in  std_logic_vector(1 to 3); -- Data Clock for Channels 1, 4, 5 and 8
      ADC_DCOA_N   : in  std_logic_vector(1 to 3);     
      ADC_DCOB_P   : in  std_logic_vector(1 to 3); -- Data Clock for Channels 2, 3, 6 and 7
      ADC_DCOB_N   : in  std_logic_vector(1 to 3); 
      ADC_ENC_P    : out std_logic_vector(1 to 3); -- LVDS, conversion clock, conversion starts at rising edge    
      ADC_ENC_N    : out std_logic_vector(1 to 3);
  --  ADC_PAR_SERn : out std_logic; -- Incorrect signal removed completely from design. This Should be tied to ground.
      ADC_SDI      : out std_logic; -- shared serial interface data input 
      ADC_SCK      : out std_logic; -- shared serial interface clock input     
      ADC_CSA      : out std_logic_vector(1 to 3); -- serial interfacechip select, channels 1, 4, 5 and 8
      ADC_CSB      : out std_logic_vector(1 to 3); -- serial interfacechip select, channels 2, 3, 6 and 7
		
       -- ADC LTC2173-14, 4 channel, ser out, 80 MSPS max., LVDS outputs
      ADC_OUTA_4P   : in  std_logic_vector(0 to 3); -- LVDS, oserdes data outputs
      ADC_OUTA_4N   : in  std_logic_vector(0 to 3);    
      ADC_FR_4P     : in  std_logic; 
      ADC_FR_4N     : in  std_logic;
      ADC_DCO_4P    : in  std_logic; -- Data Clock Outputs
      ADC_DCO_4N    : in  std_logic;     
      ADC_ENC_4P    : out std_logic; -- LVDS, conversion clock, conversion starts at rising edge    
      ADC_ENC_4N    : out std_logic;
      ADC_CS_4      : out std_logic; -- serial interfacechip select
      ADC_SDO_4     : in  std_logic; -- serial interface data readback output
      
      -- Stamp9G45 1.8V signals
      EBI1_ADDR    : in std_logic_vector(20 downto 0); -- up to 21 memory bus address signals
      EBI1_D       : inout std_logic_vector(15 downto 0); -- memory bus data signals
      EBI1_NWE     : in std_logic; --EBI1_NWE/NWR0/CFWE, low active write strobe 
      EBI1_NCS2    : in std_logic; --PC13/NCS2,             address (hex) 3000 0000, low active Chip Select 2
      EBI1_NRD     : in std_logic; --EBI1_NRD/CFOE, low active read strobe
      EBI1_MCK     : in std_logic; --PB31/ISI_MCK/PCK1, might be used as clock
      EBI1_NWAIT    : out std_logic; --PC15/NWAIT, low active
      -- Stamp9G45 3.3V signals      
      PC1_ARM_IRQ0  : out std_logic; -- PIO port PC1, used as edge (both) triggered interrupt signal
      -- single wire 64 bit EEPROM
 --     ADDR_64BIT    : inout std_logic; -- 2.5V CMOS, one wire serial EPROM DS2431P
      ADDR_64BIT    : inout std_logic;
 
       -- DRS4 (Domino Ring Sampler) chips #1..3, 2.5V CMOS outputs      
      DRS4_SROUT   : in  std_logic_vector(1 to 3); -- Multiplexed Shift Register Output
 --     DRS4_WSROUT  : in  std_logic_vector(1 to 3); -- Double function: Write Shift Register  
                                                   -- Output if DWRITE=1, Read Shift Register Output if DWRITE=0
      DRS4_DTAP    : in  std_logic_vector(1 to 3); -- Domino Tap Signal Output toggling on each domino revolution
      DRS4_PLLLCK  : in  std_logic_vector(1 to 3); -- PLL Lock Indicator Output 
       -- DRS4 (Domino Ring Sampler) chips #1..3, 2.5V CMOS inputs      
      DRS4_RESETn  : out std_logic_vector(1 to 3); -- external Reset, leave open when using internal ..
      DRS4_A       : out std_logic_vector(3 downto 0); -- shared address bits       
      DRS4_SRIN    : out std_logic_vector(1 to 3);  -- Shared Shift Register Input   
      DRS4_SRCLK   : out std_logic_vector(1 to 3);  -- Multiplexed Shift Register Clock Input      
      DRS4_RSLOAD  : out std_logic_vector(1 to 3);  -- Read Shift Register Load Input
      DRS4_DWRITE  : out std_logic_vector(1 to 3);  -- Domino Write Input. Connects the Domino Wave Circuit to the 
                                                    -- Sampling Cells to enable sampling if high
      DRS4_DENABLE : out std_logic_vector(1 to 3);  -- Domino Enable Input. A low-to-high transition starts the Domino
                                                    -- Wave. Setting this input low stops the Domino Wave
        -- DRS4 clock, LVDS       
      DRS4_REFCLK_P : out std_logic_vector(1 to 3);  -- Reference Clock Input LVDS (+)    
      DRS4_REFCLK_N : out std_logic_vector(1 to 3);  -- Reference Clock Input LVDS (-)
      
           -- serial DAC to set the Discriminator thresholds
      DAC_DIN      : out std_logic_vector(3 downto 1);   -- 2.5V CMOS, serial DAC (discr. threshold)
      DAC_SCLK     : out std_logic_vector(3 downto 1);   -- 2.5V CMOS
      DAC_SYNCn    : out std_logic_vector(3 downto 1);    -- 2.5V CMOS, low active
      --DAC_DOUT     : in  std_logic_vector(1 to 3);    -- 2.5V CMOS

           -- paddle #1..3 control
      I2C_CLK      : inout std_logic_vector(3 downto 1);   -- I2C clock
      I2C_DATA     : inout std_logic_vector(3 downto 1); -- SN65HVD1782D, bidirectional data
      CBL_PLGDn    : in  std_logic_vector(1 to 3);    -- cable plugged, low active, needs pullup activated
      PON_PADDLEn  : out std_logic_vector(1 to 3);    -- Paddle power on signal
      POW_SW_SCL   : out std_logic;   -- paddle power switch monitoring ADC control
      POW_SW_SDA   : out std_logic;   -- paddle power switch monitoring ADC control
      POW_ALERT    : in  std_logic;   -- ADC AD7997 open drain output, needs pullup,

         -- RS232 / RS485 ports 
      RS232_TXD    : out std_logic;   -- 3.3V CMOS
      RS232_RXD    : in std_logic;    -- 3.3V CMOS 
  
      RS485_PV     : out std_logic;   -- 3.3V CMOS
      RS485_DE     : out std_logic;   -- 3.3V CMOS
      RS485_REn    : out std_logic;   -- 3.3V CMOS  
      RS485_TXD    : out std_logic;   -- 3.3V CMOS
      RS485_RXD    : in std_logic;    -- 3.3V CMOS

     -- GPS module LEA-6T ?? check wether this is really 3.3V .. 
      GPS_RESET_N    : out std_logic;   -- 3.3V CMOS, GPS-module reset
      GPS_EXTINT0    : out std_logic;   -- 3.3V CMOS, interrupt signal for time stamping an event
      GPS_TIMEPULSE  : in std_logic;    -- 3.3V CMOS, typical used as PPS pulse
      GPS_TIMEPULSE2 : in std_logic;    -- 3.3V CMOS, configurable, clock from 0.25 Hz to 10 MHz 
      GPS_RXD1       : out std_logic;   -- 3.3V CMOS,
      GPS_TXD1       : in std_logic;    -- 3.3V CMOS, 

      -- test signals DACs
      TEST_DAC_SCL   : inout std_logic;  -- 2.5V CMOS, DAC for test pulse (chain saw) generation
      TEST_DAC_SDA   : inout std_logic;  -- 2.5V CMOS,
      TEST_GATE      : out std_logic_vector(1 to 3);    -- 2.5V CMOS, to discharge the capacitor used for the chain saw signal
      TEST_PDn       : out std_logic;    -- 2.5V CMOS, to power down the test circuitry
      
      TEMPERATURE    : out std_logic;    -- 2.5V CMOS, inout , one wire temp. sensor
    
          -- test signals, NOT AVAILABLE for XC6SLX100FGG484-2 !!! 
      LVDS_IO_P    : out std_logic_vector(5 downto 0); -- LVDS bidir. test port 
      LVDS_IO_N    : out std_logic_vector(5 downto 0)  -- LVDS bidir. test port       
       
      );  
end taxiTop; 

architecture behaviour of taxiTop is

	attribute keep : string;

	signal asyncAddressAndControlBus : std_logic_vector(27 downto 0);
	signal addressAndControlBus : std_logic_vector(31 downto 0);
	signal clock0 : std_logic := '0';
	signal notClock0 : std_logic := '1';
	signal clock0out : std_logic;
	signal clockValid : std_logic;
	signal asyncReset : std_logic;
	
	signal ebiNotWrite : std_logic := '0';
	signal ebiNotRead : std_logic := '0';
	signal ebiNotChipSelect : std_logic := '0';
	signal ebiAddress : std_logic_vector(23 downto 0) := (others=>'0');
	signal ebiDataIn : std_logic_vector(15 downto 0) := (others=>'0');
	signal ebiDataOut : std_logic_vector(15 downto 0) := (others=>'0');
--	signal ebiDataOutActive : std_logic_vector(0 downto 0) := (others=>'0');

	constant numberOfDsr : integer := 3;
	type drsChannel_t is array(0 to numberOfDsr-1) of std_logic_vector(7 downto 0);
	signal discriminator : drsChannel_t;

	type adcData_t is array(0 to 6) of std_logic_vector(11 downto 0); --adc4channel_r;
	signal adcData : adcData_t;
	
	signal serdesDivClock : std_logic := '0';
	signal serdesIoClock_1 : std_logic := '0';
	signal serdesIoClock_2 : std_logic := '0';
	signal serdesStrobe_1 : std_logic := '0';
	signal serdesStrobe_2 : std_logic := '0';
	signal reset : std_logic := '0';
	signal discriminatorSerdes : std_logic_vector(8*8-1 downto 0) := (others=>'0');
	signal discriminatorSerdesDelayed : std_logic_vector(discriminatorSerdes'length-1 downto 0) := (others=>'0');
	attribute keep of discriminatorSerdes : signal is "true";
	
	signal error : std_logic_vector(3 downto 0);
	signal trigger :std_logic := '0';
	
	signal edgeData : std_logic_vector(8*16-1 downto 0);
	signal edgeDataReady : std_logic := '0';
	
	signal triggerTimeToRisingEdge0_r : triggerTimeToRisingEdge_registerRead_t;
	signal triggerTimeToRisingEdge0_w : triggerTimeToRisingEdge_registerWrite_t;
	signal eventFifoSystem0_r : eventFifoSystem_registerRead_t;
	signal eventFifoSystem0_w : eventFifoSystem_registerWrite_t;
	signal triggerDataDelay0_r: triggerDataDelay_registerRead_t;
	signal triggerDataDelay0_w: triggerDataDelay_registerWrite_t;
	signal pixelRateCounter0_r : pixelRateCounter_registerRead_t;
	signal pixelRateCounter0_w : pixelRateCounter_registerWrite_t;
	
	signal triggerTiming : triggerTiming_t;
	signal dsr4Timing : dsr4Timing_t;
	signal dsr4Sampling : dsr4Sampling_t := (newData => '0', samplingDone => '1', others => (others=>'0'));
	signal dsr4Charge : dsr4Charge_t := (newData => '0', chargeDone => '1', others => (others=>'0'));
	
begin

   g0: for i in 0 to 7 generate
--		i1: IBUFDS generic map(DIFF_TERM => true) port map (I => DISCR_OUT_1P(i), IB => DISCR_OUT_1N(i), O => discriminator(0)(i));
		i2: IBUFDS generic map(DIFF_TERM => true) port map (I => DISCR_OUT_2P(i), IB => DISCR_OUT_2N(i), O => discriminator(1)(i));
		i3: IBUFDS generic map(DIFF_TERM => true) port map (I => DISCR_OUT_3P(i), IB => DISCR_OUT_3N(i), O => discriminator(2)(i));

		i4: IBUFDS generic map(DIFF_TERM => true) port map (I => ADC_OUTA_1P(i), IB => ADC_OUTA_1N(i), O => open);--adcData(0)(i));
		i5: IBUFDS generic map(DIFF_TERM => true) port map (I => ADC_OUTA_2P(i), IB => ADC_OUTA_2N(i), O => open);--adcData(1)(i));
		i6: IBUFDS generic map(DIFF_TERM => true) port map (I => ADC_OUTA_3P(i), IB => ADC_OUTA_3N(i), O => open);--adcData(2)(i));

--		h2: IBUFDS generic map(DIFF_TERM => true) port map (I => P(i), IB => N(i), O => (i));
   end generate;
	
	g1: for i in 0 to numberOfDsr-1 generate
		i1: IBUFDS generic map(DIFF_TERM => true) port map (I => ADC_FRA_P(i+1), IB => ADC_FRA_N(i+1), O => open);--adcData(i)(8));
		i2: IBUFDS generic map(DIFF_TERM => true) port map (I => ADC_FRB_P(i+1), IB => ADC_FRB_N(i+1), O => open);--adcData(i)(9));
		i3: IBUFDS generic map(DIFF_TERM => true) port map (I => ADC_DCOA_P(i+1), IB => ADC_DCOA_N(i+1), O => open);--adcData(i)(10));
		i4: IBUFDS generic map(DIFF_TERM => true) port map (I => ADC_DCOB_P(i+1), IB => ADC_DCOB_N(i+1), O => open);--adcData(i)(11));
	end generate;

	g2: for i in 0 to 3 generate
		i1: IBUFDS generic map(DIFF_TERM => true) port map (I => ADC_OUTA_4P(i), IB => ADC_OUTA_4N(i), O => open);
	end generate;
	i1: IBUFDS generic map(DIFF_TERM => true) port map (I => ADC_FR_4P, IB => ADC_FR_4N, O => open);
	i2: IBUFDS generic map(DIFF_TERM => true) port map (I => ADC_DCO_4P, IB => ADC_DCO_4N, O => open);

	i3: IBUFDS generic map(DIFF_TERM => true) port map (I => EXT_CLK_P, IB => EXT_CLK_N, O => open);
	i4: IBUFDS generic map(DIFF_TERM => true) port map (I => EXT_PPS_P, IB => EXT_PPS_N, O => open);
	i5: IBUFDS generic map(DIFF_TERM => true) port map (I => EXT_TRIG_IN_P, IB => EXT_TRIG_IN_N, O => open);
	
	i6: OBUFDS port map(O => EXT_TRIG_OUT_P, OB => EXT_TRIG_OUT_N, I => '0');
	i7: OBUFDS port map(O => AERA_TRIG_P, OB => AERA_TRIG_N, I => '0');
	i8: OBUFDS port map(O => ADC_ENC_4P, OB => ADC_ENC_4N, I => '0');
	i9: OBUF port map(O => ADC_CS_4, I => '0');
	
	g3: for i in 1 to 3 generate
		i1: OBUFDS port map(O => ADC_ENC_P(i), OB => ADC_ENC_N(i), I => '0');
		i2: OBUFDS port map(O => DRS4_REFCLK_P(i), OB => DRS4_REFCLK_N(i), I => '0');
	end generate;
	
	--i10: OBUFDS port map(O => LVDS_IO_P(0), OB => LVDS_IO_N(0), I => clock0out);
	i11: OBUFDS port map(O => LVDS_IO_P(1), OB => LVDS_IO_N(1), I => error(0));
	i12: OBUFDS port map(O => LVDS_IO_P(2), OB => LVDS_IO_N(2), I => error(1));
	i13: OBUFDS port map(O => LVDS_IO_P(3), OB => LVDS_IO_N(3), I => error(2));
	i14: OBUFDS port map(O => LVDS_IO_P(4), OB => LVDS_IO_N(4), I => error(3));
	--i15: OBUFDS port map(O => LVDS_IO_P(5), OB => LVDS_IO_N(5), I => '0');

	notClock0 <= not(serdesDivClock);
	c1: ODDR2 port map(Q => clock0out, C0 => serdesDivClock, C1 => notClock0, CE => '1', D0 => '1', D1 => '0', R => '0', S => '0');

	i16: IBUF port map(I => EBI1_NWE, O => ebiNotWrite);
	i17: IBUF port map(I => EBI1_NCS2, O => ebiNotChipSelect);
	i18: IBUF port map(I => EBI1_NRD, O => ebiNotRead);
	g4: for i in 0 to 20 generate
		k: IBUF port map(I => EBI1_ADDR(i), O => ebiAddress(i));
	end generate;
	
	g5: for i in 0 to 15 generate 
		k: IOBUF generic map(DRIVE => 2, IBUF_DELAY_VALUE => "0", IFD_DELAY_VALUE => "AUTO", IOSTANDARD => "DEFAULT", SLEW => "SLOW")
			port map(O => ebiDataIn(i), IO => EBI1_D(i), I => ebiDataOut(i), T => ebiNotRead);
   end generate;

	i20: OBUF port map(O => QOSC1_DAC_SYNCn, I => '1');
	i21: OBUF port map(O => QOSC2_ENA, I => '0');
	i22: OBUF port map(O => QOSC2_DAC_SYNCn, I => '1');
	i23: OBUF port map(O => QOSC2_DAC_SCKL, I => '0');
	i24: OBUF port map(O => QOSC2_DAC_SDIN, I => '0');
	
	i25: OBUF port map(O => ADC_SDI, I => '0');
	i26: OBUF port map(O => ADC_SCK, I => '0');
	
	g6: for i in 1 to 3 generate
		k1: OBUF port map(O => ADC_CSA(i), I => '0');
		k2: OBUF port map(O => ADC_CSB(i), I => '0');
	end generate;
	
	i27: OBUF port map(O => EBI1_NWAIT, I => '1');
	i28: OBUF port map(O => PC1_ARM_IRQ0, I => '0');
	
	g7: for i in 1 to 3 generate k: OBUF port map(O => DRS4_RESETn(i), I => '1'); end generate;
	g8: for i in 0 to 3 generate k: OBUF port map(O => DRS4_A(i), I => '1'); end generate;
	
	g9: for i in 1 to 3 generate
		k1: OBUF port map(O => DRS4_SRIN(i), I => '0');
		k2: OBUF port map(O => DRS4_SRCLK(i), I => '0');
		k3: OBUF port map(O => DRS4_RSLOAD(i), I => '0');
		k4: OBUF port map(O => DRS4_DWRITE(i), I => '0');
		k5: OBUF port map(O => DRS4_DENABLE(i), I => '0');
	end generate;
	
	g10: for i in 1 to 3 generate
		k1: OBUF port map(O => DAC_DIN(i), I => '0');
		k2: OBUF port map(O => DAC_SCLK(i), I => '0');
		k3: OBUF port map(O => DAC_SYNCn(i), I => '1');
	end generate;
	
	g11: for i in 1 to 3 generate 
		k1: IOBUF port map(O => open, IO => I2C_CLK(i), I => '0', T => '1');
		k2: IOBUF port map(O => open, IO => I2C_DATA(i), I => '0', T => '1');
   end generate;
	
	g12: for i in 1 to 3 generate k: OBUF port map(O => PON_PADDLEn(i), I => '0'); end generate;
	i30: OBUF port map(O => POW_SW_SCL, I => '0');
	i31: OBUF port map(O => POW_SW_SDA, I => '0');
	
	i32: OBUF port map(O => RS232_TXD, I => '0');
	i33: OBUF port map(O => RS485_PV, I => '0');
	i34: OBUF port map(O => RS485_DE, I => '0');
	i35: OBUF port map(O => RS485_REn, I => '0');
	i36: OBUF port map(O => RS485_TXD, I => '0');
	i37: OBUF port map(O => GPS_RESET_N, I => '1');
	i38: OBUF port map(O => GPS_EXTINT0, I => '0');
	i39: OBUF port map(O => GPS_RXD1, I => '0');
	
	g13: for i in 1 to 3 generate k: OBUF port map(O => TEST_GATE(i), I => '0'); end generate;
	i40: OBUF port map(O => TEST_PDn, I => '0');
	i41: OBUF port map(O => TEMPERATURE, I => '0');
	
	i42: IOBUF port map(O => open, IO => ADDR_64BIT, I => '0', T => '1');

	i43: IOBUF port map(O => open, IO => TEST_DAC_SCL, I => '0', T => '1');
	i44: IOBUF port map(O => open, IO => TEST_DAC_SDA, I => '0', T => '1');

	asyncReset <= not(PON_RESETn and clockValid);

	--x0: entity work.pll1 port map(QOSC1_OUT, clock0, "not"(PON_RESETn), clockValid);
	
	x0: entity work.clockConfig port map(QOSC2_OUT, "not"(PON_RESETn), reset, serdesDivClock, serdesIoClock_1, serdesStrobe_1, serdesIoClock_2, serdesStrobe_2, clockValid );
	x6: entity work.serdesIn_1to8 port map('0', DISCR_OUT_1P, DISCR_OUT_1N, serdesIoClock_1, serdesStrobe_1, reset, serdesDivClock, '0', "00", discriminatorSerdes, open);	
	x7a: entity work.serdesOut_8to1 port map(serdesIoClock_2, serdesStrobe_2, reset, serdesDivClock, discriminatorSerdes(7 downto 0), LVDS_IO_P(5 downto 5), LVDS_IO_N(5 downto 5));
	x7b: entity work.serdesOut_8to1 port map(serdesIoClock_2, serdesStrobe_2, reset, serdesDivClock, discriminatorSerdes(15 downto 8), LVDS_IO_P(0 downto 0), LVDS_IO_N(0 downto 0));
	
	x8: entity work.triggerLogic generic map(8) port map(serdesDivClock, reset, discriminatorSerdes, trigger);
	x9: entity work.triggerDataDelay port map(discriminatorSerdes, discriminatorSerdesDelayed, triggerDataDelay0_r, triggerDataDelay0_w);
	
	x10: entity work.triggerTimeToRisingEdge generic map(8) port map(discriminatorSerdesDelayed, trigger, edgeData, edgeDataReady, triggerTimeToRisingEdge0_r, triggerTimeToRisingEdge0_w, triggerTiming);
	
	x12: entity work.pixelRateCounter port map(discriminatorSerdes, pixelRateCounter0_r, pixelRateCounter0_w);
	
	x11: entity work.eventFifoSystem port map(
		newEvent => trigger,
		triggerTiming => triggerTiming,
		dsr4Timing => dsr4Timing,
		dsr4Sampling => dsr4Sampling,
		dsr4Charge => dsr4Charge,
		registerRead => eventFifoSystem0_r,
		registerWrite => eventFifoSystem0_w
		);
	
	x1: entity work.smcBusCollector port map("not"(ebiNotChipSelect), ebiAddress, "not"(ebiNotRead), "not"(ebiNotWrite), asyncReset, asyncAddressAndControlBus);
	x2: entity work.smcBusEntry port map(serdesDivClock, asyncAddressAndControlBus, addressAndControlBus);
	x3: entity work.testRam_test port map(addressAndControlBus, ebiDataIn, ebiDataOut, 
		triggerTimeToRisingEdge0_r,
		triggerTimeToRisingEdge0_w,
		eventFifoSystem0_r,
		eventFifoSystem0_w,
		triggerDataDelay0_r,
		triggerDataDelay0_w,
		pixelRateCounter0_r,
		pixelRateCounter0_w
		);

end behaviour;
