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
		
		adcDataValid : in std_logic;

		drs4Clocks : in drs4Clocks_t;
		drs4Fifo : out drs4Fifo_t;
		
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
	
	type stateAdcFifo_t is (sync1, sync2, sample1, sample2);
	signal stateAdcFifoA : stateAdcFifo_t := sync1;
	signal stateAdcFifoB : stateAdcFifo_t := sync1;

	signal fifoWriteEnableA : std_logic := '0';
	signal fifoWriteEnableB : std_logic := '0';
	signal fifoReadEnableA : std_logic := '0';
	signal fifoReadEnableB : std_logic := '0';
	signal fifoResetA : std_logic := '0';
	signal fifoResetB : std_logic := '0';

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
	constant MSG_write_testPatternOffHight : std_logic_vector(15 downto 0) := "0" & "0000011" & "00000011";
	--constant MSG_write_testPatternOnHight : std_logic_vector(15 downto 0) := "0" & "0000011" & "10000011";
	--constant MSG_write_testPatternLow : std_logic_vector(15 downto 0) := "0" & "0000100" & "11001101";
	constant MSG_write_testPatternOnHight : std_logic_vector(15 downto 0) := "0" & "0000011" & "10010101";
	constant MSG_write_testPatternLow : std_logic_vector(15 downto 0) := "0" & "0000100" & "01010101";
	type stateAdc_t is (idle,init1,init2,init3,init4,init5,init6,init7,init8,init9,init10,init11);
	signal stateAdc : stateAdc_t := idle;
	
begin
	
	adcDataGroupA_p <= adcDataA_p(6) & adcDataA_p(4) & adcDataA_p(2) & adcDataA_p(0);
	adcDataGroupA_n <= adcDataA_n(6) & adcDataA_n(4) & adcDataA_n(2) & adcDataA_n(0);
	adcDataGroupB_p <= adcDataA_p(7) & adcDataA_p(5) & adcDataA_p(3) & adcDataA_p(1);
	adcDataGroupB_n <= adcDataA_n(7) & adcDataA_n(5) & adcDataA_n(3) & adcDataA_n(1);
	
	reset <= registerWrite.reset;

	--x100: entity work.serdes_1_to_n_clk_ddr_s8_diff generic map(7, false) port map(dataClockA_p, dataClockA_n, ioClockA_p, ioClockA_n, serdesStrobeA, serdesDivClockA);
	--x101: entity work.serdes_1_to_n_data_ddr_s8_diff generic map(7,4,false,"PER_CHANL") port map('1', adcDataGroupA_p, adcDataGroupA_n, ioClockA_p, ioClockA_n, serdesStrobeA, reset, serdesDivClockA, '0', dataOutGroupA, "00", open);
	--x101: entity work.serdes_1_to_n_data_ddr_s8_diff generic map(7,4,false,"PER_CHANL") port map('1', adcDataGroupA_p, adcDataGroupA_n, ioClockA_p, ioClockA_n, adcClocks.serdesStrobe, reset, adcClocks.serdesDivClock, '0', dataOutGroupA, "00", open);
	--x102: entity work.serdes_1_to_n_data_ddr_s8_diff generic map(7,1,false,"PER_CHANL") port map('1', frameA_p, frameA_n, ioClockA_p, ioClockA_n, serdesStrobeA, reset, serdesDivClockA, '0', frameOutGroupA, "00", open);

	--x104: entity work.serdes_1_to_n_clk_ddr_s8_diff generic map(7, false) port map(dataClockB_p, dataClockB_n, ioClockB_p, ioClockB_n, serdesStrobeB, serdesDivClockB);
	--x105: entity work.serdes_1_to_n_data_ddr_s8_diff generic map(7,4,false,"PER_CHANL") port map('1', adcDataGroupB_p, adcDataGroupB_n, ioClockB_p, ioClockB_n, serdesStrobeB, reset, serdesDivClockB, '0', dataOutGroupB, "00", open);
	--x105: entity work.serdes_1_to_n_data_ddr_s8_diff generic map(7,4,false,"PER_CHANL") port map('1', adcDataGroupB_p, adcDataGroupB_n, ioClockB_p, ioClockB_n, adcClocks.serdesStrobe, reset, adcClocks.serdesDivClock, '0', dataOutGroupB, "00", open);
	--x106: entity work.serdes_1_to_n_data_ddr_s8_diff generic map(7,1,false,"PER_CHANL") port map('1', frameB_p, frameB_n, ioClockA_p, ioClockA_n, serdesStrobeA, reset, serdesDivClockA, '0', frameOutGroupB, "00", open);
	
	x6: entity work.serdesIn_1to7 generic map(7,4,false,"PER_CHANL") port map('1', adcDataGroupA_p, adcDataGroupA_n, reset, adcClocks, '0', "00", dataOutGroupA, open);
	x7: entity work.serdesIn_1to7 generic map(7,4,false,"PER_CHANL") port map('1', adcDataGroupB_p, adcDataGroupB_n, reset, adcClocks, '0', "00", dataOutGroupB, open);

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
		empty => open,
		valid => open,
		underflow => eventFifoUnderflowA,
		rd_data_count => fifoWordsA(3 downto 0),
		wr_data_count => open
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
		empty => open,
		valid => open,
		underflow => eventFifoUnderflowB,
		rd_data_count => fifoWordsB(3 downto 0),
		wr_data_count => open
	);
	
	fifoReadClock <= registerWrite.clock;
	drs4Fifo.fifoOutA <= fifoOutA;
	drs4Fifo.fifoOutB <= fifoOutB;
	fifoWordsA(4) <= eventFifoFullA;
	fifoWordsB(4) <= eventFifoFullB;
	drs4Fifo.fifoWordsA <= fifoWordsA;
	drs4Fifo.fifoWordsB <= fifoWordsB;
	
	registerRead.testMode <= registerWrite.testMode;

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
			if (registerWrite.reset = '1') then				
				stateAdc <= idle;
				message <= (others=>'0');
			else

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
						if(registerWrite.testMode = '1') then
							message <= "0" & MSG_write_testPatternOnHight;
						else
							message <= "0" & MSG_write_testPatternOffHight;
						end if;
						spiTransfer <= '1'; -- autoreset
						if(spiDone = '1') then
							stateAdc <= init9;
							spiTransfer <= '0'; -- autoreset
						end if;
						
					when init9 =>
						if(registerWrite.testMode = '1') then
							message <= "0" & MSG_write_testPatternOnHight;
						else
							message <= "0" & MSG_write_testPatternOffHight;
						end if;
						spiTransfer <= '1'; -- autoreset
						if(spiDone = '1') then
							stateAdc <= init10;
							spiTransfer <= '0'; -- autoreset
						end if;
						
					when init10 =>
						message <= "0" & MSG_write_testPatternLow;
						spiTransfer <= '1'; -- autoreset
						if(spiDone = '1') then
							stateAdc <= init11;
							spiTransfer <= '0'; -- autoreset
						end if;

					when init11 =>
						message <= "1" & MSG_write_testPatternLow;
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

P10:process (adcClocks.serdesDivClock) -- ~66 MHz
begin
	if rising_edge(adcClocks.serdesDivClock) then
		fifoWriteEnableA <= '0'; -- autoreset
		if (registerWrite.reset = '1') then -- ## sync?!
			stateAdcFifoA <= sync1;
		else
						
			case stateAdcFifoA is				
				when sync1 =>
					-- set testbytes in adc ?!
					-- find start of values ?!
					-- use frame to pahseshift
					fifoResetA <= '1';
					stateAdcFifoA <= sync2;
					
				when sync2 =>
					-- timeout for fifo reset...
					stateAdcFifoA <= sample1;
				
				when sample1 =>
					stateAdcFifoA <= sample2;
					dataOutGroupA_buffer(14*4-1 downto 14*2) <= dataOutGroupA;	
					
				when sample2 =>
					stateAdcFifoA <= sample1;
					dataOutGroupA_buffer(14*2-1 downto 0) <= dataOutGroupA;
					fifoWriteEnableA <= adcDataValid; -- autoreset		
					
				when others => null;
			end case;
		end if;
	end if;
end process P10;
P11:process (adcClocks.serdesDivClock) -- ~66 MHz
begin
	if rising_edge(adcClocks.serdesDivClock) then
		fifoWriteEnableB <= '0'; -- autoreset
		if (registerWrite.reset = '1') then -- ## sync?!
			stateAdcFifoB <= sync1;
		else
						
			case stateAdcFifoB is				
				when sync1 =>
					-- set testbytes in adc ?!
					-- find start of values ?!
					-- use frame to pahseshift
					fifoResetB <= '1';
					stateAdcFifoB <= sync2;
					
				when sync2 =>
					-- timeout for fifo reset...
					stateAdcFifoB <= sample1;
				
				when sample1 =>
					stateAdcFifoB <= sample2;
					dataOutGroupB_buffer(14*4-1 downto 14*2) <= dataOutGroupB;	
					
				when sample2 =>
					stateAdcFifoB <= sample1;
					dataOutGroupB_buffer(14*2-1 downto 0) <= dataOutGroupB;
					fifoWriteEnableB <= adcDataValid; -- autoreset		
					
				when others => null;
			end case;
		end if;
	end if;
end process P11;

P4:process (registerWrite.clock)
begin
	if rising_edge(registerWrite.clock) then
		fifoReadEnableA <= '0'; -- autoreset
		fifoReadEnableB <= '0'; -- autoreset
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

			if(fifoWordsA > "00111") then
				fifoReadEnableA <= '1'; -- autoreset
				fifoReadEnableB <= '1'; -- autoreset
			end if;

			registerRead.fifoA <= fifoOutA;
			registerRead.fifoB <= fifoOutB;
			
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

