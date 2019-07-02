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
		enc_p_0 : out std_logic;
		enc_n_0 : out std_logic;
		adcDataA_p_0 : in std_logic_vector(7 downto 0);
		adcDataA_n_0 : in std_logic_vector(7 downto 0);
		notChipSelectA_0 : out std_logic;
		notChipSelectB_0 : out std_logic;
		
		enc_p_1 : out std_logic;
		enc_n_1 : out std_logic;
		adcDataA_p_1 : in std_logic_vector(7 downto 0);
		adcDataA_n_1 : in std_logic_vector(7 downto 0);
		notChipSelectA_1 : out std_logic;
		notChipSelectB_1 : out std_logic;
		
		enc_p_2 : out std_logic;
		enc_n_2 : out std_logic;
		adcDataA_p_2 : in std_logic_vector(7 downto 0);
		adcDataA_n_2 : in std_logic_vector(7 downto 0);
		notChipSelectA_2 : out std_logic;
		notChipSelectB_2 : out std_logic;
		
		
		mosi : out std_logic;
		sclk : out std_logic;
		
		drs4_to_ltm9007_14 : in drs4_to_ltm9007_14_t;
		--drs4Clocks : in drs4Clocks_t;
		--adcFifo : out adcFifo_t;
		ltm9007_14_to_eventFifoSystem : out ltm9007_14_to_eventFifoSystem_t;
		adcClocks : in adcClocks_t;
		
		registerRead : out ltm9007_14_registerRead_t;
		registerWrite : in ltm9007_14_registerWrite_t	
	);
end ltm9007_14;

architecture Behavioral of ltm9007_14 is
	attribute keep : string;
	
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
	signal fifoReset : std_logic := '0';
	signal fifoReset_TPTHRU_TIG : std_logic := '0';
	attribute keep of fifoReset_TPTHRU_TIG: signal is "true";
	signal fifoReset_sync : std_logic := '0';
	--signal fifoResetB : std_logic := '0';
	
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
	type stateAdc_t is (idle,init1,init2,init3,init4,init5,init6,init7,init8,init9,init10);
	signal stateAdc : stateAdc_t := init1;
	
	signal bitslipStart : std_logic := '0';
	signal bitslipStartFromInit : std_logic := '0';
	signal bitslipFailed : std_logic_vector(1 downto 0) := (others=>'0');
	signal bitslipFailed_TPTHRU_TIG : std_logic_vector(1 downto 0) := (others=>'0');
	attribute keep of bitslipFailed_TPTHRU_TIG: signal is "true";
	signal bitslipFailed_sync : std_logic_vector(1 downto 0) := (others=>'0');
	signal bitslipPattern : std_logic_vector(6 downto 0);
	signal bitslipPatternOverride :  std_logic := '0';
	signal bitslipDone : std_logic_vector(3 downto 0) := (others=>'0');
	signal bitslipDoneLatched : std_logic_vector(3 downto 0) := (others=>'0');
	--signal bitslipDone_sync : std_logic_vector(1 downto 0) := (others=>'0');
	signal bitslipDoneSync1 : std_logic_vector(4 downto 0);
	signal bitslipDoneSync2 : std_logic_vector(4 downto 0);
	signal allBitslipDone : std_logic := '0';
	signal timeoutBitslip : unsigned(15 downto 0) := x"ffff";
	
	signal adcDataValid : std_logic := '0';
	signal adcDataSkipCounter : integer range 0 to 31 := 0;
	signal adcDataValidCounter : unsigned(15 downto 0) := (others=>'0');
	signal adcDataStart_old : std_logic := '0';
	
	signal numberOfSamplesToRead : std_logic_vector(15 downto 0);
	signal numberOfSamplesToRead_TPTHRU_TIG : std_logic_vector(15 downto 0);
	attribute keep of numberOfSamplesToRead_TPTHRU_TIG: signal is "true";
	signal numberOfSamplesToRead_sync : std_logic_vector(15 downto 0);
--	signal numberOfSamplesToRead2 : std_logic_vector(15 downto 0);
	signal numberOfSamplesToReadLatched : std_logic_vector(15 downto 0);
	signal adcDataFifoCounter : unsigned(15 downto 0) := (others=>'0');
	
	signal offsetCorrectionRamAddress : std_logic_vector(9 downto 0);
	signal offsetCorrectionRamData : data8x16Bit_t;
	
	type stateFifoRead_t is (idle,read1,read2,done);
	signal stateFifoRead : stateFifoRead_t := idle;
	
	signal adcDataStartLatched : std_logic := '0';
	signal roiBufferReadyLatched : std_logic := '0';
	
	signal chargeBuffer : data8x24Bit_t;
	signal baselineBuffer : data8x24Bit_t;
	signal baselineStart : std_logic_vector(9 downto 0);
	signal baselineEnd : std_logic_vector(9 downto 0);
	
begin

	bitslipFailed_TPTHRU_TIG <= bitslipFailed;
	bitslipFailed_sync <= bitslipFailed_TPTHRU_TIG;
	
	reset <= registerWrite.reset;
	bitslipStart <= registerWrite.bitslipStart or bitslipStartFromInit;
	--registerRead.bitslipFailed <= bitslipFailed; -- ## sync
	
	--bitslipPattern <= registerWrite.bitslipPattern when (bitslipPatternOverride = '0') else "1100101";
	--registerRead.bitslipPattern <= registerWrite.bitslipPattern;
	
	registerRead.testMode <= registerWrite.testMode;
	registerRead.testPattern <= registerWrite.testPattern;
	
	sclk <= sclk_i;
	
	x107a: OBUFDS port map(O => enc_p_0, OB => enc_n_0, I => enc);
	x107b: OBUFDS port map(O => enc_p_1, OB => enc_n_1, I => enc);
	x107c: OBUFDS port map(O => enc_p_2, OB => enc_n_2, I => enc);

	P5:process (adcClocks.serdesDivClock) -- 66MHz
	begin
		if rising_edge(adcClocks.serdesDivClock) then
			if (adcClocks.serdesDivClockReset = '1') then
				enc <= '0';
			else
				enc <= not(enc);
			end if;
		end if;
	end process P5;
	
	x99a: entity work.ltm9007_14 generic port map(adcDataA_p_0, adcDataA_n_0, drs4_to_ltm9007_14, ltm9007_14_to_eventFifoSystem_0, adcClocks, bitslipDone(0), bitslipStart, registerWrite);
	x99b: entity work.ltm9007_14 generic port map(adcDataA_p_1, adcDataA_n_1, drs4_to_ltm9007_14, ltm9007_14_to_eventFifoSystem_1, adcClocks, bitslipDone(1), bitslipStart, registerWrite);
	x99c: entity work.ltm9007_14 generic port map(adcDataA_p_2, adcDataA_n_2, drs4_to_ltm9007_14, ltm9007_14_to_eventFifoSystem_2, adcClocks, bitslipDone(2), bitslipStart, registerWrite);
	
	notChipSelectA_0 <= notChipSelect(0);
	notChipSelectB_0 <= notChipSelect(1);
	notChipSelectA_1 <= notChipSelect(2);
	notChipSelectB_1 <= notChipSelect(3);
	notChipSelectA_2 <= notChipSelect(4);
	notChipSelectB_2 <= notChipSelect(5);

	process (registerWrite.clock)
	begin
		if rising_edge(registerWrite.clock) then
			registerRead.fifoWordsA <= "000" & fifoWordsA;
			registerRead.bitslipFailed <= bitslipFailed_sync;
		end if;
	end process;

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
				notChipSelect <= (others=>'1');
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
						notChipSelect <= (others=>'1');
						if((spiTransfer_old = '0') and (spiTransfer = '1')) then							
							txBuffer <= message(15 downto 0);
							notChipSelect <= not(message(21 downto 16));
							stateSpi <= transfer;
							bitCounter <= 15;
						end if;

					when transfer =>
						sclkEnable <= '1'; -- autoreset
						spiBusy <= '1'; -- autoreset

						--if (sclkEdgeRising = '1') then
						if (sclkEdgeFalling = '1') then
							txBuffer <= txBuffer(txBuffer'length-2 downto 0) & mosiDefaultLevel;
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
			bitslipStartFromInit <= '0'; -- autoreset	
			bitslipPattern_TPTHRU_TIG <= bitslipPattern;
			if (registerWrite.reset = '1') then				
				stateAdc <= init1;
				message <= (others=>'0');
				bitslipDoneSync1 <= (others=>'0');
				bitslipDoneSync2 <= (others=>'0');
				allBitslipDone <= '0';
				bitslipDoneLatched <= (others=>'0');
				bitslipPatternOverride <= '0';
			else
				bitslipDoneSync1 <= bitslipDone & bitslipDoneSync1(bitslipDoneSync1'length-1 downto 1);
				bitslipDoneSync2 <= bitslipDone_TPTHRU_TIG(1) & bitslipDoneSync2(bitslipDoneSync2'length-1 downto 1);
				
				--bitslipDoneLatched(0) <= bitslipDone(0) or bitslipDoneLatched(0);
				bitslipDoneLatched <= bitslipDone or bitslipDoneLatched;
				
				allBitslipDone <= bitslipDoneLatched(2) and bitslipDoneLatched(1) and bitslipDoneLatched(0);

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
						message <= "111111" & MSG_write_softReset;
						spiTransfer <= '1'; -- autoreset
						if(spiDone = '1') then
							stateAdc <= init3;
							spiTransfer <= '0'; -- autoreset
						end if;
					
					when init3 =>
						message <= "111111" & MSG_write_formatAndPower;
						spiTransfer <= '1'; -- autoreset
						if(spiDone = '1') then
							stateAdc <= init4;
							spiTransfer <= '0'; -- autoreset
						end if;
						
					when init4 =>
						message <= "111111" & MSG_write_outputMode;
						spiTransfer <= '1'; -- autoreset
						if(spiDone = '1') then
							stateAdc <= init5;
							spiTransfer <= '0'; -- autoreset
						end if;
						
					when init5 =>
						if(registerWrite.testMode = x"1") then
							message <= "111111" & MSG_write_testPatternXLow & registerWrite.testPattern(7 downto 0);
						else
							--message <= "0" & MSG_write_testPatternOffLow;
							message <= "111111" & MSG_write_testPatternBitslipLow;
						end if;
						spiTransfer <= '1'; -- autoreset
						if(spiDone = '1') then
							stateAdc <= init6;
							spiTransfer <= '0'; -- autoreset
						end if;

					when init6 =>
						if(registerWrite.testMode = x"1") then
							message <= "111111" & MSG_write_testPatternXHigh & registerWrite.testPattern(13 downto 8);
						else
							--message <= "0" & MSG_write_testPatternOffHigh;
							message <= "111111" & MSG_write_testPatternBitslipHigh;
						end if;
						spiTransfer <= '1'; -- autoreset
						if(spiDone = '1') then
							stateAdc <= init7;
							spiTransfer <= '0'; -- autoreset
						end if;

					when init7 =>
						if(registerWrite.testMode = x"1") then
							stateAdc <= idle;
						else
							stateAdc <= init8;
							timeoutBitslip <= x"0000";
						end if;
					
					when init8 =>
						timeoutBitslip <= timeoutBitslip + 1;
						if(timeoutBitslip = x"ffff") then
							stateAdc <= init9;
							timeoutBitslip <= x"0000";
						end if;
						if(timeoutBitslip > x"fff0") then
							bitslipStartFromInit <= '1'; -- autoreset	
							bitslipPatternOverride <= '1';
							allBitslipDone <= '0';
							bitslipDoneLatched <= (others=>'0');
						end if;
					
					when init9 =>
						timeoutBitslip <= timeoutBitslip + 1;
						if(timeoutBitslip = x"ffff") then
							stateAdc <= init8;
							timeoutBitslip <= x"0000";
						end if;
						if(allBitslipDone = '1') then
							bitslipPatternOverride <= '0';
							stateAdc <= init10;
							timeoutBitslip <= x"0000";
						end if;

					when init10 =>
						message <= "111111" & MSG_write_testPatternOffHigh;
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
	
	





end Behavioral;

