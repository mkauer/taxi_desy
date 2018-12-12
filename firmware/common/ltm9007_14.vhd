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
		adcDataA_p : in std_logic_vector(7 downto 0);
		adcDataA_n : in std_logic_vector(7 downto 0);
		--dataOutGroupA : in std_logic_vector(7*4-1 downto 0);
		--dataOutGroupB : in std_logic_vector(7*4-1 downto 0);
		
		drs4_to_ltm9007_14 : in drs4_to_ltm9007_14_t;
		ltm9007_14_to_eventFifoSystem : out ltm9007_14_to_eventFifoSystem_t;
		adcClocks : in adcClocks_t;

		allBitslipDone : out std_logic;
		bitslipStart : in std_logic;		
		--registerRead : out ltm9007_14_registerRead_t;
		registerWrite : in ltm9007_14_registerWrite_t	
	);
end ltm9007_14;

architecture Behavioral of ltm9007_14 is
	attribute keep : string;
	
	signal ioClockA_p : std_logic := '0';
	signal ioClockA_n : std_logic := '0';
	signal ioClockB_p : std_logic := '0';
	signal ioClockB_n : std_logic := '0';
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
	
	type stateAdcFifoData_t is (idle, skip, valid1, valid2);
	signal stateAdcFifoData : stateAdcFifoData_t := idle;
	type stateAdcFifo_t is (sync1, sync2, sample1, sample2);
	signal stateAdcFifo : stateAdcFifo_t := sync1;

	signal fifoWriteEnable : std_logic := '0';
	signal fifoReadEnable : std_logic := '0';
	signal fifoReset : std_logic := '0';
	signal fifoReset_TPTHRU_TIG : std_logic := '0';
	attribute keep of fifoReset_TPTHRU_TIG: signal is "true";
	signal fifoReset_sync : std_logic := '0';
	
	signal fifoEmptyA : std_logic := '0';
	signal fifoEmptyB : std_logic := '0';
	signal fifoValidA : std_logic := '0';
	signal fifoValidB : std_logic := '0';

	signal eventFifoOverflowA : std_logic := '0';
	signal eventFifoOverflowA_66 : std_logic := '0';
	--signal eventFifoOverflowB : std_logic := '0';
	signal eventFifoUnderflowA : std_logic := '0';
	--signal eventFifoUnderflowB : std_logic := '0';
	signal eventFifoFullA : std_logic := '0';
	signal eventFifoFullA_TPTHRU_TIG : std_logic := '0';
	
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

	signal notChipSelect : std_logic_vector(5 downto 0);
	signal message : std_logic_vector(notChipSelect'length+15 downto 0);
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
	
	signal bitslipStart_TPTHRU_TIG : std_logic := '0';
	attribute keep of bitslipStart_TPTHRU_TIG: signal is "true";
	signal bitslipStart_sync : std_logic := '0';
	--signal bitslipPattern : std_logic_vector(6 downto 0);
	--signal bitslipPattern_TPTHRU_TIG : std_logic_vector(6 downto 0);
	signal bitslipPatternOverride :  std_logic := '0';
	signal bitslipDone : std_logic_vector(1 downto 0) := (others=>'0');
	signal allBitslipDone_TPTHRU_TIG : std_logic := '0';
	attribute keep of allBitslipDone_TPTHRU_TIG: signal is "true";
	--signal bitslipDone_sync : std_logic_vector(1 downto 0) := (others=>'0');
	
	signal adcDataValid : std_logic := '0';
	signal adcDataSkipCounter : integer range 0 to 31 := 0;
	signal adcDataValidCounter : unsigned(15 downto 0) := (others=>'0');
	signal adcDataStart_old : std_logic := '0';
	signal adcDataStartSync : std_logic_vector(3 downto 0);
	
	signal numberOfSamplesToRead_slow : std_logic_vector(15 downto 0);
	signal numberOfSamplesToRead_TPTHRU_TIG : std_logic_vector(15 downto 0);
	attribute keep of numberOfSamplesToRead_TPTHRU_TIG: signal is "true";
	signal numberOfSamplesToReadLatched : std_logic_vector(15 downto 0);
	signal adcDataFifoCounter : unsigned(15 downto 0) := (others=>'0');
	
	signal offsetCorrectionRamAddressRead : std_logic_vector(9 downto 0);
	signal offsetCorrectionRamDataRead : data8x16Bit_t;
	
	type stateFifoRead_t is (idle,read1,read2,done);
	signal stateFifoRead : stateFifoRead_t := idle;
	
	signal adcDataStartLatched : std_logic := '0';
	signal roiBufferReadyLatched : std_logic := '0';
	signal adcDataStart : std_logic := '0';
	signal adcDataStart_66 : std_logic := '0';
	signal adcDataStart_66_TPTHRU_TIG : std_logic := '0';
	attribute keep of adcDataStart_66_TPTHRU_TIG: signal is "true";
	
	signal chargeBuffer : data8x24Bit_t;
	signal baselineBuffer : data8x24Bit_t;
	signal baselineStart : std_logic_vector(9 downto 0);
	signal baselineEnd : std_logic_vector(9 downto 0);
	
	signal bitslipStart_Slow : std_logic_vector(3 downto 0);

	
begin

	--registerWrite.numbeOfSamplesToRead
	--registerWrite.baselineStart
	--registerWrite.baselineEnd

	--registerWrite.offsetCorrectionRamAddress
	--registerWrite.offsetCorrectionRamWrite
	--registerWrite.offsetCorrectionRamData
	registerRead.offsetCorrectionRamData --

	
	bitslipStartLatched_sync

	process (registerWrite.clock) begin
		if rising_edge(registerWrite.clock) then
			allBitslipDone_TPTHRU_TIG <= bitslipDone(0) and bitslipDone(1);

			if(bitslipStart = '1') then
				bitslipStart_Slow <= (others=>'1');
			else
				bitslipStart_Slow <= '0' & bitslipStart_Slow(bitslipStart_Slow'length-1 downto 1);
			end if;
		end if;
	end process;
	allBitslipDone <= allBitslipDone_TPTHRU_TIG; 
	
	process (registerWrite.serdesDivClock) begin -- ~66 MHz
		if rising_edge(registerWrite.serdesDivClock) then
			bitslipStart_TPTHRU_TIG <= bitslipStart_Slow;
			bitslipStart_sync <= bitslipStart_TPTHRU_TIG;
			numberOfSamplesToRead_TPTHRU_TIG <= registerWrite.numberOfSamplesToRead;
			numberOfSamplesToRead_slow <= numberOfSamplesToRead_TPTHRU_TIG;
		end if;
	end process;

	fifoReset_TPTHRU_TIG <= fifoReset; 
	fifoReset_sync <= fifoReset_TPTHRU_TIG; 
	
	adcDataStart_66_TPTHRU_TIG <= drs4_to_ltm9007_14.adcDataStart_66;
	adcDataStart_66 <= drs4_to_ltm9007_14.adcDataStart_66;
	
	adcDataGroupA_p <= adcDataA_p(7) & adcDataA_p(4) & adcDataA_p(3) & adcDataA_p(0);
	adcDataGroupA_n <= adcDataA_n(7) & adcDataA_n(4) & adcDataA_n(3) & adcDataA_n(0);
	adcDataGroupB_p <= adcDataA_p(6) & adcDataA_p(5) & adcDataA_p(2) & adcDataA_p(1);
	adcDataGroupB_n <= adcDataA_n(6) & adcDataA_n(5) & adcDataA_n(2) & adcDataA_n(1);

	ltm9007_14_to_eventFifoSystem.roiBuffer <= drs4_to_ltm9007_14.roiBuffer;
	ltm9007_14_to_eventFifoSystem.roiBufferReady <= drs4_to_ltm9007_14.roiBufferReady;
	ltm9007_14_to_eventFifoSystem.realTimeCounter_latched <= drs4_to_ltm9007_14.realTimeCounter_latched;
	
	ltm9007_14_to_eventFifoSystem.maxValue <= (others=>(others=>'0'));

	x6: entity work.serdesIn_1to7 generic map(7,4,true,"PER_CHANL") port map('1', adcDataGroupA_p, adcDataGroupA_n, adcClocks, bitslipStart_sync, bitslipDone(0), open, "1100101", "00", dataOutGroupA, open);
	x7: entity work.serdesIn_1to7 generic map(7,4,true,"PER_CHANL") port map('1', adcDataGroupB_p, adcDataGroupB_n, adcClocks, bitslipStart_sync, bitslipDone(1), open, "1100101", "00", dataOutGroupB, open);

	x108: entity work.drs4FrontEndFifo port map(
		rst => fifoReset_sync, -- 66 ??
		wr_clk => adcClocks.serdesDivClock, -- 66 ok --serdesDivClockA,
		rd_clk => registerWrite.clock, -- 125 ok
		din => dataOutGroupA_buffer, -- 66 ok
		wr_en => fifoWriteEnable, -- 66 ok
		rd_en => fifoReadEnable, -- 125 ok
		dout => fifoOutA, -- 125 ok 
		full => eventFifoFullA_TPTHRU_TIG, -- 125 xx
		overflow => eventFifoOverflowA_66, -- 125 xx
		empty => fifoEmptyA, -- 125 ok
		valid => fifoValidA, -- 125 ok
		underflow => eventFifoUnderflowA, -- 125 ok
		rd_data_count => fifoWordsA(3 downto 0), -- 125 ok
		wr_data_count => open --registerRead.fifoWordsA2(3 downto 0) -- 125 xx
	);
	x109: entity work.drs4FrontEndFifo port map(
		rst => fifoReset_sync,
		wr_clk => adcClocks.serdesDivClock,
		rd_clk => registerWrite.clock,
		din => dataOutGroupB_buffer,
		wr_en => fifoWriteEnable,
		rd_en => fifoReadEnable,
		dout => fifoOutB,
		full => open,
		overflow => open,
		empty => open,
		valid => open,
		underflow => open,
		rd_data_count => open,
		wr_data_count => open
	);

	fifoWordsA(4) <= eventFifoFullA_TPTHRU_TIG;
	registerRead.fifoValidA <= fifoValidA;
	registerRead.fifoEmptyA <= fifoEmptyA;

	g110: for i in 0 to 7 generate
		x110: entity work.drs4OffsetCorrectionRam port map(
			registerWrite.clock,
			registerWrite.reset,
			registerWrite.offsetCorrectionRamWrite(i downto i),
			registerWrite.offsetCorrectionRamAddress,
			registerWrite.offsetCorrectionRamData,
			registerRead.offsetCorrectionRamData(i), -- ## implement mux here....
			registerWrite.clock,
			'0',
			"0",
			offsetCorrectionRamAddressRead,
			x"0000",
			offsetCorrectionRamDataRead(i)
		);
	end generate;

P9:process (adcClocks.serdesDivClock) -- ~66 MHz
begin
	if rising_edge(adcClocks.serdesDivClock) then
		adcDataValid <= '0'; -- autoreset
		if (adcClocks.serdesDivClockReset = '1') then
			stateAdcFifoData <= idle;
			adcDataStart_old <= '0';
			--numberOfSamplesToRead <= (others=>'0'); 
		else
			adcDataStart_old <= adcDataStart_66;
			
			case stateAdcFifoData is
				when idle =>
					adcDataSkipCounter <= 1;
					if(adcDataStart_old = '0' and adcDataStart_66 = '1') then
						stateAdcFifoData <= skip;
					end if;
					
				when skip =>
					adcDataSkipCounter <= adcDataSkipCounter + 1;
					if(adcDataSkipCounter >= 6) then
						stateAdcFifoData <= valid1;
						adcDataValidCounter <= unsigned(numberOfSamplesToRead_slow); 
					end if;

				when valid1 =>
					adcDataValid <= '1'; -- autoreset
					stateAdcFifoData <= valid2;
					adcDataValidCounter <= adcDataValidCounter - 1;
				
				when valid2 =>
					adcDataValid <= '1'; -- autoreset
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
		fifoWriteEnable <= '0'; -- autoreset
		fifoReset <= '0'; -- autoreset
		if (adcClocks.serdesDivClockReset = '1') then
			stateAdcFifo <= sync1;
		else
			case stateAdcFifo is				
				when sync1 =>
					-- set testbytes in adc ?!
					-- find start of values ?!
					fifoReset <= '1'; -- autoreset
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
					fifoWriteEnable <= adcDataValid; -- autoreset		
					
				when others => null;
			end case;
		end if;
	end if;
end process P10;

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
			eventFifoOverflowA <= eventFifoOverflowA_66;
			eventFifoOverflowA_old <= eventFifoOverflowA;
			eventFifoUnderflowA_old <= eventFifoUnderflowA;
			eventFifoFullA <= eventFifoFullA_TPTHRU_TIG;
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

		end if;
	end if;
end process P4;

P02:process (registerWrite.clock)
	begin
		if rising_edge(registerWrite.clock) then
			adcDataStartSync <= adcDataStart_66_TPTHRU_TIG & adcDataStartSync(adcDataStartSync'length-1 downto 1);
			if (registerWrite.reset = '1') then
				adcDataStart <= '0';
				adcDataStartSync <= (others=>'0');
			else
				if((adcDataStartSync(1) = '1') and (adcDataStartSync(0) = '0')) then
					adcDataStart <= '1';
				else
					adcDataStart <= '0';
				end if;
			end if;
		end if;
	end process P02;

P5:process (registerWrite.clock)
	variable sampleBuffer : data8x16Bit_t; 
begin
	if rising_edge(registerWrite.clock) then
		fifoReadEnable <= '0'; -- autoreset
		ltm9007_14_to_eventFifoSystem.newData <= '0'; -- autoreset
		ltm9007_14_to_eventFifoSystem.samplingDone <= '0'; -- autoreset
		ltm9007_14_to_eventFifoSystem.chargeDone <= '0'; -- autoreset
		ltm9007_14_to_eventFifoSystem.baselineDone <= '0'; -- autoreset
		if (registerWrite.reset = '1') then
			stateFifoRead <= idle;
			adcDataStartLatched <= '0';
			roiBufferReadyLatched <= '0';
		else
			adcDataStartLatched <= adcDataStartLatched or adcDataStart;
			roiBufferReadyLatched <= roiBufferReadyLatched or drs4_to_ltm9007_14.roiBufferReady;

			case stateFifoRead is				
				when idle =>
					if((adcDataStartLatched = '1') and (roiBufferReadyLatched = '1')) then
						stateFifoRead <= read1;
						numberOfSamplesToReadLatched <= registerWrite.numberOfSamplesToRead;
						offsetCorrectionRamAddressRead <= drs4_to_ltm9007_14.roiBuffer;
						adcDataFifoCounter <= (others=>'0');
						chargeBuffer <= (others=>(others=>'0'));
						baselineBuffer <= (others=>(others=>'0'));
						baselineStart <= registerWrite.baselineStart;
						baselineEnd <= registerWrite.baselineEnd;
					end if;

				when read1 =>
					--if(fifoWordsA /= "00000") then
					if(fifoEmptyA = '0') then
						fifoReadEnable <= '1'; -- autoreset
						stateFifoRead <= read2;
					end if;
					
					if(adcDataFifoCounter >= unsigned(numberOfSamplesToReadLatched)) then
						stateFifoRead <= done;
					end if;
					
					--if(adcDataFifoCounter > unsigned(baselineEnd)) then
					--	ltm9007_14_to_eventFifoSystem.baseline <= baselineBuffer;
					--	ltm9007_14_to_eventFifoSystem.baselineDone <= '1'; -- autoreset
					--end if;	
			
				when read2 =>
					if(fifoValidA = '1') then -- ## fifo B is allways the same...
						--l0: for i in 0 to 3 loop
						--	sampleBuffer(i*2) := std_logic_vector(resize(unsigned(fifoOutA(13+i*14 downto 0+i*14)),16) + resize(unsigned(offsetCorrectionRamDataRead(i)),16));
						--	sampleBuffer(i*2+1) := std_logic_vector(resize(unsigned(fifoOutB(13+i*14 downto 0+i*14)),16) + resize(unsigned(offsetCorrectionRamDataRead(i+4)),16));
						--end loop;
							sampleBuffer(0) := std_logic_vector(resize(unsigned(fifoOutA(13+0*14 downto 0+0*14)),16) + resize(unsigned(offsetCorrectionRamDataRead(0)),16));
							sampleBuffer(3) := std_logic_vector(resize(unsigned(fifoOutA(13+1*14 downto 0+1*14)),16) + resize(unsigned(offsetCorrectionRamDataRead(3)),16));
							sampleBuffer(4) := std_logic_vector(resize(unsigned(fifoOutA(13+2*14 downto 0+2*14)),16) + resize(unsigned(offsetCorrectionRamDataRead(4)),16));
							sampleBuffer(7) := std_logic_vector(resize(unsigned(fifoOutA(13+3*14 downto 0+3*14)),16) + resize(unsigned(offsetCorrectionRamDataRead(7)),16));
							sampleBuffer(1) := std_logic_vector(resize(unsigned(fifoOutB(13+0*14 downto 0+0*14)),16) + resize(unsigned(offsetCorrectionRamDataRead(1)),16));
							sampleBuffer(2) := std_logic_vector(resize(unsigned(fifoOutB(13+1*14 downto 0+1*14)),16) + resize(unsigned(offsetCorrectionRamDataRead(2)),16));
							sampleBuffer(5) := std_logic_vector(resize(unsigned(fifoOutB(13+2*14 downto 0+2*14)),16) + resize(unsigned(offsetCorrectionRamDataRead(5)),16));
							sampleBuffer(6) := std_logic_vector(resize(unsigned(fifoOutB(13+3*14 downto 0+3*14)),16) + resize(unsigned(offsetCorrectionRamDataRead(6)),16));

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
						offsetCorrectionRamAddressRead <= std_logic_vector(unsigned(offsetCorrectionRamAddressRead) + 1);
						adcDataFifoCounter <= adcDataFifoCounter + 1;
						stateFifoRead <= read1;
					end if;

				when done =>
					stateFifoRead <= idle;
					adcDataStartLatched <= '0';
					roiBufferReadyLatched <= '0';
					ltm9007_14_to_eventFifoSystem.samplingDone <= '1'; -- autoreset
					ltm9007_14_to_eventFifoSystem.charge <= chargeBuffer;
					ltm9007_14_to_eventFifoSystem.chargeDone <= '1'; -- autoreset
					ltm9007_14_to_eventFifoSystem.baseline <= baselineBuffer;
					ltm9007_14_to_eventFifoSystem.baselineDone <= '1'; -- autoreset
					
				when others => null;
			end case;
			
		end if;
	end if;
end process P5;


end Behavioral;

