-------------------------------------------------------
-- Design Name      : taxi_003_top
-- File Name        : taxi_003_top.vhd
-- Device           : Spartan 6, XC6SLX45FGG484-2
-- Migration Device : Spartan 6, XC6SLX100FGG484-2
-- Function         : taxi top level test design rev-005
-- Coder(s)         : K.-H. Sulanke & S. Kunwar & M. Kossatz, DESY, 2016
-------------------------------------------------------
-- compiling duration = min
-- QOSC1_OUT, 25 MHz, 3.3V CMOS 2.5 ppm

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.types.all;
use work.types_platformSpecific.all;

library unisim;
use unisim.vcomponents.all;

entity taxiTop is
	port
	(
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
		DISCR_OUT_1P  : in std_logic_vector(7 downto 0); -- LVDS, discriminator inputs
		DISCR_OUT_1N  : in std_logic_vector(7 downto 0);
	--DISCR_OUT_2P  : in std_logic_vector(7 downto 0); -- LVDS, discriminator inputs
	--DISCR_OUT_2N  : in std_logic_vector(7 downto 0);
	--DISCR_OUT_3P  : in std_logic_vector(7 downto 0); -- LVDS, discriminator inputs
	--DISCR_OUT_1N  : in std_logic_vector(7 downto 0);

		NOT_USED_GND  : out std_logic_vector(7 downto 0);
		PANEL_NP24V_ON  : out std_logic_vector(7 downto 0);
		PANEL_RS485_D : inout std_logic_vector(7 downto 0);
		PANEL_RS485_DE : out std_logic_vector(7 downto 0);

		-- trigger to be used by the AERA board
		AERA_TRIG_P   : out std_logic;    -- LVDS
		AERA_TRIG_N   : out std_logic;    -- LVDS

		-- ADC #1..3, LTM9007-14, 8 channel, ser out, 40 MSPS max., LVDS outputs
		-- the direction used for the pins is (0 to 7) but will be assigned to a (7 downto 0)
		-- we do this to compensate the non logical order in the pcb
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
		ADC_PAR_SERn : out std_logic; -- Incorrect signal removed completely from design. This Should be tied to ground.
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

		TEMPERATURE    : inout std_logic;    -- bidir, tmp05 sensor

		-- test signals, NOT AVAILABLE for XC6SLX100FGG484-2 !!!
		LVDS_IO_P    : inout std_logic_vector(5 downto 0); -- LVDS bidir. test port
		LVDS_IO_N    : inout std_logic_vector(5 downto 0)  -- LVDS bidir. test port
		--LVDS_IN_P    : in std_logic_vector(5 downto 5) -- LVDS bidir. test port
	);
end taxiTop;

architecture behaviour of taxiTop is
	
	signal NOT_USED_GND : std_logic_vector(7 downto 0);
	signal PANEL_NP24V_ON : std_logic_vector(7 downto 0);

begin

	PANEL_NP24V_ON(0) <= DISCR_OUT_2N(6);
	PANEL_NP24V_ON(1) <= DISCR_OUT_2N(4);
	PANEL_NP24V_ON(2) <= DISCR_OUT_2N(2);
	PANEL_NP24V_ON(3) <= DISCR_OUT_2N(0);
	PANEL_NP24V_ON(4) <= DISCR_OUT_3N(6);
	PANEL_NP24V_ON(5) <= DISCR_OUT_3N(4);
	PANEL_NP24V_ON(6) <= DISCR_OUT_3N(2);
	PANEL_NP24V_ON(7) <= DISCR_OUT_3N(0);
	
	NOT_USED_GND(0) <= DISCR_OUT_2P(0);
	NOT_USED_GND(1) <= DISCR_OUT_2P(2);
	NOT_USED_GND(2) <= DISCR_OUT_2P(4);
	NOT_USED_GND(3) <= DISCR_OUT_2P(6);
	NOT_USED_GND(4) <= DISCR_OUT_3P(0);
	NOT_USED_GND(5) <= DISCR_OUT_3P(2);
	NOT_USED_GND(6) <= DISCR_OUT_3P(4);
	NOT_USED_GND(7) <= DISCR_OUT_3P(6);

	NOT_USED_GND  : out std_logic_vector(7 downto 0);
	PANEL_NP24V_ON  : out std_logic_vector(7 downto 0);
	PANEL_RS485_D : inout std_logic_vector(7 downto 0);
	PANEL_RS485_DE : out std_logic_vector(7 downto 0);

	g0: if SYSTEM_TYPE = TAXI_ICE_SCINT generate
	taxiTop_iceScint_1: entity work.taxiTop_iceScint
    port map (
      PON_RESETn      => PON_RESETn,
      QOSC1_OUT       => QOSC1_OUT,
      QOSC1_DAC_SYNCn => QOSC1_DAC_SYNCn,
      QOSC2_OUT       => QOSC2_OUT,
      QOSC2_ENA       => QOSC2_ENA,
      QOSC2_DAC_SYNCn => QOSC2_DAC_SYNCn,
      QOSC2_DAC_SCKL  => QOSC2_DAC_SCKL,
      QOSC2_DAC_SDIN  => QOSC2_DAC_SDIN,
      EXT_CLK_P       => EXT_CLK_P,
      EXT_CLK_N       => EXT_CLK_N,
      EXT_PPS_P       => EXT_PPS_P,
      EXT_PPS_N       => EXT_PPS_N,
      EXT_TRIG_OUT_P  => EXT_TRIG_OUT_P,
      EXT_TRIG_OUT_N  => EXT_TRIG_OUT_N,
      EXT_TRIG_IN_P   => EXT_TRIG_IN_P,
      EXT_TRIG_IN_N   => EXT_TRIG_IN_N,
      DISCR_OUT_1P    => DISCR_OUT_1P,
      DISCR_OUT_1N    => DISCR_OUT_1N,
      NOT_USED_GND    => NOT_USED_GND,
      PANEL_NP24V_ON  => PANEL_NP24V_ON,
      PANEL_RS485_D   => PANEL_RS485_D,
      PANEL_RS485_DE  => PANEL_RS485_DE,
      AERA_TRIG_P     => AERA_TRIG_P,
      AERA_TRIG_N     => AERA_TRIG_N,
      ADC_OUTA_1P     => ADC_OUTA_1P,
      ADC_OUTA_1N     => ADC_OUTA_1N,
      ADC_OUTA_2P     => ADC_OUTA_2P,
      ADC_OUTA_2N     => ADC_OUTA_2N,
      ADC_OUTA_3P     => ADC_OUTA_3P,
      ADC_OUTA_3N     => ADC_OUTA_3N,
      ADC_FRA_P       => ADC_FRA_P,
      ADC_FRA_N       => ADC_FRA_N,
      ADC_FRB_P       => ADC_FRB_P,
      ADC_FRB_N       => ADC_FRB_N,
      ADC_DCOA_P      => ADC_DCOA_P,
      ADC_DCOA_N      => ADC_DCOA_N,
      ADC_DCOB_P      => ADC_DCOB_P,
      ADC_DCOB_N      => ADC_DCOB_N,
      ADC_ENC_P       => ADC_ENC_P,
      ADC_ENC_N       => ADC_ENC_N,
      ADC_PAR_SERn    => ADC_PAR_SERn,
      ADC_SDI         => ADC_SDI,
      ADC_SCK         => ADC_SCK,
      ADC_CSA         => ADC_CSA,
      ADC_CSB         => ADC_CSB,
      ADC_OUTA_4P     => ADC_OUTA_4P,
      ADC_OUTA_4N     => ADC_OUTA_4N,
      ADC_FR_4P       => ADC_FR_4P,
      ADC_FR_4N       => ADC_FR_4N,
      ADC_DCO_4P      => ADC_DCO_4P,
      ADC_DCO_4N      => ADC_DCO_4N,
      ADC_ENC_4P      => ADC_ENC_4P,
      ADC_ENC_4N      => ADC_ENC_4N,
      ADC_CS_4        => ADC_CS_4,
      ADC_SDO_4       => ADC_SDO_4,
      EBI1_ADDR       => EBI1_ADDR,
      EBI1_D          => EBI1_D,
      EBI1_NWE        => EBI1_NWE,
      EBI1_NCS2       => EBI1_NCS2,
      EBI1_NRD        => EBI1_NRD,
      EBI1_MCK        => EBI1_MCK,
      EBI1_NWAIT      => EBI1_NWAIT,
      PC1_ARM_IRQ0    => PC1_ARM_IRQ0,
      ADDR_64BIT      => ADDR_64BIT,
      DRS4_SROUT      => DRS4_SROUT,
      DRS4_DTAP       => DRS4_DTAP,
      DRS4_PLLLCK     => DRS4_PLLLCK,
      DRS4_RESETn     => DRS4_RESETn,
      DRS4_A          => DRS4_A,
      DRS4_SRIN       => DRS4_SRIN,
      DRS4_SRCLK      => DRS4_SRCLK,
      DRS4_RSLOAD     => DRS4_RSLOAD,
      DRS4_DWRITE     => DRS4_DWRITE,
      DRS4_DENABLE    => DRS4_DENABLE,
      DRS4_REFCLK_P   => DRS4_REFCLK_P,
      DRS4_REFCLK_N   => DRS4_REFCLK_N,
      DAC_DIN         => DAC_DIN,
      DAC_SCLK        => DAC_SCLK,
      DAC_SYNCn       => DAC_SYNCn,
      I2C_CLK         => I2C_CLK,
      I2C_DATA        => I2C_DATA,
      CBL_PLGDn       => CBL_PLGDn,
      PON_PADDLEn     => PON_PADDLEn,
      POW_SW_SCL      => POW_SW_SCL,
      POW_SW_SDA      => POW_SW_SDA,
      POW_ALERT       => POW_ALERT,
      RS232_TXD       => RS232_TXD,
      RS232_RXD       => RS232_RXD,
      RS485_PV        => RS485_PV,
      RS485_DE        => RS485_DE,
      RS485_REn       => RS485_REn,
      RS485_TXD       => RS485_TXD,
      RS485_RXD       => RS485_RXD,
      GPS_RESET_N     => GPS_RESET_N,
      GPS_EXTINT0     => GPS_EXTINT0,
      GPS_TIMEPULSE   => GPS_TIMEPULSE,
      GPS_TIMEPULSE2  => GPS_TIMEPULSE2,
      GPS_RXD1        => GPS_RXD1,
      GPS_TXD1        => GPS_TXD1,
      TEST_DAC_SCL    => TEST_DAC_SCL,
      TEST_DAC_SDA    => TEST_DAC_SDA,
      TEST_GATE       => TEST_GATE,
      TEST_PDn        => TEST_PDn,
      TEMPERATURE     => TEMPERATURE,
      LVDS_IO_P       => LVDS_IO_P,
      LVDS_IO_N       => LVDS_IO_N);

	end generate;

end behaviour;
