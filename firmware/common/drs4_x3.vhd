----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:59:02 03/27/2017 
-- Design Name: 
-- Module Name:    drs4 - Behavioral 
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
--library UNISIM;
--use UNISIM.VComponents.all;

entity drs4_x3 is
	generic(
		drs4_type : string := "INVALID"
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
		--drs4_to_ltm9007_14_0 : out drs4_to_ltm9007_14_t;

		notReset1 : out std_logic;
		denable1 : out std_logic;
		dwrite1 : out std_logic;
		rsrload1 : out std_logic;
		miso1 : in std_logic;
		mosi1 : out std_logic;
		srclk1 : out std_logic;
		dtap1 : in std_logic;
		plllck1 : in std_logic;
		--drs4_to_ltm9007_14_1 : out drs4_to_ltm9007_14_t;

		notReset2 : out std_logic;
		denable2 : out std_logic;
		dwrite2 : out std_logic;
		rsrload2 : out std_logic;
		miso2 : in std_logic;
		mosi2 : out std_logic;
		srclk2 : out std_logic;
		dtap2 : in std_logic;
		plllck2 : in std_logic;
		--drs4_to_ltm9007_14_2 : out drs4_to_ltm9007_14_t;
		
		deadTime : out std_logic;
		trigger : in std_logic; -- should be truly async later on
		internalTiming : in internalTiming_t;
		adcClocks : in adcClocks_t;
		drs4_to_ltm9007_14 : out drs4_to_ltm9007_14_vector_t;
		drs4_to_eventFifoSystem : out drs4_to_eventFifoSystem_vector_t;
		
		registerRead : out drs4_registerRead_t;
		registerWrite : in drs4_registerWrite_t	
	);
end entity;

architecture Behavioral of drs4_x3 is
	signal drs4_to_ltm9007_14_0 : drs4_to_ltm9007_14_t;
	signal drs4_to_ltm9007_14_1 : drs4_to_ltm9007_14_t;
	signal drs4_to_ltm9007_14_2 : drs4_to_ltm9007_14_t;
	--signal address : std_logic_vector(address_p'range);

	signal notReset : std_logic;
	signal denable : std_logic;
	signal dwrite : std_logic;
	signal rsrload : std_logic;
	signal mosi : std_logic;
	signal miso : std_logic;
	signal srclk : std_logic;
	signal dtap : std_logic;
	signal plllck : std_logic;

begin

	h0: for i in 0 to 3 generate k: OBUF port map(O => address_p(i), I => address(i)); end generate;


g0: if drs4_type = "INVALID" generate
	assert 1=2 report "drs4_type invalid" severity error;
end generate;

g1: if (drs4_type = "one_channel") generate
	y0: entity work.drs4 port map(address,
		notReset0, denable0, dwrite0, dwriteSerdes0, rsrload0, miso0, mosi0, srclk0, dtap0, plllck0,
		deadTime, triggerDRS4, internalTiming, adcClocks, drs4_to_ltm9007_14(0), drs4_to_eventFifoSystem(0), drs4_0r, drs4_0w);
	
	z10: OBUF port map(O => notReset1, I => '0');
	z11: OBUF port map(O => denable1, I => '0');
	z12: OBUF port map(O => dwrite1, I => '0');
	z13: OBUF port map(O => rsrload1, I => '0');
	z14: OBUF port map(O => mosi1, I => '0');
	z15: IBUF port map(I => miso1, O => open);
	z16: OBUF port map(O => srclk1, I => '0');
	z17: IBUF port map(I => dtap1, O => open);
	z18: IBUF port map(I => plllck1, O => open);
	
	z20: OBUF port map(O => notReset2, I => '0');
	z21: OBUF port map(O => denable2, I => '0');
	z22: OBUF port map(O => dwrite2, I => '0');
	z23: OBUF port map(O => rsrload2, I => '0');
	z24: OBUF port map(O => mosi2, I => '0');
	z25: IBUF port map(I => miso2, O => open);
	z26: OBUF port map(O => srclk2, I => '0');
	z27: IBUF port map(I => dtap2, O => open);
	z28: IBUF port map(I => plllck2, O => open);
end generate;
	

g2: if drs4_type = "three_channel" generate
	y1a: entity work.drs4 port map(address,
		notReset0, denable0, dwrite0, dwriteSerdes0, rsrload0, miso0, mosi0, srclk0, dtap0, plllck0,
		deadTime, triggerDRS4, internalTiming, adcClocks, drs4_to_ltm9007_14(0), drs4_to_eventFifoSystem(0), drs4_0r, drs4_0w);
	y1b: entity work.drs4 port map(open,
		notReset1, denable1, dwrite1, dwriteSerdes1, rsrload1, miso1, mosi1, srclk1, dtap1, plllck1,
		deadTime, triggerDRS4, internalTiming, adcClocks, drs4_to_ltm9007_14(1), drs4_to_eventFifoSystem(1), open, drs4_0w);
	y1c: entity work.drs4 port map(open,
		notReset2, denable2, dwrite2, dwriteSerdes2, rsrload2, miso2, mosi2, srclk2, dtap2, plllck2,
		deadTime, triggerDRS4, internalTiming, adcClocks, drs4_to_ltm9007_14(2), drs4_to_eventFifoSystem(2), open, drs4_0w);

end generate;


end Behavioral;

