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

entity ltm9007_14 is
	port(
		enc_p : out std_logic;
		enc_n : out std_logic;
		adcDataA_p : in std_logic_vector(7 downto 0);
		adcDataA_n : in std_logic_vector(7 downto 0);
		
		frameA_p : in std_logic_vector(0 downto 0);
		frameA_n : in std_logic_vector(0 downto 0);
		frameB_p : in std_logic_vector(0 downto 0);
		frameB_n : in std_logic_vector(0 downto 0);
		--dataClockA_p : in std_logic;
		--dataClockA_n : in std_logic;
		--dataClockB_p : in std_logic;
		--dataClockB_n : in std_logic;
			
		notChipSelectA : out std_logic;
		notChipSelectB : out std_logic;
		mosi : out std_logic;
		sclk : out std_logic;
		
		drs4_to_ltm9007_14 : in drs4_to_ltm9007_14_t;
		--adcDataValid : in std_logic;

		drs4Clocks : in drs4Clocks_t;
		adcFifo : out adcFifo_t;
		ltm9007_14_to_eventFifoSystem : out ltm9007_14_to_eventFifoSystem_t;
		
		adcClocks : in adcClocks_t;
		
		registerRead : out ltm9007_14_registerRead_t;
		registerWrite : in ltm9007_14_registerWrite_t	
	);
end ltm9007_14;

architecture Behavioral of ltm9007_14 is
	signal ioClockA_p : std_logic := '0';
	signal ioClockA_n : std_logic := '0';
	signal ioClockB_p : std_logic := '0';
	signal ioClockB_n : std_logic := '0';
	--signal serdesStrobeA : std_logic := '0';
	--signal serdesStrobeB : std_logic := '0';
	--signal serdesDivClockA : std_logic := '0';
	--signal serdesDivClockB : std_logic := '0';
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
	signal fifoOutA : std_logic_vector(14*4-1 downto 0) := (others=>'0');
	signal fifoOutB : std_logic_vector(14*4-1 downto 0) := (others=>'0');
	signal fifoWordsA : std_logic_vector(4 downto 0) := (others=>'0');
	signal fifoWordsB : std_logic_vector(4 downto 0) := (others=>'0');
	signal fifoReadClock : std_logic := '0';
	signal enc : std_logic := '0';
	signal reset : std_logic := '0';
	
	type stateAdcFifoData_t is (idle, skip, valid1, valid2);
	signal stateAdcFifoData : stateAdcFifoData_t := idle;
	type stateAdcFifo_t is (sync1, sync2, sample1, sample2);
	signal stateAdcFifo : stateAdcFifo_t := sync1;

	signal fifoWriteEnableA : std_logic := '0';
	signal fifoWriteEnableB : std_logic := '0';
	signal fifoReadEnableA : std_logic := '0';
	signal fifoReadEnableB : std_logic := '0';
	signal fifoResetA : std_logic := '0';
	signal fifoResetB : std_logic := '0';
	
	signal fifoEmptyA : std_logic := '0';
	signal fifoEmptyB : std_logic := '0';
	signal fifoValidA : std_logic := '0';
	signal fifoValidB : std_logic := '0';

	signal eventFifoOverflowA : std_logic := '0';
	signal eventFifoOverflowB : std_logic := '0';
	signal eventFifoUnderflowA : std_logic := '0';
	signal eventFifoUnderflowB : std_logic := '0';
	signal eventFifoFullA : std_logic := '0';
	signal eventFifoFullB : std_logic := '0';
	
	signal eventFifoFullA_old : std_logic := '0';
	signal eventFifoOverflowA_old : std_logic := '0';
	signal eventFifoUnderflowA_old : std_logic := '0';
	signal eventFifoOverflowCounterA : unsigned(15 downto 0) := (others=>'0');
	signal eventFifoUnderflowCounterA : unsigned(15 downto 0) := (others=>'0');
	signal eventFifoFullCounterA : unsigned(15 downto 0) := (others=>'0');

	constant spiNumberOfBits : integer := 8;
	constant sclkDivisor : unsigned(3 downto 0) := x"3"; -- ((systemClock / spiClock) / 2) ... 2=~29.7MHz@118.75MHz
	constant sclkDefaultLevel : std_logic := '0';
	constant mosiDefaultLevel : std_logic := '0';
	signal spiBusy : std_logic := '0';
	signal spiTransfer : std_logic := '0';
	signal spiTransfer_old : std_logic := '0';
	signal spiCounter : integer range 0 to spiNumberOfBits := 0;
	signal sclkDivisorCounter : unsigned (3 downto 0) := x"0";
	signal sclk_i : std_logic := '0';
	signal sclkEnable : std_logic := '0';
	signal sclkEdgeRising : std_logic := '0';
	signal sclkEdgeFalling : std_logic := '0';
	signal txBuffer : std_logic_vector(15 downto 0);
	type stateSpi_t is (idle,transfer,transferEnd);
	signal stateSpi : stateSpi_t := idle;

	type spiTransferMode_t is (sampleNormalMode, sampleTransparentMode, standby, regionOfIntrest, fullReadout, readShiftRegister_write, writeShiftRegister_write, configRegister_write, writeConfigRegister_write);
	signal spiTransferMode : spiTransferMode_t := sampleNormalMode;
	signal bitCounter : integer range 0 to 31 := 0;
	signal spiDone : std_logic := '0';

	signal message : std_logic_vector(16 downto 0);
	constant MSG_write_softReset : std_logic_vector(15 downto 0) := "0" & "0000000" & x"80";
	constant MSG_write_formatAndPower : std_logic_vector(15 downto 0) := "0" & "0000001" & x"00"; -- "20" for 2'compliment
	constant MSG_write_outputMode : std_logic_vector(15 downto 0) := "0" & "0000010" & x"85"; -- "85" 3.0mA + X
	constant MSG_write_testPatternOffHigh : std_logic_vector(15 downto 0) := "0" & "0000011" & "00000000";
	constant MSG_write_testPatternOffLow : std_logic_vector(15 downto 0) := "0" & "0000011" & "00000000";
	--constant MSG_write_testPatternOnHigh : std_logic_vector(15 downto 0) := "0" & "0000011" & "10000011";
	--constant MSG_write_testPatternLow : std_logic_vector(15 downto 0) := "0" & "0000100" & "11001101";
	constant MSG_write_testPattern1High : std_logic_vector(15 downto 0) := "0" & "0000011" & "10010101";
	constant MSG_write_testPattern1Low : std_logic_vector(15 downto 0) := "0" & "0000100" & "01010101";
	constant MSG_write_testPattern2High : std_logic_vector(15 downto 0) := "0" & "0000011" & "10000000";
	constant MSG_write_testPattern2Low : std_logic_vector(15 downto 0) := "0" & "0000100" & "00000001";
	constant MSG_write_testPattern3High : std_logic_vector(15 downto 0) := "0" & "0000011" & "10111111";
	constant MSG_write_testPattern3Low : std_logic_vector(15 downto 0) := "0" & "0000100" & "11111111";
	constant MSG_write_testPattern4High : std_logic_vector(15 downto 0) := "0" & "0000011" & "10000000";
	constant MSG_write_testPattern4Low : std_logic_vector(15 downto 0) := "0" & "0000100" & "00000000";
	constant MSG_write_testPatternBitslipHigh : std_logic_vector(15 downto 0) := "0" & "0000011" & "10101001";
	constant MSG_write_testPatternBitslipLow : std_logic_vector(15 downto 0) := "0" & "0000100" & "11010011";
	constant MSG_write_testPatternXHigh : std_logic_vector(9 downto 0) := "0" & "0000011" & "10";
	constant MSG_write_testPatternXLow : std_logic_vector(7 downto 0) := "0" & "0000100";
	type stateAdc_t is (idle,init1,init2,init3,init4,init5,init6,init7,init8,init9,init10,init11,init12,init13,init14,init15,init16,init17);
	signal stateAdc : stateAdc_t := init1;
	
	signal bitslipStart : std_logic := '0';
	signal bitslipStart2 : std_logic := '0';
	signal bitslipFailed : std_logic_vector(1 downto 0) := (others=>'0');
	signal bitslipPattern : std_logic_vector(6 downto 0);
	signal bitslipPatternOverride :  std_logic := '0';
	signal bitslipDone : std_logic_vector(1 downto 0) := (others=>'0');
	signal bitslipDoneSync1 : std_logic_vector(4 downto 0);
	signal bitslipDoneSync2 : std_logic_vector(4 downto 0);
	signal bitslipDoneSyncLatched1 : std_logic := '0';
	signal bitslipDoneSyncLatched2 : std_logic := '0';
	signal bitslipDoneSync : std_logic := '0';
	signal timeoutBitslip : unsigned(15 downto 0) := x"ffff";
	
	signal adcDataValid : std_logic := '0';
	signal adcDataSkipCounter : integer range 0 to 31 := 0;
	signal adcDataValidCounter : unsigned(15 downto 0) := (others=>'0');
	signal adcDataStart_old : std_logic := '0';
	
	signal numberOfSamplesToRead1 : std_logic_vector(15 downto 0);
	signal numberOfSamplesToRead2 : std_logic_vector(15 downto 0);
	signal numberOfSamplesToRead3 : std_logic_vector(15 downto 0);
	signal adcDataFifoCounter : unsigned(15 downto 0) := (others=>'0');
	
	signal offsetCorrectionRamAddress : std_logic_vector(9 downto 0);
	signal offsetCorrectionRamData : data8x16Bit_t;
	
	type stateFifoRead_t is (idle,read1,read2,done);
	signal stateFifoRead : stateFifoRead_t := idle;
	
	signal adcDataStartSync : std_logic_vector(3 downto 0);
	signal adcDataStartLatched : std_logic := '0';
	signal roiBufferReadyLatched : std_logic := '0';
	signal adcDataStart : std_logic := '0';
	
	signal chargeBuffer : data8x24Bit_t;
	signal baselineBuffer : data8x24Bit_t;
	signal baselineStart : std_logic_vector(9 downto 0);
	signal baselineEnd : std_logic_vector(9 downto 0);
	
begin
	
	adcDataGroupA_p <= adcDataA_p(6) & adcDataA_p(4) & adcDataA_p(2) & adcDataA_p(0);
	adcDataGroupA_n <= adcDataA_n(6) & adcDataA_n(4) & adcDataA_n(2) & adcDataA_n(0);
	adcDataGroupB_p <= adcDataA_p(7) & adcDataA_p(5) & adcDataA_p(3) & adcDataA_p(1);
	adcDataGroupB_n <= adcDataA_n(7) & adcDataA_n(5) & adcDataA_n(3) & adcDataA_n(1);
	
	reset <= registerWrite.reset;
	bitslipPattern <= registerWrite.bitslipPattern when (bitslipPatternOverride = '0') else "1100101";
	bitslipStart <= registerWrite.bitslipStart or bitslipStart2;
	registerRead.bitslipFailed <= bitslipFailed; --(0) or bitslipFailed(1);
	registerRead.bitslipPattern <= registerWrite.bitslipPattern;
	
	registerRead.testMode <= registerWrite.testMode;
	registerRead.testPattern <= registerWrite.testPattern;
	
	registerRead.offsetCorrectionRamAddress <= registerWrite.offsetCorrectionRamAddress;
	registerRead.offsetCorrectionRamWrite <= registerWrite.offsetCorrectionRamWrite;
	
	ltm9007_14_to_eventFifoSystem.roiBuffer <= drs4_to_ltm9007_14.roiBuffer;
	ltm9007_14_to_eventFifoSystem.roiBufferReady <= drs4_to_ltm9007_14.roiBufferReady;
	ltm9007_14_to_eventFifoSystem.realTimeCounter_latched <= drs4_to_ltm9007_14.realTimeCounter_latched;

	sclk <= sclk_i;

	--x100: entity work.serdes_1_to_n_clk_ddr_s8_diff generic map(7, false) port map(dataClockA_p, dataClockA_n, ioClockA_p, ioClockA_n, serdesStrobeA, serdesDivClockA);
	--x101: entity work.serdes_1_to_n_data_ddr_s8_diff generic map(7,4,false,"PER_CHANL") port map('1', adcDataGroupA_p, adcDataGroupA_n, ioClockA_p, ioClockA_n, serdesStrobeA, reset, serdesDivClockA, '0', dataOutGroupA, "00", open);
	--x101: entity work.serdes_1_to_n_data_ddr_s8_diff generic map(7,4,false,"PER_CHANL") port map('1', adcDataGroupA_p, adcDataGroupA_n, ioClockA_p, ioClockA_n, adcClocks.serdesStrobe, reset, adcClocks.serdesDivClock, '0', dataOutGroupA, "00", open);
	--x102: entity work.serdes_1_to_n_data_ddr_s8_diff generic map(7,1,false,"PER_CHANL") port map('1', frameA_p, frameA_n, ioClockA_p, ioClockA_n, serdesStrobeA, reset, serdesDivClockA, '0', frameOutGroupA, "00", open);

	--x104: entity work.serdes_1_to_n_clk_ddr_s8_diff generic map(7, false) port map(dataClockB_p, dataClockB_n, ioClockB_p, ioClockB_n, serdesStrobeB, serdesDivClockB);
	--x105: entity work.serdes_1_to_n_data_ddr_s8_diff generic map(7,4,false,"PER_CHANL") port map('1', adcDataGroupB_p, adcDataGroupB_n, ioClockB_p, ioClockB_n, serdesStrobeB, reset, serdesDivClockB, '0', dataOutGroupB, "00", open);
	--x105: entity work.serdes_1_to_n_data_ddr_s8_diff generic map(7,4,false,"PER_CHANL") port map('1', adcDataGroupB_p, adcDataGroupB_n, ioClockB_p, ioClockB_n, adcClocks.serdesStrobe, reset, adcClocks.serdesDivClock, '0', dataOutGroupB, "00", open);
	--x106: entity work.serdes_1_to_n_data_ddr_s8_diff generic map(7,1,false,"PER_CHANL") port map('1', frameB_p, frameB_n, ioClockA_p, ioClockA_n, serdesStrobeA, reset, serdesDivClockA, '0', frameOutGroupB, "00", open);
	
	x6: entity work.serdesIn_1to7 generic map(7,4,true,"PER_CHANL") port map('1', adcDataGroupA_p, adcDataGroupA_n, reset, adcClocks, bitslipStart, bitslipDone(0), bitslipFailed(0), bitslipPattern, "00", dataOutGroupA, open);
	x7: entity work.serdesIn_1to7 generic map(7,4,true,"PER_CHANL") port map('1', adcDataGroupB_p, adcDataGroupB_n, reset, adcClocks, bitslipStart, bitslipDone(1), bitslipFailed(1), bitslipPattern, "00", dataOutGroupB, open);

	x107: OBUFDS port map(O => enc_p, OB => enc_n, I => enc);
	
	x108: entity work.drs4FrontEndFifo port map(
		rst => fifoResetA,
		wr_clk => adcClocks.serdesDivClock, --serdesDivClockA,
		rd_clk => fifoReadClock,
		din => dataOutGroupA_buffer,
		wr_en => fifoWriteEnableA,
		rd_en => fifoReadEnableA,
		dout => fifoOutA,
		full => eventFifoFullA,
		overflow => eventFifoOverflowA,
		empty => fifoEmptyA,
		valid => fifoValidA,
		underflow => eventFifoUnderflowA,
		rd_data_count => fifoWordsA(3 downto 0),
		wr_data_count => registerRead.fifoWordsA2(3 downto 0)
	);
	x109: entity work.drs4FrontEndFifo port map(
		rst => fifoResetB,
		wr_clk => adcClocks.serdesDivClock, --serdesDivClockB,
		rd_clk => fifoReadClock,
		din => dataOutGroupB_buffer,
		wr_en => fifoWriteEnableB,
		rd_en => fifoReadEnableB,
		dout => fifoOutB,
		full => eventFifoFullB,
		overflow => eventFifoOverflowB,
		empty => fifoEmptyB, --open,
		valid => fifoValidB, --open,
		underflow => eventFifoUnderflowB,
		rd_data_count => fifoWordsB(3 downto 0),
		wr_data_count => open
	);

	fifoReadClock <= registerWrite.clock;
	adcFifo.fifoOutA <= fifoOutA;
	adcFifo.fifoOutB <= fifoOutB;
	fifoWordsA(4) <= eventFifoFullA;
	fifoWordsB(4) <= eventFifoFullB;
	adcFifo.fifoWordsA <= fifoWordsA;
	adcFifo.fifoWordsB <= fifoWordsB;
	registerRead.fifoValidA <= fifoValidA;
	registerRead.fifoEmptyA <= fifoEmptyA;
	registerRead.baselineStart <= registerWrite.baselineStart;
	registerRead.baselineEnd <= registerWrite.baselineEnd;

	registerRead.fifoWordsA <= "000" & fifoWordsA;

	g110: for i in 0 to 7 generate
		x110: entity work.drs4OffsetCorrectionRam port map(
			registerWrite.clock,
			registerWrite.reset,
			registerWrite.offsetCorrectionRamWrite(i downto i),
			registerWrite.offsetCorrectionRamAddress,
			registerWrite.offsetCorrectionRamData,
			registerRead.offsetCorrectionRamData(i),
			registerWrite.clock,
			'0',
			"0",
			offsetCorrectionRamAddress,
			x"0000",
			offsetCorrectionRamData(i)
		);
	end generate;

	P0:process (registerWrite.clock)
	begin
		if rising_edge(registerWrite.clock) then
			sclkEdgeRising <= '0'; -- autoreset
			sclkEdgeFalling <= '0'; -- autoreset
			sclkEnable <= '0'; -- autoreset
			spiDone <= '0'; -- autoreset
			spiBusy <= '0'; -- autoreset
			if (registerWrite.reset = '1') then
				sclkDivisorCounter <= to_unsigned(0, sclkDivisorCounter'length);
				sclk_i <= sclkDefaultLevel;
				stateSpi <= idle;
			else
				if (sclkEnable = '1') then
					if (sclkDivisorCounter = sclkDivisor) then
						sclkDivisorCounter <= to_unsigned(0, sclkDivisorCounter'length);
						
						sclk_i <= not sclk_i;
						if ((sclk_i = '0')) then
							sclkEdgeRising <= '1'; -- autoreset
						end if;
						if ((sclk_i = '1')) then
							sclkEdgeFalling <= '1'; -- autoreset
						end if;
					else
						sclkDivisorCounter <= sclkDivisorCounter + 1;
					end if;
				else
					sclk_i <= sclkDefaultLevel;
					sclkDivisorCounter <= to_unsigned(0, sclkDivisorCounter'length);
				end if;

				spiTransfer_old <= spiTransfer;
				
				case stateSpi is	
					when idle =>
						notChipSelectA <= '1';
						notChipSelectB <= '1';
						if((spiTransfer_old = '0') and (spiTransfer = '1')) then							
							txBuffer <= message(15 downto 0);
							if(message(16) = '0') then
								notChipSelectA <= '0';
							else
								notChipSelectB <= '0';
							end if;
							stateSpi <= transfer;
							bitCounter <= 15;
						end if;

					when transfer =>
						sclkEnable <= '1'; -- autoreset
						spiBusy <= '1'; -- autoreset

						--if (sclkEdgeRising = '1') then
						if (sclkEdgeFalling = '1') then
							--if((bitCounter /= 0) and (bitCounter /= 16)) then
								txBuffer <= txBuffer(txBuffer'length-2 downto 0) & mosiDefaultLevel;
							--end if;
							bitCounter <= bitCounter - 1;
							if (bitCounter = 0) then
								stateSpi <= transferEnd;
								bitCounter <= 0;
							end if;
						end if;
						
					when transferEnd =>
						spiBusy <= '1'; -- autoreset
						bitCounter <= bitCounter + 1;
						if(bitCounter >= 4) then -- ## may be we dont have to wait at all ...
						--if (sclkEdgeRising = '1') then
							--registerRead.regionOfInterest <= roiBuffer;
							stateSpi <= idle;
							txBuffer <= (others=>'0');
							spiDone <= '1'; -- autoreset
						end if;		
						
					when others => null;
				end case;
			end if;
		end if;
	end process P0;

	mosi <= txBuffer(txBuffer'length-1);

	P1:process (registerWrite.clock)
	begin
		if rising_edge(registerWrite.clock) then
			spiTransfer <= '0'; -- autoreset
			bitslipStart2 <= '0'; -- autoreset	
			if (registerWrite.reset = '1') then				
				stateAdc <= init1;
				message <= (others=>'0');
				bitslipDoneSync1 <= (others=>'0');
				bitslipDoneSync2 <= (others=>'0');
				bitslipDoneSync <= '0';
				bitslipDoneSyncLatched1 <= '0';
				bitslipDoneSyncLatched2 <= '0';
				bitslipPatternOverride <= '0';
			else
				bitslipDoneSync1 <= bitslipDone(0) & bitslipDoneSync1(bitslipDoneSync1'length-1 downto 1);
				bitslipDoneSync2 <= bitslipDone(1) & bitslipDoneSync2(bitslipDoneSync2'length-1 downto 1);
				
				bitslipDoneSyncLatched1 <= bitslipDoneSync1(0) or bitslipDoneSyncLatched1;
				bitslipDoneSyncLatched2 <= bitslipDoneSync2(0) or bitslipDoneSyncLatched2;
				bitslipDoneSync <= bitslipDoneSyncLatched1 and bitslipDoneSyncLatched2;

				case stateAdc is
					when idle =>
						if(registerWrite.init = '1') then
							stateAdc <= init1;
						end if;

					when init1 =>
						if(spiBusy = '0') then
							stateAdc <= init2;
						end if;
						
					when init2 =>
						message <= "0" & MSG_write_softReset;
						spiTransfer <= '1'; -- autoreset
						if(spiDone = '1') then
							stateAdc <= init3;
							spiTransfer <= '0'; -- autoreset
						end if;
					
					when init3 =>
						message <= "1" & MSG_write_softReset;
						spiTransfer <= '1'; -- autoreset
						if(spiDone = '1') then
							stateAdc <= init4;
							spiTransfer <= '0'; -- autoreset
						end if;
						
					when init4 =>
						message <= "0" & MSG_write_formatAndPower;
						spiTransfer <= '1'; -- autoreset
						if(spiDone = '1') then
							stateAdc <= init5;
							spiTransfer <= '0'; -- autoreset
						end if;
						
					when init5 =>
						message <= "1" & MSG_write_formatAndPower;
						spiTransfer <= '1'; -- autoreset
						if(spiDone = '1') then
							stateAdc <= init6;
							spiTransfer <= '0'; -- autoreset
						end if;
						
					when init6 =>
						message <= "0" & MSG_write_outputMode;
						spiTransfer <= '1'; -- autoreset
						if(spiDone = '1') then
							stateAdc <= init7;
							spiTransfer <= '0'; -- autoreset
						end if;
						
					when init7 =>
						message <= "1" & MSG_write_outputMode;
						spiTransfer <= '1'; -- autoreset
						if(spiDone = '1') then
							stateAdc <= init8;
							spiTransfer <= '0'; -- autoreset
						end if;
					
					when init8 =>
						if(registerWrite.testMode = x"1") then
							message <= "0" & MSG_write_testPatternXLow & registerWrite.testPattern(7 downto 0);
						else
							--message <= "0" & MSG_write_testPatternOffLow;
							message <= "0" & MSG_write_testPatternBitslipLow;
						end if;
						spiTransfer <= '1'; -- autoreset
						if(spiDone = '1') then
							stateAdc <= init9;
							spiTransfer <= '0'; -- autoreset
						end if;

					when init9 =>
						if(registerWrite.testMode = x"1") then
							message <= "1" & MSG_write_testPatternXLow & registerWrite.testPattern(7 downto 0);
						else
							--message <= "1" & MSG_write_testPatternOffLow;
							message <= "1" & MSG_write_testPatternBitslipLow;
						end if;
						spiTransfer <= '1'; -- autoreset
						if(spiDone = '1') then
							stateAdc <= init10;
							spiTransfer <= '0'; -- autoreset
						end if;

					when init10 =>
						if(registerWrite.testMode = x"1") then
							message <= "0" & MSG_write_testPatternXHigh & registerWrite.testPattern(13 downto 8);
						else
							--message <= "0" & MSG_write_testPatternOffHigh;
							message <= "0" & MSG_write_testPatternBitslipHigh;
						end if;
						spiTransfer <= '1'; -- autoreset
						if(spiDone = '1') then
							stateAdc <= init11;
							spiTransfer <= '0'; -- autoreset
						end if;
						
					when init11 =>
						if(registerWrite.testMode = x"1") then
							message <= "1" & MSG_write_testPatternXHigh & registerWrite.testPattern(13 downto 8);
						else
							--message <= "1" & MSG_write_testPatternOffHigh;
							message <= "1" & MSG_write_testPatternBitslipHigh;
						end if;
						spiTransfer <= '1'; -- autoreset
						if(spiDone = '1') then
							stateAdc <= init12;
							spiTransfer <= '0'; -- autoreset
						end if;

					when init12 =>
						if(registerWrite.testMode = x"1") then
							stateAdc <= idle;
						else
							stateAdc <= init13;
							timeoutBitslip <= x"0000";
						end if;
					
					when init13 =>
						timeoutBitslip <= timeoutBitslip + 1;
						if(timeoutBitslip = x"ffff") then
							stateAdc <= init14;
							timeoutBitslip <= x"0000";
						end if;
						if(timeoutBitslip > x"fff0") then
							bitslipStart2 <= '1'; -- autoreset	
						end if;
					
					when init14 =>
						bitslipStart2 <= '1'; -- autoreset
						bitslipDoneSync <= '0';
						bitslipPatternOverride <= '1';
						bitslipDoneSyncLatched1 <= '0';
						bitslipDoneSyncLatched2 <= '0';
						stateAdc <= init15;
						
					when init15 =>
						timeoutBitslip <= timeoutBitslip + 1;
						if(timeoutBitslip = x"ffff") then
							stateAdc <= init13;
							timeoutBitslip <= x"0000";
						end if;
						if(bitslipDoneSync = '1') then
							bitslipPatternOverride <= '0';
							stateAdc <= init16;
							timeoutBitslip <= x"0000";
						end if;

					when init16 =>
						message <= "0" & MSG_write_testPatternOffHigh;
						spiTransfer <= '1'; -- autoreset
						if(spiDone = '1') then
							stateAdc <= init17;
							spiTransfer <= '0'; -- autoreset
						end if;
						
					when init17 =>
						message <= "1" & MSG_write_testPatternOffHigh;
						spiTransfer <= '1'; -- autoreset
						if(spiDone = '1') then
							stateAdc <= idle;
							spiTransfer <= '0'; -- autoreset
						end if;
						
					when others => stateAdc <= idle;
				end case;	
			end if;
		end if;
	end process P1;

	P02:process (registerWrite.clock)
	begin
		if rising_edge(registerWrite.clock) then
			adcDataStartSync <= drs4_to_ltm9007_14.adcDataStart_66 & adcDataStartSync(adcDataStartSync'length-1 downto 1);
			if (registerWrite.reset = '1') then
				adcDataStart <= '0';
			else
				if((adcDataStartSync(1) = '1') and (adcDataStartSync(0) = '0')) then
					adcDataStart <= '1';
				else
					adcDataStart <= '0';
				end if;
			end if;
		end if;
	end process P02;

P9:process (adcClocks.serdesDivClock) -- ~66 MHz
begin
	if rising_edge(adcClocks.serdesDivClock) then
		adcDataValid <= '0'; -- autoreset
		if (registerWrite.reset = '1') then -- ## sync?!
			stateAdcFifoData <= idle;
			adcDataStart_old <= '0';
			numberOfSamplesToRead1 <= (others=>'0'); 
			numberOfSamplesToRead2 <= (others=>'0'); 
		else
			adcDataStart_old <= drs4_to_ltm9007_14.adcDataStart_66;
			numberOfSamplesToRead1 <= registerWrite.numberOfSamplesToRead; 
			numberOfSamplesToRead2 <= numberOfSamplesToRead1; 
			
			case stateAdcFifoData is
				when idle =>
					adcDataSkipCounter <= 1;
					if(adcDataStart_old = '0' and drs4_to_ltm9007_14.adcDataStart_66 = '1') then
						stateAdcFifoData <= skip;
					end if;
					
				when skip =>
					adcDataSkipCounter <= adcDataSkipCounter + 1;
					if(adcDataSkipCounter >= 6) then
						stateAdcFifoData <= valid1;
						adcDataValidCounter <= unsigned(numberOfSamplesToRead2); 
					end if;

				when valid1 =>
					adcDataValid <= '1'; -- autoreset
					stateAdcFifoData <= valid2;
					adcDataValidCounter <= adcDataValidCounter - 1;
				
				when valid2 =>
					adcDataValid <= '1'; -- autoreset
					--fifoWriteEnableA <= adcDataValid; -- autoreset		
					--fifoWriteEnableB <= adcDataValid; -- autoreset		
					stateAdcFifoData <= valid1;
					if(adcDataValidCounter = 0) then
						stateAdcFifoData <= idle;
					end if;

				when others => null;
			end case;
		end if;
	end if;
end process P9;

P10:process (adcClocks.serdesDivClock) -- ~66 MHz
begin
	if rising_edge(adcClocks.serdesDivClock) then
		fifoWriteEnableA <= '0'; -- autoreset
		fifoWriteEnableB <= '0'; -- autoreset
		fifoResetA <= '0'; -- autoreset
		fifoResetB <= '0'; -- autoreset
		if (registerWrite.reset = '1') then -- ## sync?!
			stateAdcFifo <= sync1;
		else
			case stateAdcFifo is				
				when sync1 =>
					-- set testbytes in adc ?!
					-- find start of values ?!
					fifoResetA <= '1'; -- autoreset
					fifoResetB <= '1'; -- autoreset
					stateAdcFifo <= sync2;
					
				when sync2 =>
					-- timeout for fifo reset...
					stateAdcFifo <= sample1;
				
				when sample1 =>
					stateAdcFifo <= sample2;
					for i in 0 to 3 loop
						dataOutGroupA_buffer(13+i*14 downto 7+i*14) <= reverse_vector(dataOutGroupA(6+i*7 downto 0+i*7));	
						dataOutGroupB_buffer(13+i*14 downto 7+i*14) <= reverse_vector(dataOutGroupB(6+i*7 downto 0+i*7));	
					end loop;

				when sample2 =>
					stateAdcFifo <= sample1;
					for i in 0 to 3 loop
						dataOutGroupA_buffer(6+i*14 downto 0+i*14) <= reverse_vector(dataOutGroupA(6+i*7 downto 0+i*7));
						dataOutGroupB_buffer(6+i*14 downto 0+i*14) <= reverse_vector(dataOutGroupB(6+i*7 downto 0+i*7));
					end loop;
					fifoWriteEnableA <= adcDataValid; -- autoreset		
					fifoWriteEnableB <= adcDataValid; -- autoreset		
					
				when others => null;
			end case;
		end if;
	end if;
end process P10;

P4:process (registerWrite.clock)
	variable sampleBuffer : data8x16Bit_t; 
begin
	if rising_edge(registerWrite.clock) then
		fifoReadEnableA <= '0'; -- autoreset
		fifoReadEnableB <= '0'; -- autoreset
		ltm9007_14_to_eventFifoSystem.newData <= '0'; -- autoreset
		ltm9007_14_to_eventFifoSystem.samplingDone <= '0'; -- autoreset
		ltm9007_14_to_eventFifoSystem.chargeDone <= '0'; -- autoreset
		ltm9007_14_to_eventFifoSystem.baselineDone <= '0'; -- autoreset
		if (registerWrite.reset = '1') then
			eventFifoFullCounterA <= to_unsigned(0,eventFifoFullCounterA'length);
			eventFifoOverflowCounterA <= to_unsigned(0,eventFifoOverflowCounterA'length);
			eventFifoUnderflowCounterA <= to_unsigned(0,eventFifoUnderflowCounterA'length);
			eventFifoOverflowA_old <= '0';
			eventFifoUnderflowA_old <= '0';
			eventFifoFullA_old <= '0';
			stateFifoRead <= idle;
			adcDataStartLatched <= '0';
			roiBufferReadyLatched <= '0';
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

			--if(fifoWordsA > "11100") then
			--	fifoReadEnableA <= '1'; -- autoreset
			--	fifoReadEnableB <= '1'; -- autoreset
			--	-- error++
			--end if;
			--
			--if(drs4_to_ltm9007_14.drs4RoiValid = '1') then
			--	fifoReadEnableA <= '1'; -- autoreset
			--	fifoReadEnableB <= '1'; -- autoreset
			--end if;

			--debugA <= fifoReadEnableA;
			--debugB <= debugA;
			--debugC <= debugB;

			registerRead.fifoA <= fifoOutA;
			registerRead.fifoB <= fifoOutB;

			adcDataStartLatched <= adcDataStartLatched or adcDataStart;
			roiBufferReadyLatched <= roiBufferReadyLatched or drs4_to_ltm9007_14.roiBufferReady;

			case stateFifoRead is				
				when idle =>
					if((adcDataStartLatched = '1') and (roiBufferReadyLatched = '1')) then
						stateFifoRead <= read1;
						numberOfSamplesToRead3 <= registerWrite.numberOfSamplesToRead;
						offsetCorrectionRamAddress <= drs4_to_ltm9007_14.roiBuffer;
						adcDataFifoCounter <= (others=>'0');
						chargeBuffer <= (others=>(others=>'0'));
						baselineBuffer <= (others=>(others=>'0'));
						baselineStart <= registerWrite.baselineStart;
						baselineEnd <= registerWrite.baselineEnd;
					end if;

				when read1 =>
					--if(fifoWordsA /= "00000") then
					if(fifoEmptyA = '0') then
						fifoReadEnableA <= '1'; -- autoreset
						fifoReadEnableB <= '1'; -- autoreset
						stateFifoRead <= read2;
					end if;
					
					if(adcDataFifoCounter >= unsigned(numberOfSamplesToRead3)) then
						stateFifoRead <= done;
					end if;
					
					if(adcDataFifoCounter > unsigned(baselineEnd)) then
						ltm9007_14_to_eventFifoSystem.baseline <= baselineBuffer;
						ltm9007_14_to_eventFifoSystem.baselineDone <= '1'; -- autoreset
					end if;	
			
				when read2 =>
					if(fifoValidA = '1') then -- ## fifo B is allways the same...
						l0: for i in 0 to 3 loop
							sampleBuffer(i) := std_logic_vector(resize(unsigned(fifoOutA(13+i*14 downto 0+i*14)),16) + resize(unsigned(offsetCorrectionRamData(i)),16));
							sampleBuffer(i+4) := std_logic_vector(resize(unsigned(fifoOutB(13+i*14 downto 0+i*14)),16) + resize(unsigned(offsetCorrectionRamData(i+4)),16));
						end loop;
						l1: for i in 0 to 7 loop							
							ltm9007_14_to_eventFifoSystem.channel(i) <= sampleBuffer(i);
							chargeBuffer(i) <= std_logic_vector(unsigned(chargeBuffer(i)) + unsigned(sampleBuffer(i)));
						end loop;

						if((adcDataFifoCounter >= unsigned(baselineStart)) and (adcDataFifoCounter <= unsigned(baselineEnd))) then
							l2: for i in 0 to 7 loop							
								baselineBuffer(i) <= std_logic_vector(unsigned(baselineBuffer(i)) + unsigned(sampleBuffer(i)));
							end loop;
						end if;
					
						ltm9007_14_to_eventFifoSystem.newData <= '1'; -- autoreset
						offsetCorrectionRamAddress <= std_logic_vector(unsigned(offsetCorrectionRamAddress) + 1);
						adcDataFifoCounter <= adcDataFifoCounter + 1;
						stateFifoRead <= read1;
					end if;

					--if(adcDataFifoCounter >= unsigned(numberOfSamplesToRead3)) then
					--	stateFifoRead <= done;
					--end if;
					
				when done =>
					stateFifoRead <= idle;
					adcDataStartLatched <= '0';
					roiBufferReadyLatched <= '0';
					ltm9007_14_to_eventFifoSystem.samplingDone <= '1'; -- autoreset
					ltm9007_14_to_eventFifoSystem.charge <= chargeBuffer;
					ltm9007_14_to_eventFifoSystem.chargeDone <= '1'; -- autoreset
					
				when others => null;
			end case;
			
		end if;
	end if;
end process P4;


P5:process (adcClocks.serdesDivClock) -- 66MHz
begin
	if rising_edge(adcClocks.serdesDivClock) then
		if (registerWrite.reset = '1') then -- ## hack
			enc <= '0';
		else
			enc <= not(enc);
		end if;
	end if;
end process P5;

end Behavioral;

