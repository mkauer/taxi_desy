----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:49:07 03/09/2017 
-- Design Name: 
-- Module Name:    eventFifoSystem - Behavioral 
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
use IEEE.NUMERIC_STD.ALL;
use work.types.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity eventFifoSystem is
	port(
		newEvent : in std_logic;
		pps : in std_logic;
		triggerTiming : in triggerTiming_t;
		dsr4Timing : in dsr4Timing_t;
		dsr4Sampling : in dsr4Sampling_t;
		dsr4Charge : in dsr4Charge_t;
		gpsTiming : in gpsTiming_t;
		registerRead : out eventFifoSystem_registerRead_t;
		registerWrite : in eventFifoSystem_registerWrite_t	
		);
end eventFifoSystem;

architecture behavioral of eventFifoSystem is

	signal eventFifoWriteRequest : std_logic := '0';
	signal eventFifoReadRequest : std_logic := '0';
	signal eventFifoFull : std_logic := '0';
	signal eventFifoEmpty : std_logic := '0';
	signal eventFifoClear : std_logic := '0';
	signal eventFifoOverflow : std_logic := '0';
	signal eventFifoUnderflow : std_logic := '0';
	signal eventFifoWords : std_logic_vector(15 downto 0) := (others=>'0');
	signal eventFifoIn : std_logic_vector(16*9-1 downto 0) := (others=>'0');
	signal eventFifoOut : std_logic_vector(16*9-1 downto 0) := (others=>'0');
	
	signal eventFifoClearBuffer : std_logic := '0';
	signal eventFifoClearBuffer_old : std_logic := '0';
	signal eventFifoClearCounter : integer range 0 to 7 := 0;
	
	signal dmaBuffer : std_logic_vector(15 downto 0) := (others=>'0');
	signal eventFifoWordsDma : std_logic_vector(15 downto 0) := (others=>'0');
--	signal dmaLookAheadIsIdle : std_logic := '0';
	signal s : integer range 0 to 63 := 0;
	
	type state1_t is (wait0, idle, writeSecondInfo, writeHeader, writeDebug, writeTriggerTiming, writeDsr4Sampling, writeDsr4Charge, writeDsr4Timing);
	signal state1 : state1_t := idle;
	
	type state7_t is (wait0, wait1, idle, read0, read1, read2, read3);
	signal state7 : state7_t := wait0;
	
	signal eventFifoErrorCounter : unsigned(15 downto 0) := (others=>'0');
	constant eventFifoWordsMax : unsigned(15 downto 0) := to_unsigned(1024,16);
	
	signal eventCount : unsigned(32 downto 0) := (others=>'0');
	signal counterSecounds : unsigned(32 downto 0) := (others=>'0'); -- move
	signal realTimeCounterSecounds : unsigned(32 downto 0) := (others=>'0'); -- move
	signal realTimeCounterSubSecounds : unsigned(32 downto 0) := (others=>'0'); -- move

	signal eventLength : unsigned(15 downto 0) := (others=>'0');
	signal eventFifoFull_old : std_logic := '0';
	signal eventFifoOverflow_old : std_logic := '0';
	signal eventFifoUnderflow_old : std_logic := '0';
	signal eventFifoOverflowCounter : unsigned(15 downto 0) := (others=>'0');
	signal eventFifoUnderflowCounter : unsigned(15 downto 0) := (others=>'0');
	signal eventFifoFullCounter : unsigned(15 downto 0) := (others=>'0');
	
	constant DATATYPE_HEADER : std_logic_vector(5 downto 0) := x"1" & "00";
	constant DATATYPE_DEBUG : std_logic_vector(5 downto 0) := x"2" & "00";
	constant DATATYPE_TRIGGERTIMING : std_logic_vector(5 downto 0) := x"3" & "00";
	constant DATATYPE_DSR4SAMPLING : std_logic_vector(5 downto 0) := x"4" & "00";
	constant DATATYPE_DSR4CHARGE : std_logic_vector(5 downto 0) := x"5" & "00";
	constant DATATYPE_DSR4TIMING : std_logic_vector(5 downto 0) := x"6" & "00";
	constant DATATYPE_DATAPERSECOND : std_logic_vector(5 downto 0) := x"7" & "00";
	constant DATATYPE_TESTDATA_STATICEVENTFIFOHEADER : std_logic_vector(5 downto 0) := x"a" & "00";
	constant DATATYPE_TESTDATA_COUNTEREVENTFIFOHEADER : std_logic_vector(5 downto 0) := x"b" & "00";
	
	signal nextWord : std_logic := '0';
	signal packetConfig : std_logic_vector(15 downto 0);
--	alias writeDsr4TimingToFifo_bit : std_logic is packetConfig(0);
	alias writeDsr4TimingToFifo_bit_v : std_logic_vector(0 downto 0) is packetConfig(0 downto 0);
--	alias writeDsr4ChargeToFifo_bit : std_logic is packetConfig(1);
	alias writeDsr4ChargeToFifo_bit_v : std_logic_vector(0 downto 0) is packetConfig(1 downto 1);
--	alias writeDsr4SamplingToFifo_bit : std_logic is packetConfig(2);
	alias writeDsr4SamplingToFifo_bit_v : std_logic_vector(0 downto 0) is packetConfig(2 downto 2);
--	alias writeDebugToFifo_bit : std_logic is packetConfig(3);
	alias writeDebugToFifo_bit_v : std_logic_vector(0 downto 0) is packetConfig(3 downto 3);
	alias testDataEventFifoStatic_bit : std_logic is packetConfig(8);
	alias testDataEventFifoCounter_bit : std_logic is packetConfig(9);
	alias testDataFrondEndFifo_bit : std_logic is packetConfig(10);
	
	signal registerSamplesToRead : std_logic_vector(15 downto 0) := x"0001"; -- ## dummy
	signal registerDeviceId : std_logic_vector(15 downto 0) := x"a5a5"; -- ## dummy
--	signal packetConfig : std_logic_vector(15 downto 0) := x"0000";
	
begin

	l: entity work.eventFifo
	port map (
		clk => registerWrite.clock,
		rst => eventFifoClear,
		din => eventFifoIn,
		wr_en => eventFifoWriteRequest,
		rd_en => eventFifoReadRequest,
		dout => eventFifoOut,
		full => eventFifoFull,
		overflow => eventFifoOverflow,
		empty => eventFifoEmpty,
		underflow => eventFifoUnderflow,
		data_count => eventFifoWords(9 downto 0)
	);
	
	eventFifoWords(10) <= eventFifoFull and not(eventFifoClearBuffer); -- ## has side effecs after fifoClear
	
	registerRead.dmaBuffer <= dmaBuffer;
	registerRead.eventFifoWordsDma <= eventFifoWordsDma;
	nextWord <= registerWrite.nextWord;
	
	packetConfig <= registerWrite.packetConfig;
	registerRead.packetConfig <= registerWrite.packetConfig;
	registerRead.eventFifoErrorCounter <= std_logic_vector(eventFifoErrorCounter);
	
P1:process (registerWrite.clock)
	constant HEADER_LENGTH : integer := 1;
	constant CHARGE_LENGTH : integer := 1;
	constant TXT_LENGTH : integer := 1;
	constant SLOT_WIDTH : integer := 16;
	variable tempLength : unsigned(15 downto 0);
begin
	if rising_edge(registerWrite.clock) then
		eventFifoWriteRequest <= '0'; -- autoreset
	
		if (registerWrite.reset = '1') then
			eventFifoClear <= '1';
			eventFifoClearBuffer <= '1';
			eventFifoClearBuffer_old <= '0';
			state1 <= idle;
			eventLength <= to_unsigned(0,eventLength'length);
			eventFifoErrorCounter <= to_unsigned(0,eventFifoErrorCounter'length);
			eventCount <= (others=>'0');
		else
			eventFifoClear <= registerWrite.eventFifoClear;
			eventFifoClearBuffer <= registerWrite.eventFifoClear;
			
			-- hide 'eventFifoFull' for dmaBuffer
			eventFifoClearBuffer_old <= eventFifoClearBuffer;
			if((eventFifoClearBuffer = '1') and (eventFifoClearBuffer_old = '0')) then
				eventFifoClearCounter <= 7;
			else
				if(eventFifoClearCounter > 0) then
					eventFifoClearCounter <= eventFifoClearCounter - 1;
				else
					eventFifoClearBuffer <= '0';
				end if;
			end if;
			
			case state1 is
				when wait0 =>
					if(newEvent = '0') then
						state1 <= idle;
					end if;
					
				when idle =>
					if(newEvent = '1') then
						state1 <= writeHeader;
						tempLength := to_unsigned(0,tempLength'length) + HEADER_LENGTH + unsigned(writeDebugToFifo_bit_v) + unsigned(writeDsr4SamplingToFifo_bit_v) + unsigned(writeDsr4ChargeToFifo_bit_v) + unsigned(writeDsr4TimingToFifo_bit_v); -- ## is this efficient?!
						if(writeDsr4SamplingToFifo_bit_v = "1") then
							eventLength <= unsigned(registerSamplesToRead) + tempLength;
						else
							eventLength <= tempLength;
						end if;
					end if;
					if(pps = '1') then
						state1 <= writeSecondInfo;
					end if;
				
				when writeSecondInfo =>
					if(unsigned(eventFifoWords) < (eventFifoWordsMax)) then
						eventFifoIn <= (others=>'0');
						eventFifoIn(0*SLOT_WIDTH+SLOT_WIDTH-1 downto 0*SLOT_WIDTH) <= DATATYPE_DATAPERSECOND & "00" & x"00";
						eventFifoIn(1*SLOT_WIDTH+SLOT_WIDTH-1 downto 1*SLOT_WIDTH) <= gpsTiming.week;
						eventFifoIn(2*SLOT_WIDTH+SLOT_WIDTH-1 downto 2*SLOT_WIDTH) <= gpsTiming.timeOfWeekMilliSecond(31 downto 16);
						eventFifoIn(3*SLOT_WIDTH+SLOT_WIDTH-1 downto 3*SLOT_WIDTH) <= gpsTiming.timeOfWeekMilliSecond(15 downto 0);
						eventFifoIn(4*SLOT_WIDTH+SLOT_WIDTH-1 downto 4*SLOT_WIDTH) <= gpsTiming.quantizationError(31 downto 16);
						eventFifoIn(5*SLOT_WIDTH+SLOT_WIDTH-1 downto 5*SLOT_WIDTH) <= gpsTiming.quantizationError(15 downto 0);
						eventFifoIn(6*SLOT_WIDTH+SLOT_WIDTH-1 downto 6*SLOT_WIDTH) <= gpsTiming.differenceGpsToLocalClock;
						--eventFifoIn(7*SLOT_WIDTH+SLOT_WIDTH-1 downto 7*SLOT_WIDTH) <= gpsTiming.
						--eventFifoIn(8*SLOT_WIDTH+SLOT_WIDTH-1 downto 8*SLOT_WIDTH) <= registerDeviceId;
					else
						eventFifoErrorCounter <= eventFifoErrorCounter + 1;
					end if;
					state1 <= idle;
					
				when writeHeader =>
					if(unsigned(eventFifoWords) < (eventFifoWordsMax - eventLength)) then
						eventFifoIn <= (others=>'0');
						--eventFifoIn(0*SLOT_WIDTH+SLOT_WIDTH-1 downto 0*SLOT_WIDTH) <= DATATYPE_HEADER & "00" & x"00";
						eventFifoIn(1*SLOT_WIDTH+SLOT_WIDTH-1 downto 1*SLOT_WIDTH) <= std_logic_vector(eventCount(31 downto 16));
						eventFifoIn(2*SLOT_WIDTH+SLOT_WIDTH-1 downto 2*SLOT_WIDTH) <= std_logic_vector(eventCount(15 downto 0));
						eventFifoIn(3*SLOT_WIDTH+SLOT_WIDTH-1 downto 3*SLOT_WIDTH) <= std_logic_vector(eventLength);
						--eventFifoIn(4*SLOT_WIDTH+SLOT_WIDTH-1 downto 4*SLOT_WIDTH) <= std_logic_vector(realTimeCounterSecounds(31 downto 16)); -- unsigned unix time or gps time (32bit week+sec)
						--eventFifoIn(5*SLOT_WIDTH+SLOT_WIDTH-1 downto 5*SLOT_WIDTH) <= std_logic_vector(realTimeCounterSecounds(15 downto 0));
						eventFifoIn(6*SLOT_WIDTH+SLOT_WIDTH-1 downto 6*SLOT_WIDTH) <= std_logic_vector(realTimeCounterSubSecounds(31 downto 16)); -- not 1ns but ~1.05263ns per tick
						eventFifoIn(7*SLOT_WIDTH+SLOT_WIDTH-1 downto 7*SLOT_WIDTH) <= std_logic_vector(realTimeCounterSubSecounds(15 downto 0));
						eventFifoIn(8*SLOT_WIDTH+SLOT_WIDTH-1 downto 8*SLOT_WIDTH) <= registerDeviceId; -- ## can be moved
							
						if(testDataEventFifoStatic_bit = '1') then
							eventFifoIn(0*SLOT_WIDTH+SLOT_WIDTH-1 downto 0*SLOT_WIDTH) <= DATATYPE_TESTDATA_STATICEVENTFIFOHEADER & "00" & x"00"; -- ## not implemented...
						elsif(testDataEventFifoCounter_bit = '1') then
							eventFifoIn(0*SLOT_WIDTH+SLOT_WIDTH-1 downto 0*SLOT_WIDTH) <= DATATYPE_TESTDATA_COUNTEREVENTFIFOHEADER & "00" & x"00"; -- ## not implemented...
						else
							eventFifoIn(0*SLOT_WIDTH+SLOT_WIDTH-1 downto 0*SLOT_WIDTH) <= DATATYPE_HEADER & "00" & x"00"; -- ## 'unknown' as default would be better						
						end if;
						eventFifoWriteRequest <= '1'; -- autoreset
						state1 <= writeDebug;
					-- ## maybe we can save some LEs here if the assignment of eventFifoIn is changed
					
						eventCount <= eventCount + 1;
						
					else
						state1 <= wait0;
						eventFifoErrorCounter <= eventFifoErrorCounter + 1;
					end if;
				
				when writeDebug =>
					eventFifoIn <= (others=>'0');
					eventFifoIn(0*SLOT_WIDTH+SLOT_WIDTH-1 downto 0*SLOT_WIDTH) <= DATATYPE_DEBUG & "00" & x"00";
					eventFifoIn(1*SLOT_WIDTH+SLOT_WIDTH-1 downto 1*SLOT_WIDTH) <= std_logic_vector(eventFifoFullCounter);
					eventFifoIn(2*SLOT_WIDTH+SLOT_WIDTH-1 downto 2*SLOT_WIDTH) <= std_logic_vector(eventFifoOverflowCounter);
					eventFifoIn(3*SLOT_WIDTH+SLOT_WIDTH-1 downto 3*SLOT_WIDTH) <= std_logic_vector(eventFifoUnderflowCounter);
					eventFifoIn(4*SLOT_WIDTH+SLOT_WIDTH-1 downto 4*SLOT_WIDTH) <= std_logic_vector(eventFifoErrorCounter); 
					--eventFifoIn(5*SLOT_WIDTH+SLOT_WIDTH-1 downto 5*SLOT_WIDTH) <= x"0000"; -- 
					--eventFifoIn(6*SLOT_WIDTH+SLOT_WIDTH-1 downto 6*SLOT_WIDTH) <= x"0000"; -- 
					--eventFifoIn(7*SLOT_WIDTH+SLOT_WIDTH-1 downto 7*SLOT_WIDTH) <= x"0000"; -- 
					--eventFifoIn(8*SLOT_WIDTH+SLOT_WIDTH-1 downto 8*SLOT_WIDTH) <= x"0000"; -- some masks...
					eventFifoWriteRequest <= '1'; -- autoreset
					state1 <= writeTriggerTiming;
					
				when writeTriggerTiming =>
					if(triggerTiming.newData = '1') then
						eventFifoIn <= (others=>'0');
						eventFifoIn(0*SLOT_WIDTH+SLOT_WIDTH-1 downto 0*SLOT_WIDTH) <= DATATYPE_TRIGGERTIMING & "00" & x"00";
						eventFifoIn(1*SLOT_WIDTH+SLOT_WIDTH-1 downto 1*SLOT_WIDTH) <= triggerTiming.ch0;
						eventFifoIn(2*SLOT_WIDTH+SLOT_WIDTH-1 downto 2*SLOT_WIDTH) <= triggerTiming.ch1;
						eventFifoIn(3*SLOT_WIDTH+SLOT_WIDTH-1 downto 3*SLOT_WIDTH) <= triggerTiming.ch2;
						eventFifoIn(4*SLOT_WIDTH+SLOT_WIDTH-1 downto 4*SLOT_WIDTH) <= triggerTiming.ch3;
						eventFifoIn(5*SLOT_WIDTH+SLOT_WIDTH-1 downto 5*SLOT_WIDTH) <= triggerTiming.ch4;
						eventFifoIn(6*SLOT_WIDTH+SLOT_WIDTH-1 downto 6*SLOT_WIDTH) <= triggerTiming.ch5;
						eventFifoIn(7*SLOT_WIDTH+SLOT_WIDTH-1 downto 7*SLOT_WIDTH) <= triggerTiming.ch6;
						eventFifoIn(8*SLOT_WIDTH+SLOT_WIDTH-1 downto 8*SLOT_WIDTH) <= triggerTiming.ch7;
						eventFifoWriteRequest <= '1'; -- autoreset
						state1 <= writeDsr4Sampling;
					end if;
				
				when writeDsr4Sampling =>
					if(dsr4Sampling.newData = '1') then
						eventFifoIn <= (others=>'0');
						eventFifoIn(0*SLOT_WIDTH+SLOT_WIDTH-1 downto 0*SLOT_WIDTH) <= DATATYPE_DSR4SAMPLING & "00" & x"00";
						-- ## not implemented...
						eventFifoWriteRequest <= '1'; -- autoreset
					end if;

					if(dsr4Sampling.samplingDone = '1') then
						state1 <= writeDsr4Charge;
					end if;
					
				when writeDsr4Charge =>
					if(dsr4Charge.newData = '1') then
						eventFifoIn <= (others=>'0');
						eventFifoIn(0*SLOT_WIDTH+SLOT_WIDTH-1 downto 0*SLOT_WIDTH) <= DATATYPE_DSR4CHARGE & "00" & x"00";
						-- ## not implemented...
						eventFifoWriteRequest <= '1'; -- autoreset
					end if;
					
					if(dsr4Charge.chargeDone = '1') then
						state1 <= writeDsr4Timing;
					end if;
					
				when writeDsr4Timing =>
					if(dsr4Timing.newData = '1') then
						eventFifoIn <= (others=>'0');
						eventFifoIn(0*SLOT_WIDTH+SLOT_WIDTH-1 downto 0*SLOT_WIDTH) <= DATATYPE_DSR4TIMING & "00" & x"00";
						-- ## not implemented...
						eventFifoWriteRequest <= '1'; -- autoreset
					end if;
					
					if(dsr4Timing.timingDone = '1') then
						state1 <= idle;
					end if;
				
				when others =>
					state1 <= idle;
			end case;	
			
		end if;
	end if;
end process P1;


-- ## todo: implement a 16Bit counting fifoWordCount to look like a real 16Bit per word fifo....
P2:process (registerWrite.clock)
	variable lookAheadWord : std_logic := '0';
begin
	if rising_edge(registerWrite.clock) then
		eventFifoReadRequest <= '0'; -- autoreset
		if (registerWrite.reset = '1') then
			state7 <= wait0;
			dmaBuffer <= x"0000";
			lookAheadWord := '0';
			eventFifoWordsDma <= x"0000";
--			dmaLookAheadIsIdle <= '1';
			s <= 0;
		else		
			case state7 is
				when wait0 =>
					state7 <= wait1;
					
				when wait1 =>
					state7 <= idle;
					
				when idle =>
					if (eventFifoWords /= x"0000") then
						state7 <= read0;
						eventFifoReadRequest <= '1'; -- autoreset
					else
						dmaBuffer <= x"0000";
						lookAheadWord := '0'; -- ## ?!?!?!?!?! variable?
					end if;
					
				when read0 =>
					state7 <= read1;
					
				when read1 =>
					--dmaBuffer <= eventFifoOut(eventFifoOut'length-1 downto eventFifoOut'length-16);
					dmaBuffer <= eventFifoOut(0*16+16-1 downto 16*0);
					s <= 1;
					lookAheadWord := '1';
					state7 <= read2;
					
				when read2 =>
					if (nextWord = '1') then
						dmaBuffer <= eventFifoOut(s*16+16-1 downto 16*s);
						s <= s + 1;
						state7 <= read3;
					end if;
					
				when read3 =>
					if (nextWord = '0') then
						state7 <= read2;
						if (s > 9) then
							if (eventFifoWords /= x"0000") then
								state7 <= read0;
								eventFifoReadRequest <= '1'; -- autoreset
							else
								state7 <= idle;
							end if;
						end if;
					end if;
					
				when others => null;
			end case;
			
			if (lookAheadWord = '1') then
				eventFifoWordsDma <= std_logic_vector(unsigned(eventFifoWords) + 1);
				--dmaLookAheadIsIdle <= '0';
			else
				eventFifoWordsDma <= eventFifoWords;
				--dmaLookAheadIsIdle <= '1';
			end if;
			
--			if(registerResetFifos(1) = '1') then
--				s <= 0;
--				state7 <= wait0;
--				--fifoWasEmpty <= '1';
--			end if;
			
		end if;
	end if;
end process P2;

P3:process (registerWrite.clock)
begin
	if rising_edge(registerWrite.clock) then
		if (registerWrite.reset = '1') then
			counterSecounds <= to_unsigned(0,counterSecounds'length);
			realTimeCounterSecounds <= to_unsigned(0,realTimeCounterSecounds'length);
			realTimeCounterSubSecounds <= to_unsigned(0,realTimeCounterSubSecounds'length);
		else
		
			counterSecounds <= counterSecounds + 1;
			if(counterSecounds >= to_unsigned(118750000,counterSecounds'length)) then
				counterSecounds <= to_unsigned(0,counterSecounds'length);
				realTimeCounterSecounds <= realTimeCounterSecounds + 1;
				realTimeCounterSubSecounds <= to_unsigned(0,realTimeCounterSubSecounds'length);
			else
				realTimeCounterSubSecounds <= realTimeCounterSubSecounds + 8;
			end if;			
		end if;
	end if;
end process P3;

registerRead.eventFifoFullCounter <= std_logic_vector(eventFifoFullCounter);
registerRead.eventFifoOverflowCounter <= std_logic_vector(eventFifoOverflowCounter);
registerRead.eventFifoUnderflowCounter <= std_logic_vector(eventFifoUnderflowCounter);
registerRead.eventFifoWords <= std_logic_vector(eventFifoWords);
registerRead.eventFifoFlags <= x"000" & eventFifoOverflow & eventFifoUnderflow & eventFifoEmpty & eventFifoFull;

P4:process (registerWrite.clock)
begin
	if rising_edge(registerWrite.clock) then
		if (registerWrite.reset = '1') then
			eventFifoFullCounter <= to_unsigned(0,eventFifoFullCounter'length);
			eventFifoOverflowCounter <= to_unsigned(0,eventFifoOverflowCounter'length);
			eventFifoUnderflowCounter <= to_unsigned(0,eventFifoUnderflowCounter'length);
			eventFifoOverflow_old <= '0';
			eventFifoUnderflow_old <= '0';
			eventFifoFull_old <= '0';
		else
		
			eventFifoOverflow_old <= eventFifoOverflow;
			eventFifoUnderflow_old <= eventFifoUnderflow;
			eventFifoFull_old <= eventFifoFull;
			
			if((eventFifoOverflow_old = '0') and (eventFifoOverflow = '1')) then
				eventFifoOverflowCounter <= eventFifoOverflowCounter + 1;
			end if;
			
			if((eventFifoUnderflow_old = '0') and (eventFifoUnderflow = '1')) then
				eventFifoUnderflowCounter <= eventFifoUnderflowCounter + 1;
			end if;
			
			if((eventFifoFull_old = '0') and (eventFifoFull = '1')) then
				eventFifoFullCounter <= eventFifoFullCounter + 1;
			end if;
			
		end if;
	end if;
end process P4;

end behavioral;