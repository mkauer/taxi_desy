library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use work.types.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity drs4adc is
	generic(
		drs4_type : string := "INVALID";
		dummyImplementation : string := "FALSE"
	);
	port(
		address : out std_logic_vector(3 downto 0);
		
		notReset0 : out std_logic;
		denable0 : out std_logic;
		dwrite0 : out std_logic;
		rsrload0 : out std_logic;
		miso0 : in std_logic;
		mosi0 : out std_logic;
		srclk0 : out std_logic;
		dtap0 : in std_logic;
		plllck0 : in std_logic;
	
		deadTime : out std_logic;
		trigger : in std_logic; -- should be truly async later on
		internalTiming : in internalTiming_t;
		adcClocks : in adcClocks_t;
		--drs4_to_ltm9007_14 : out drs4_to_ltm9007_14_t;
		--drs4_to_eventFifoSystem : out drs4_to_eventFifoSystem_t;
		
		drs4_0r : out drs4_registerRead_t;
		drs4_0w : in drs4_registerWrite_t;	

		
		nCSA0 : out std_logic;
		nCSB0 : out std_logic;
		mosi : out std_logic;
		sclk : out std_logic;
		
		--enc_p0 : out std_logic;
		--enc_n0 : out std_logic;
		enc0 : out std_logic;
		adcDataA_p0 : in std_logic_vector(7 downto 0);
		adcDataA_n0 : in std_logic_vector(7 downto 0);
		
		--drs4_to_ltm9007_14 : in drs4_to_ltm9007_14_t;
		--ltm9007_14_to_eventFifoSystem : out ltm9007_14_to_eventFifoSystem_t;
		--adcClocks : in adcClocks_t;
		drs4AndAdcData : out drs4AndAdcData_t;
		
		registerRead : out ltm9007_14_registerRead_t;
		registerWrite : in ltm9007_14_registerWrite_t
	);
end entity;

architecture Behavioral of drs4adc is
	attribute keep : string;
	
	--signal address : std_logic_vector(3 downto 0);
	
	signal bitslipStart : std_logic;
	signal bitslipDone : std_logic; --_vector(2 downto 0);
	
	signal bitslipDone_TPTHRU_TIG : std_logic;
	attribute keep of bitslipDone_TPTHRU_TIG: signal is "true";
	
	signal bitslipStart_TPTHRU_TIG : std_logic;
	attribute keep of bitslipStart_TPTHRU_TIG: signal is "true";
	
	signal drs4_to_ltm9007_14 : drs4_to_ltm9007_14_t;

	signal drs4_to_eventFifoSystem : drs4_to_eventFifoSystem_t;
	signal ltm9007_14_to_eventFifoSystem : ltm9007_14_to_eventFifoSystem_t;

begin

	drs4AndAdcData.adcData <= ltm9007_14_to_eventFifoSystem;
	drs4AndAdcData.drs4Data <= drs4_to_eventFifoSystem;

	--h0: for i in 0 to 3 generate k: OBUF port map(O => address_p(i), I => address(i)); end generate;
	
	y0: entity work.drs4 --generic map(dummyImplementation => dummyImplementation);
		port map(address,
		notReset0, denable0, dwrite0, rsrload0, miso0, mosi0, srclk0, dtap0, plllck0,
		deadTime, trigger, internalTiming, adcClocks, drs4_to_ltm9007_14, drs4_to_eventFifoSystem, drs4_0r, drs4_0w);

--g1: if drs4_type = "ICE_SCINT" generate

	bitslipDone_TPTHRU_TIG <= bitslipDone;
	bitslipStart_TPTHRU_TIG <= bitslipStart;
	--yyy <= std_logic_TIG(bitslipStart);
	--l0: entity work.tig port map(bitslipStart, yyy);
	--temp <= std_logic_vector_TIG(bitslipDone); 

	--j0: OBUF port map(O => nCSA0, I => notChipSelectA);
	--j1: OBUF port map(O => nCSB0, I => notChipSelectB);
	
	y1: entity work.ltm9007_14_slowControl port map(
		registerWrite.clock, registerWrite.reset,
		nCSA0, nCSB0, mosi, sclk,
		registerWrite.init, bitslipDone_TPTHRU_TIG, bitslipStart, registerWrite.bitslipStart,
		LTM9007_14_BITSLIPPATTERN, registerWrite.testMode, registerWrite.testPattern);

	y2: entity work.ltm9007_14_adcData port map(
		--enc_p0, enc_n0, adcDataA_p0, adcDataA_n0,
		enc0, adcDataA_p0, adcDataA_n0,
		bitslipStart_TPTHRU_TIG, bitslipDone,
		drs4_to_ltm9007_14, ltm9007_14_to_eventFifoSystem, adcClocks, registerRead, registerWrite);

--end generate; 

end Behavioral;
