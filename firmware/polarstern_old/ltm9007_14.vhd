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
--library UNISIM;
--use UNISIM.VComponents.all;

entity ltm9007_14 is
	port(
		enc : out std_logic;
		adcDataA_p : in std_logic_vector(7 downto 0);
		adcDataA_n : in std_logic_vector(7 downto 0);
		
		frameA_p : in std_logic;
		frameA_n : in std_logic;
		frameB_p : in std_logic;
		frameB_n : in std_logic;
		dataClockA_p : in std_logic;
		dataClockA_n : in std_logic;
		dataClockB_p : in std_logic;
		dataClockB_n : in std_logic;
			
		notChipSelectA : out std_logic;
		notChipSelectB : out std_logic;
		mosi : out std_logic;
		sclk : out std_logic;
		
		adcDataValid : in std_logic;

		drs4Clocks : in drs4Clocks_t;
		drs4Fifo : out drs4Fifo_t;
		
		registerRead : out ltm9007_14_registerRead_t;
		registerWrite : in ltm9007_14_registerWrite_t	
	);
end ltm9007_14;

architecture Behavioral of ltm9007_14 is
	signal ioClockA_p : std_logic := '0';
	signal ioClockA_n : std_logic := '0';
	signal ioClockB_p : std_logic := '0';
	signal ioClockB_n : std_logic := '0';
	signal serdesStrobeA : std_logic := '0';
	signal serdesStrobeB : std_logic := '0';
	signal serdesDivClockA : std_logic := '0';
	signal serdesDivClockB : std_logic := '0';
	signal frameOutGroupA : std_logic_vector(7-1 downto 0) := (others=>'0');
	signal frameOutGroupB : std_logic_vector(7-1 downto 0) := (others=>'0');
	signal dataOutGroupA : std_logic_vector(7*4-1 downto 0) := (others=>'0');
	signal dataOutGroupB : std_logic_vector(7*4-1 downto 0) := (others=>'0');
	signal adcDataGroupA_p : std_logic_vector(3 downto 0) := (others=>'0');
	signal adcDataGroupA_n : std_logic_vector(3 downto 0) := (others=>'0');
	signal adcDataGroupB_p : std_logic_vector(3 downto 0) := (others=>'0');
	signal adcDataGroupB_n : std_logic_vector(3 downto 0) := (others=>'0');
	signal dataOutGroupA_buffer : std_logic_vector(14*4-1 downto 0) := (others=>'0');
	signal dataOutGroupB_buffer : std_logic_vector(14*4-1 downto 0) := (others=>'0');

	signal fifoWriteEnableA : std_logic := '0';
	signal fifoWriteEnableB : std_logic := '0';
	signal fifoReadEnableA : std_logic := '0';
	signal fifoReadEnableB : std_logic := '0';
	signal fifoResetA : std_logic := '0';
	signal fifoResetB : std_logic := '0';

	signal eventFifoFullA_old : std_logic := '0';
	signal eventFifoOverflowA_old : std_logic := '0';
	signal eventFifoUnderflowA_old : std_logic := '0';
	signal eventFifoOverflowCounterA : unsigned(15 downto 0) := (others=>'0');
	signal eventFifoUnderflowCounterA : unsigned(15 downto 0) := (others=>'0');
	signal eventFifoFullCounterA : unsigned(15 downto 0) := (others=>'0');
	
begin
	
	adcDataGroupA_p <= adcDataA_p(6) & adcDataA_p(4) & adcDataA_p(2) & adcDataA_p(0);
	adcDataGroupA_n <= adcDataA_n(6) & adcDataA_n(4) & adcDataA_n(2) & adcDataA_n(0);
	adcDataGroupB_p <= adcDataB_p(7) & adcDataB_p(5) & adcDataB_p(3) & adcDataB_p(1);
	adcDataGroupB_n <= adcDataB_n(7) & adcDataB_n(5) & adcDataB_n(3) & adcDataB_n(1);
	

	x100: entity work.serdes_1_to_n_clk_ddr_s8_diff generic map(7, false) port map(dataClockA_p, dataClockA_n, ioClockA_p, ioClockA_n, serdesStrobeA, serdesDivClockA);
	x101: entity work.serdes_1_to_n_data_ddr_s8_diff generic map(7,4,false,"PER_CHANL") port map('1', adcDataGroupA_p, adcDataGroupA_n, ioClockA_p, ioClockA_n, serdesStrobeA, reset, serdesDivClockA, '0', dataOutGroupA, "00", open);
	x102: entity work.serdes_1_to_n_data_ddr_s8_diff generic map(7,1,false,"PER_CHANL") port map('1', frameA_p, frameA_n, ioClockA_p, ioClockA_n, serdesStrobeA, reset, serdesDivClockA, '0', frameOutGroupA, "00", open);

	x104: entity work.serdes_1_to_n_clk_ddr_s8_diff generic map(7, false) port map(dataClockB_p, dataClockB_n, ioClockB_p, ioClockB_n, serdesStrobeB, serdesDivClockB);
	x105: entity work.serdes_1_to_n_data_ddr_s8_diff generic map(7,4,false,"PER_CHANL") port map('1', adcDataGroupB_p, adcDataGroupB_n, ioClockB_p, ioClockB_n, serdesStrobeB, reset, serdesDivClockB, '0', dataOutGroupB, "00", open);
	x106: entity work.serdes_1_to_n_data_ddr_s8_diff generic map(7,1,false,"PER_CHANL") port map('1', frameB_p, frameB_n, ioClockA_p, ioClockA_n, serdesStrobeA, reset, serdesDivClockA, '0', frameOutGroupB, "00", open);

	x108: entity work.drs4FrontEndFifo port map(
    rst => fifoResetA,
    wr_clk => serdesDivClockA,
    rd_clk => registerWrite.clock,
    din => dataOutGroupA_buffer,
    wr_en => fifoWriteEnableA,
    rd_en => fifoReadEnableA,
    dout => drs4Fifo.fifoOutA,
    full => eventFifoFullA,
    overflow => eventFifoOverflowA,
    empty => open,
    valid => open,
    underflow => eventFifoUnderflowA,
    rd_data_count => drs4Fifo.fifoWordsA,
    wr_data_count => open
  );


P0:process (serdesDivClockA) -- ~66 MHz
begin
	if rising_edge(serdesDivClockA) then
		fifoWriteEnableA <= '0'; -- autoreset
		if (registerWrite.reset = '1') then -- ## sync?!
			state5 <= sync1;
		else
						
			case state5 is				
				when sync1 =>
					-- set testbytes in adc ?!
					-- find start of values ?!
					-- use frame to pahseshift
					fifoResetA <= '1';
					state5 <= sync2;
					
				when sync2 =>
					-- timeout for fifo reset...
					state5 <= sample1;
				
				when sample1 =>
					state5 <= sample2;
					dataOutGroupA_buffer(14*4-1 downto 14*2) <= dataOutGroupA;	
					
				when sample2 =>
					state5 <= sample1;
					dataOutGroupA_buffer(14*2-1 downto 0) <= dataOutGroupA;
					fifoWriteEnableA <= adcDataValid; -- autoreset		
					
				when others => null;
			end case;
			
		end if;
	end if;
end process P0;

P4:process (registerWrite.clock)
begin
	if rising_edge(registerWrite.clock) then
		if (registerWrite.reset = '1') then
			eventFifoFullCounterA <= to_unsigned(0,eventFifoFullCounterA'length);
			eventFifoOverflowCounterA <= to_unsigned(0,eventFifoOverflowCounterA'length);
			eventFifoUnderflowCounterA <= to_unsigned(0,eventFifoUnderflowCounterA'length);
			eventFifoOverflowA_old <= '0';
			eventFifoUnderflowA_old <= '0';
			eventFifoFullA_old <= '0';
		else
		
			eventFifoOverflowA_old <= eventFifoOverflowA;
			eventFifoUnderflowA_old <= eventFifoUnderflowA;
			eventFifoFullA_old <= eventFifoFullA;
			
			if((eventFifoOverflowA_old = '0') and (eventFifoOverflowA = '1')) then
				eventFifoOverflowCounterA <= eventFifoOverflowCounterA + 1;
			end if;
			
			if((eventFifoUnderflowA_old = '0') and (eventFifoUnderflowA = '1')) then
				eventFifoUnderflowCounterA <= eventFifoUnderflowCounterA + 1;
			end if;
			
			if((eventFifoFullA_old = '0') and (eventFifoFullA = '1')) then
				eventFifoFullCounterA <= eventFifoFullCounterA + 1;
			end if;
			
		end if;
	end if;
end process P4;

end Behavioral;

