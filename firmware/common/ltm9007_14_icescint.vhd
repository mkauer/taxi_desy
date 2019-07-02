----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:18:20 03/27/2017 
-- Design Name: 
-- Module Name:    ltm9007_14 - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use work.types.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity ltm9007_14_icescint is
	generic(
		drs4_type : string := "INVALID"
	);
	port(
		enc_p0 : out std_logic;
		enc_n0 : out std_logic;
		adcDataA_p0 : in std_logic_vector(7 downto 0);
		adcDataA_n0 : in std_logic_vector(7 downto 0);
		nCSA0 : out std_logic;
		nCSB0 : out std_logic;
		
		enc_p1 : out std_logic;
		enc_n1 : out std_logic;
		adcDataA_p1 : in std_logic_vector(7 downto 0);
		adcDataA_n1 : in std_logic_vector(7 downto 0);
		nCSA1 : out std_logic;
		nCSB1 : out std_logic;
		
		enc_p2 : out std_logic;
		enc_n2 : out std_logic;
		adcDataA_p2 : in std_logic_vector(7 downto 0);
		adcDataA_n2 : in std_logic_vector(7 downto 0);
		nCSA2 : out std_logic;
		nCSB2 : out std_logic;
		
		mosi : out std_logic;
		sclk : out std_logic;
		
		drs4_to_ltm9007_14 : in drs4_to_ltm9007_14_t;
		--drs4_to_ltm9007_14 : in drs4_registerRead_vector_t;
		ltm9007_14_to_eventFifoSystem : out ltm9007_14_to_eventFifoSystem_t;
		adcClocks : in adcClocks_t;
		
		registerRead : out ltm9007_14_registerRead_t;
		registerWrite : in ltm9007_14_registerWrite_t	
	);
end entity;

architecture Behavioral of ltm9007_14_icescint is
	attribute keep : string;
		
	signal bitslipStart : std_logic;
	signal bitslipDone : std_logic_vector(2 downto 0);
--	signal temp : std_logic_vector(2 downto 0);

	signal ltm9007_14_to_eventFifoSystem_0 : ltm9007_14_to_eventFifoSystem_t;
	signal ltm9007_14_to_eventFifoSystem_1 : ltm9007_14_to_eventFifoSystem_t;
	signal ltm9007_14_to_eventFifoSystem_2 : ltm9007_14_to_eventFifoSystem_t;

	signal registerRead_0 : ltm9007_14_registerRead_t;
	signal registerRead_1 : ltm9007_14_registerRead_t;
	signal registerRead_2 : ltm9007_14_registerRead_t;
	
	signal bitslipDone_TPTHRU_TIG : std_logic;
	attribute keep of bitslipDone_TPTHRU_TIG: signal is "true";
	
	signal bitslipStart_TPTHRU_TIG : std_logic;
	attribute keep of bitslipStart_TPTHRU_TIG: signal is "true";
	
	signal notChipSelectA : std_logic; --_vector(2 downto 0);
	signal notChipSelectB : std_logic; --_vector(2 downto 0);

begin
--(ICE_SCINT, UV_LOGGER, ICE_SCINT_RADIO, INVALID);

g0: if drs4_type = "INVALID" generate
	assert 1=2 report "drs4_type invalid" severity error;
end generate;

g1a: if drs4_type = "UV_LOGGER" generate
	
	bitslipDone_TPTHRU_TIG <= bitslipDone(0);
	bitslipStart_TPTHRU_TIG <= bitslipStart;
	--yyy <= std_logic_TIG(bitslipStart);
	--l0: entity work.tig port map(bitslipStart, yyy);
	--temp <= std_logic_vector_TIG(bitslipDone); 

	registerRead <= registerRead_0;
	ltm9007_14_to_eventFifoSystem <= ltm9007_14_to_eventFifoSystem_0;

	j0: OBUF port map(O => nCSA0, I => notChipSelectA);
	j1: OBUF port map(O => nCSB0, I => notChipSelectB);
	
	y0: entity work.ltm9007_14_slowControl port map(
		registerWrite.clock, registerWrite.reset,
		notChipSelectA, notChipSelectB, mosi, sclk,
		registerWrite.init, bitslipDone_TPTHRU_TIG, bitslipStart, registerWrite.bitslipStart,
		LTM9007_14_BITSLIPPATTERN, registerWrite.testMode, registerWrite.testPattern);

	y1: entity work.ltm9007_14_adcData port map(
		enc_p0, enc_n0, adcDataA_p0, adcDataA_n0,
		bitslipStart_TPTHRU_TIG, bitslipDone(0),
		drs4_to_ltm9007_14, ltm9007_14_to_eventFifoSystem_0, adcClocks, registerRead_0, registerWrite);
end generate; 

g1: if drs4_type = "ICE_SCINT" generate
	
	s1: for i in 0 to 7 generate
		i1: IBUFDS generic map(DIFF_TERM => true) port map (I => adcDataA_p1(i), IB => adcDataA_n1(i), O => open);
		i2: IBUFDS generic map(DIFF_TERM => true) port map (I => adcDataA_p2(i), IB => adcDataA_n2(i), O => open);
	end generate;
	i1: OBUFDS port map(O => enc_p1, OB => enc_n1, I => '0');
	i2: OBUFDS port map(O => enc_p2, OB => enc_n2, I => '0');

	bitslipDone_TPTHRU_TIG <= bitslipDone(0);
	bitslipStart_TPTHRU_TIG <= bitslipStart;
	--yyy <= std_logic_TIG(bitslipStart);
	--l0: entity work.tig port map(bitslipStart, yyy);
	--temp <= std_logic_vector_TIG(bitslipDone); 

	registerRead <= registerRead_0;
	ltm9007_14_to_eventFifoSystem <= ltm9007_14_to_eventFifoSystem_0;

	j0: OBUF port map(O => nCSA0, I => notChipSelectA);
	j1: OBUF port map(O => nCSB0, I => notChipSelectB);
	j2: OBUF port map(O => nCSA1, I => '0');
	j3: OBUF port map(O => nCSB1, I => '0');
	j4: OBUF port map(O => nCSA2, I => '0');
	j5: OBUF port map(O => nCSB2, I => '0');
	
	y0: entity work.ltm9007_14_slowControl port map(
		registerWrite.clock, registerWrite.reset,
		notChipSelectA, notChipSelectB, mosi, sclk,
		registerWrite.init, bitslipDone_TPTHRU_TIG, bitslipStart, registerWrite.bitslipStart,
		LTM9007_14_BITSLIPPATTERN, registerWrite.testMode, registerWrite.testPattern);

	y1: entity work.ltm9007_14_adcData port map(
		enc_p0, enc_n0, adcDataA_p0, adcDataA_n0,
		bitslipStart_TPTHRU_TIG, bitslipDone(0),
		drs4_to_ltm9007_14, ltm9007_14_to_eventFifoSystem_0, adcClocks, registerRead_0, registerWrite);
end generate; 

g2: if drs4_type = "ICE_SCINT_RADIO" generate
	bitslipDone_TPTHRU_TIG <= bitslipDone(0) and bitslipDone(1) and bitslipDone(2);
	bitslipStart_TPTHRU_TIG <= bitslipStart;
	--yyy <= std_logic_TIG(bitslipStart);
	--l0: entity work.tig port map(bitslipStart, yyy);
	--temp <= std_logic_vector_TIG(bitslipDone); 

	registerRead <= registerRead_0;
	ltm9007_14_to_eventFifoSystem <= ltm9007_14_to_eventFifoSystem_0;
	
	j0: OBUF port map(O => nCSA0, I => notChipSelectA);
	j1: OBUF port map(O => nCSB0, I => notChipSelectB);
	j2: OBUF port map(O => nCSA1, I => notChipSelectA);
	j3: OBUF port map(O => nCSB1, I => notChipSelectB);
	j4: OBUF port map(O => nCSA2, I => notChipSelectA);
	j5: OBUF port map(O => nCSB2, I => notChipSelectB);
	
	y0: entity work.ltm9007_14_slowControl port map(
		registerWrite.clock, registerWrite.reset,
		notChipSelectA, notChipSelectB, mosi, sclk,
		registerWrite.init, bitslipDone_TPTHRU_TIG, bitslipStart, registerWrite.bitslipStart,
		LTM9007_14_BITSLIPPATTERN, registerWrite.testMode, registerWrite.testPattern);

	y1: entity work.ltm9007_14_adcData port map(
		enc_p0, enc_n0, adcDataA_p0, adcDataA_n0,
		bitslipStart_TPTHRU_TIG, bitslipDone(0),
		drs4_to_ltm9007_14, ltm9007_14_to_eventFifoSystem_0, adcClocks, registerRead_0, registerWrite);

	y2: entity work.ltm9007_14_adcData port map(
		enc_p1, enc_n1, adcDataA_p1, adcDataA_n1,
		bitslipStart_TPTHRU_TIG, bitslipDone(1),
		drs4_to_ltm9007_14, ltm9007_14_to_eventFifoSystem_1, adcClocks, registerRead_1, registerWrite);
	
	y3: entity work.ltm9007_14_adcData port map(
		enc_p2, enc_n2, adcDataA_p2, adcDataA_n2,
		bitslipStart_TPTHRU_TIG, bitslipDone(2),
		drs4_to_ltm9007_14, ltm9007_14_to_eventFifoSystem_2, adcClocks, registerRead_1, registerWrite);
end generate; 

end Behavioral;

