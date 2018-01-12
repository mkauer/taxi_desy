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
use work.lutAdder.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity eventFifoSystem is
	port(
		trigger : in triggerLogic_t;
		pps : in std_logic;
		irq2arm : out std_logic;
		triggerTiming : in triggerTiming_t;
		drs4Data : in ltm9007_14_to_eventFifoSystem_t;
		internalTiming : in internalTiming_t;
		gpsTiming : in gpsTiming_t;
		whiteRabbitTiming : in whiteRabbitTiming_t;
		pixelRateCounter : in pixelRateCounter_t;
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
	
--	signal eventFifoClearBuffer : std_logic := '0';
--	signal eventFifoClearBuffer_old : std_logic := '0';
	signal eventFifoClearCounter : integer range 0 to 7 := 0;
	
	signal dmaBuffer : std_logic_vector(15 downto 0) := (others=>'0');
	signal eventFifoWordsDma : std_logic_vector(15 downto 0) := (others=>'0');
	signal eventFifoWordsDmaAligned : std_logic_vector(15 downto 0) := (others=>'0');
	signal eventFifoWordsDmaSlice : std_logic_vector(3 downto 0) := (others=>'0');
	signal eventFifoWordsDma32 : std_logic_vector(31 downto 0) := (others=>'0');
--	signal dmaLookAheadIsIdle : std_logic := '0';
	signal s : integer range 0 to 63 := 0;
	
	type state1_t is (wait0, idle, writeGps, writeWhiteRabbit, writePixelRateCounter0, writePixelRateCounter1, writePixelRateCounter2, writeHeader, writeDebug, writeTriggerTiming, writeDrs4Sampling, writeDrs4Charge, writeDrs4Max, writeDrs4Baseline, writeDrs4Timing, testDataHeader, testData, waitForRoiData);
	signal state1 : state1_t := idle;
	
	type state7_t is (wait0, wait1, idle, read0, read1, read2, read3);
	signal state7 : state7_t := wait0;
	
	signal eventFifoErrorCounter : unsigned(15 downto 0) := (others=>'0');
	--constant eventFifoWordsMax : unsigned(15 downto 0) := to_unsigned(1024,16);
	--constant eventFifoWordsMax : unsigned(15 downto 0) := to_unsigned(4096,16);
	constant eventFifoWordsMax : unsigned(15 downto 0) := to_unsigned(8192,16);
	
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
	constant DATATYPE_PIXELRATES : std_logic_vector(5 downto 0) := x"2" & "00";
	constant DATATYPE_TRIGGERTIMING : std_logic_vector(5 downto 0) := x"3" & "00";
	constant DATATYPE_DSR4SAMPLING : std_logic_vector(5 downto 0) := x"4" & "00";
	constant DATATYPE_DSR4BASELINE : std_logic_vector(5 downto 0) := x"5" & "00";
	constant DATATYPE_DSR4CHARGE : std_logic_vector(5 downto 0) := x"6" & "00";
	constant DATATYPE_DSR4TIMING : std_logic_vector(5 downto 0) := x"7" & "00";
	constant DATATYPE_WHITERABBIT : std_logic_vector(5 downto 0) := x"8" & "00";
	constant DATATYPE_GPS : std_logic_vector(5 downto 0) := x"9" & "00";
	constant DATATYPE_TESTDATA_STATICEVENTFIFOHEADER : std_logic_vector(5 downto 0) := x"a" & "00";
	constant DATATYPE_TESTDATA_COUNTEREVENTFIFOHEADER : std_logic_vector(5 downto 0) := x"b" & "00";
	constant DATATYPE_TESTDATA_COUNTER : std_logic_vector(5 downto 0) := x"c" & "00";
	constant DATATYPE_DRS4MAX : std_logic_vector(5 downto 0) := x"d" & "00";
	constant DATATYPE_DEBUG : std_logic_vector(5 downto 0) := x"f" & "00";
	
	signal dataTypeCounter : unsigned(9 downto 0) := (others=>'0');
	
	signal nextWord : std_logic := '0';
	signal packetConfig : std_logic_vector(15 downto 0);
	 alias writeDrs4SamplingToFifo_bit : std_logic is packetConfig(0);
	 alias writeDrs4BaselineToFifo_bit : std_logic is packetConfig(1);
	 alias writeDrs4ChargeToFifo_bit : std_logic is packetConfig(2);
	 alias writeDrs4TimingToFifo_bit : std_logic is packetConfig(3);
	 alias writeDrs4MaxValueToFifo_bit : std_logic is packetConfig(4);
	 alias writeTriggerTimingToFifo_bit : std_logic is packetConfig(5);
	 alias testDataEventFifoStatic_bit : std_logic is packetConfig(8);
	 alias testDataEventFifoCounter_bit : std_logic is packetConfig(9);
	 alias writeWhiteRabbitToFifo_bit : std_logic is packetConfig(12);
	 alias writeGpsToFifo_bit : std_logic is packetConfig(13);
	 alias writePixelRatesToFifo_bit : std_logic is packetConfig(14);
	 alias writeDebugToFifo_bit : std_logic is packetConfig(15);
	
	signal registerSamplesToRead : std_logic_vector(15 downto 0) := x"0000";
	signal registerDeviceId : std_logic_vector(15 downto 0) := x"a5a5"; -- ## dummy
--	signal packetConfig : std_logic_vector(15 downto 0) := x"0000";
	
	signal testDataWords : unsigned(15 downto 0) := x"0000";
	signal testDataCounter : unsigned(12 downto 0) := (others=>'0'); --  range 0 to 2**16-1 := 0;
	signal fifoTestDataEnabled : std_logic := '0';
	signal triggerEvent : std_logic := '0';
	signal triggerEvent_old : std_logic := '0';
	signal newTriggerEvent : std_logic := '0';
	signal pixelRateCounterEvent : std_logic := '0';
	signal pixelRateCounterEvent_old : std_logic := '0';
	signal newPixelRateCounterEvent : std_logic := '0';
	
	signal eventsPerIRQcounter : unsigned(15 downto 0) := (others=>'0');
	signal irqCounter : integer range 0 to 65500 := 0;
	signal irqTimeoutCounter : integer range 0 to 8100 := 0;
	signal irqRequest : std_logic := '0';
	signal irqRequest_eventsPerCount : std_logic := '0';
	signal irqRequest_eventFifoWords : std_logic := '0';
	signal irqRequest_timeout : std_logic := '0';
	signal irqRequest_eventsPerCount_old : std_logic := '0';
	signal irqRequest_eventFifoWords_old : std_logic := '0';
	signal irqRequest_timeout_old : std_logic := '0';
	signal increaseEventCounter : std_logic := '0';
	
	type stateIrq_t is (idle, irqBlock);
	signal stateIrq : stateIrq_t := idle;
	
	signal chargeDone : std_logic := '0';
	signal chargePart : std_logic := '0';
	signal baselineDone : std_logic := '0';
	signal baselinePart : std_logic := '0';
	
	signal gpsEvent : std_logic := '0';
	signal gpsEvent_old : std_logic := '0';
	signal newGpsEvent : std_logic := '0';
	signal whiteRabbitEvent : std_logic := '0';
	signal whiteRabbitEvent_old : std_logic := '0';
	signal newWhiteRabbitEvent : std_logic := '0';
					
	signal pixelRateCounter_realTimeCounterLatched : std_logic_vector(63 downto 0) := (others=>'0');
	signal pixelRateCounter_realTimeDeltaCounterLatched : std_logic_vector(63 downto 0) := (others=>'0');
	
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
		data_count => eventFifoWords(12 downto 0)
	);
	
	eventFifoWords(13) <= eventFifoFull; -- and not(eventFifoClearBuffer); -- ## has side effecs after fifoClear
	eventFifoWords(15 downto 14) <= "00";
	
	registerRead.dmaBuffer <= dmaBuffer;
	registerRead.eventFifoWordsDma <= eventFifoWordsDma;
	registerRead.eventFifoWordsDmaAligned <= eventFifoWordsDmaAligned;
	registerRead.eventFifoWordsDmaSlice <= eventFifoWordsDmaSlice;
	registerRead.eventFifoWordsDma32 <= eventFifoWordsDma32;
	nextWord <= registerWrite.nextWord;
	
	packetConfig <= registerWrite.packetConfig;
	registerRead.packetConfig <= registerWrite.packetConfig;
	registerRead.eventsPerIrq <= registerWrite.eventsPerIrq;
	registerRead.irqAtEventFifoWords <= registerWrite.irqAtEventFifoWords;
	registerRead.eventsPerIrq <= registerWrite.eventsPerIrq;
	registerRead.enableIrq <= registerWrite.enableIrq;
	registerRead.irqStall <= registerWrite.irqStall;
	registerRead.eventFifoErrorCounter <= std_logic_vector(eventFifoErrorCounter);
	
	registerSamplesToRead <= registerWrite.registerSamplesToRead;
	registerRead.registerSamplesToRead <= registerWrite.registerSamplesToRead;
			
	triggerEvent <= trigger.triggerNotDelayed or trigger.softTrigger;
	gpsEvent <= gpsTiming.newData;
	whiteRabbitEvent <= whiteRabbitTiming.newData;
	pixelRateCounterEvent <= pixelRateCounter.newData;
	
P1:process (registerWrite.clock)
	constant HEADER_LENGTH : integer := 1;
	constant CHARGE_LENGTH : integer := 1;
	constant TXT_LENGTH : integer := 1;
	constant SLOT_WIDTH : integer := 16;
	variable tempLength : unsigned(15 downto 0);
	variable nextState : state1_t := idle;
	variable headerNeeded : std_logic;
begin
	if rising_edge(registerWrite.clock) then
		eventFifoWriteRequest <= '0'; -- autoreset
		increaseEventCounter <= '0'; -- autoreset
		headerNeeded := writeDrs4SamplingToFifo_bit or writeDrs4BaselineToFifo_bit or writeDrs4ChargeToFifo_bit or writeDrs4TimingToFifo_bit or writeTriggerTimingToFifo_bit; 
		if (registerWrite.reset = '1') then
			eventFifoClear <= '1';
			--eventFifoClearBuffer <= '1';
			--eventFifoClearBuffer_old <= '0';
			state1 <= idle;
			eventLength <= to_unsigned(0,eventLength'length);
			eventFifoErrorCounter <= to_unsigned(0,eventFifoErrorCounter'length);
			chargeDone <= '0';
			baselineDone <= '0';
			gpsEvent_old <= '0';
			newGpsEvent <= '0';
			whiteRabbitEvent_old <= '0';
			newWhiteRabbitEvent <= '0';
			triggerEvent_old <= '0';
			newTriggerEvent <= '0';
			pixelRateCounterEvent_old <= '0';
			newPixelRateCounterEvent <= '0';
			pixelRateCounter_realTimeCounterLatched <= (others=>'0');
			pixelRateCounter_realTimeDeltaCounterLatched <= (others=>'0');
		else
			eventFifoClear <= registerWrite.eventFifoClear;
			--eventFifoClearBuffer <= registerWrite.eventFifoClear;
		
			
			chargeDone <= chargeDone or drs4Data.chargeDone;
			baselineDone <= baselineDone or drs4Data.baselineDone;

			gpsEvent_old <= gpsEvent;
			if((gpsEvent = '1') and (gpsEvent_old = '0')) then
				newGpsEvent <= '1';
			end if;
					
			whiteRabbitEvent_old <= whiteRabbitEvent;
			if((whiteRabbitEvent = '1') and (whiteRabbitEvent_old = '0')) then
				newWhiteRabbitEvent <= '1';
			end if;
					
			triggerEvent_old <= triggerEvent;
			if((triggerEvent = '1') and (triggerEvent_old = '0')) then
				newTriggerEvent <= '1';
			end if;
			
			pixelRateCounterEvent_old <= pixelRateCounterEvent;
			if((pixelRateCounterEvent = '1') and (pixelRateCounterEvent_old = '0')) then
				newPixelRateCounterEvent <= '1';
			end if;


			case state1 is
				when idle =>
					if((newTriggerEvent = '1') and (headerNeeded = '1')) then
						state1 <= waitForRoiData;
						--tempLength := to_unsigned(0,tempLength'length)
						--	+ HEADER_LENGTH 
						--	+ unsigned(writeDebugToFifo_bit_v)
						--	--+ unsigned(writeDrs4SamplingToFifo_bit_v)
						--	+ unsigned(writeDrs4ChargeToFifo_bit_v)*2 
						--	+ unsigned(writeDrs4BaselineToFifo_bit_v)*2 
						--	+ unsigned(writeDrs4TimingToFifo_bit_v)
						--	+ unsigned(writeTriggerTimingToFifo_bit_v); -- ## is this efficient?! ## some types count more than 1
						
						tempLength := to_unsigned(HEADER_LENGTH,tempLength'length)
							+ lutAdder6(writeDebugToFifo_bit
								& writeDrs4ChargeToFifo_bit
								& writeDrs4ChargeToFifo_bit
								& writeDrs4BaselineToFifo_bit
								& writeDrs4BaselineToFifo_bit
								& writeDrs4TimingToFifo_bit)
							+ lutAdder6(writeTriggerTimingToFifo_bit
								& "00000");
						
						eventLength <= tempLength;
						
						if(writeDrs4SamplingToFifo_bit = '1') then
							eventLength <= unsigned(registerSamplesToRead) + tempLength;
						end if;
						if(testDataEventFifoCounter_bit = '1') then
							eventLength <= unsigned(registerSamplesToRead) + HEADER_LENGTH;
						end if;
					--	if(testDataEventFifoCounter_bit = '1')then
					--		state1 <= testDataHeader;
					--		testDataCounter <= (others=>'0');
					--		testDataWords <= to_unsigned(0,testDataWords'length);
					--	end if;
					end if;

					if((newGpsEvent = '1') and (writeGpsToFifo_bit = '1')) then
						state1 <= writeGps;
					end if;
					
					if((newWhiteRabbitEvent = '1') and (writeWhiteRabbitToFifo_bit = '1')) then
						state1 <= writeWhiteRabbit;
					end if;

					if((newPixelRateCounterEvent = '1') and (writePixelRatesToFifo_bit = '1')) then
						state1 <= writePixelRateCounter0;
					end if;

					dataTypeCounter <= (others=>'0'); -- ## not nice... should be a separate prepare state
					chargePart <= '0'; -- ## not nice...
					baselinePart <= '0'; -- ## not nice...
				
				when writePixelRateCounter0 => -- no timing information here....
					newPixelRateCounterEvent <= '0';
					nextState := writePixelRateCounter1;
					if(unsigned(eventFifoWords) < (eventFifoWordsMax-1)) then
						eventFifoIn <= (others=>'0');
						eventFifoIn(0*SLOT_WIDTH+SLOT_WIDTH-1 downto 0*SLOT_WIDTH) <= DATATYPE_PIXELRATES & "00" & x"00";
						eventFifoIn(1*SLOT_WIDTH+SLOT_WIDTH-1 downto 1*SLOT_WIDTH) <= pixelRateCounter.channelLatched(0);
						eventFifoIn(2*SLOT_WIDTH+SLOT_WIDTH-1 downto 2*SLOT_WIDTH) <= pixelRateCounter.channelLatched(1);
						eventFifoIn(3*SLOT_WIDTH+SLOT_WIDTH-1 downto 3*SLOT_WIDTH) <= pixelRateCounter.channelLatched(2);
						eventFifoIn(4*SLOT_WIDTH+SLOT_WIDTH-1 downto 4*SLOT_WIDTH) <= pixelRateCounter.channelLatched(3);
						eventFifoIn(5*SLOT_WIDTH+SLOT_WIDTH-1 downto 5*SLOT_WIDTH) <= pixelRateCounter.channelLatched(4);
						eventFifoIn(6*SLOT_WIDTH+SLOT_WIDTH-1 downto 6*SLOT_WIDTH) <= pixelRateCounter.channelLatched(5);
						eventFifoIn(7*SLOT_WIDTH+SLOT_WIDTH-1 downto 7*SLOT_WIDTH) <= pixelRateCounter.channelLatched(6);
						eventFifoIn(8*SLOT_WIDTH+SLOT_WIDTH-1 downto 8*SLOT_WIDTH) <= pixelRateCounter.channelLatched(7);
						eventFifoWriteRequest <= '1'; -- autoreset
					else
						eventFifoErrorCounter <= eventFifoErrorCounter + 1;
					end if;
					pixelRateCounter_realTimeCounterLatched <= pixelRateCounter.realTimeCounterLatched;
					pixelRateCounter_realTimeDeltaCounterLatched <= pixelRateCounter.realTimeDeltaCounterLatched;
					state1 <= nextState;

				when writePixelRateCounter1 => -- no timing information here....
					newPixelRateCounterEvent <= '0';
					nextState := writePixelRateCounter2;
					if(unsigned(eventFifoWords) < (eventFifoWordsMax-1)) then
						eventFifoIn <= (others=>'0');
						eventFifoIn(0*SLOT_WIDTH+SLOT_WIDTH-1 downto 0*SLOT_WIDTH) <= DATATYPE_PIXELRATES & "00" & x"01";
						eventFifoIn(1*SLOT_WIDTH+SLOT_WIDTH-1 downto 1*SLOT_WIDTH) <= pixelRateCounter.channelDeadTimeLatched(0);
						eventFifoIn(2*SLOT_WIDTH+SLOT_WIDTH-1 downto 2*SLOT_WIDTH) <= pixelRateCounter.channelDeadTimeLatched(1);
						eventFifoIn(3*SLOT_WIDTH+SLOT_WIDTH-1 downto 3*SLOT_WIDTH) <= pixelRateCounter.channelDeadTimeLatched(2);
						eventFifoIn(4*SLOT_WIDTH+SLOT_WIDTH-1 downto 4*SLOT_WIDTH) <= pixelRateCounter.channelDeadTimeLatched(3);
						eventFifoIn(5*SLOT_WIDTH+SLOT_WIDTH-1 downto 5*SLOT_WIDTH) <= pixelRateCounter.channelDeadTimeLatched(4);
						eventFifoIn(6*SLOT_WIDTH+SLOT_WIDTH-1 downto 6*SLOT_WIDTH) <= pixelRateCounter.channelDeadTimeLatched(5);
						eventFifoIn(7*SLOT_WIDTH+SLOT_WIDTH-1 downto 7*SLOT_WIDTH) <= pixelRateCounter.channelDeadTimeLatched(6);
						eventFifoIn(8*SLOT_WIDTH+SLOT_WIDTH-1 downto 8*SLOT_WIDTH) <= pixelRateCounter.channelDeadTimeLatched(7);
						eventFifoWriteRequest <= '1'; -- autoreset
					else
						eventFifoErrorCounter <= eventFifoErrorCounter + 1;
					end if;
					state1 <= nextState;

				when writePixelRateCounter2 =>
					--newPixelRateCounterEvent <= '0'; -- ## two times?!
					nextState := idle;
					if(unsigned(eventFifoWords) < (eventFifoWordsMax)) then
						eventFifoIn <= (others=>'0');
						eventFifoIn(0*SLOT_WIDTH+SLOT_WIDTH-1 downto 0*SLOT_WIDTH) <= DATATYPE_PIXELRATES & "00" & x"02";
						eventFifoIn(1*SLOT_WIDTH+SLOT_WIDTH-1 downto 1*SLOT_WIDTH) <= pixelRateCounter_realTimeCounterLatched(63 downto 48);
						eventFifoIn(2*SLOT_WIDTH+SLOT_WIDTH-1 downto 2*SLOT_WIDTH) <= pixelRateCounter_realTimeCounterLatched(47 downto 32);
						eventFifoIn(3*SLOT_WIDTH+SLOT_WIDTH-1 downto 3*SLOT_WIDTH) <= pixelRateCounter_realTimeCounterLatched(31 downto 16);
						eventFifoIn(4*SLOT_WIDTH+SLOT_WIDTH-1 downto 4*SLOT_WIDTH) <= pixelRateCounter_realTimeCounterLatched(15 downto 0); 
						eventFifoIn(5*SLOT_WIDTH+SLOT_WIDTH-1 downto 5*SLOT_WIDTH) <= pixelRateCounter_realTimeDeltaCounterLatched(63 downto 48);
						eventFifoIn(6*SLOT_WIDTH+SLOT_WIDTH-1 downto 6*SLOT_WIDTH) <= pixelRateCounter_realTimeDeltaCounterLatched(47 downto 32);
						eventFifoIn(7*SLOT_WIDTH+SLOT_WIDTH-1 downto 7*SLOT_WIDTH) <= pixelRateCounter_realTimeDeltaCounterLatched(31 downto 16);
						eventFifoIn(8*SLOT_WIDTH+SLOT_WIDTH-1 downto 8*SLOT_WIDTH) <= pixelRateCounter_realTimeDeltaCounterLatched(15 downto 0);
						eventFifoWriteRequest <= '1'; -- autoreset
					else
						eventFifoErrorCounter <= eventFifoErrorCounter + 1;
					end if;
					state1 <= nextState;

				when writeGps =>
					newGpsEvent <= '0';
					nextState := idle;
					if(unsigned(eventFifoWords) < (eventFifoWordsMax)) then
						eventFifoIn <= (others=>'0');
						eventFifoIn(0*SLOT_WIDTH+SLOT_WIDTH-1 downto 0*SLOT_WIDTH) <= DATATYPE_GPS & "00" & x"00";
						eventFifoIn(1*SLOT_WIDTH+SLOT_WIDTH-1 downto 1*SLOT_WIDTH) <= gpsTiming.week;
						eventFifoIn(2*SLOT_WIDTH+SLOT_WIDTH-1 downto 2*SLOT_WIDTH) <= gpsTiming.timeOfWeekMilliSecond(31 downto 16);
						eventFifoIn(3*SLOT_WIDTH+SLOT_WIDTH-1 downto 3*SLOT_WIDTH) <= gpsTiming.timeOfWeekMilliSecond(15 downto 0);
						eventFifoIn(4*SLOT_WIDTH+SLOT_WIDTH-1 downto 4*SLOT_WIDTH) <= gpsTiming.differenceGpsToLocalClock;
						--eventFifoIn(5*SLOT_WIDTH+SLOT_WIDTH-1 downto 5*SLOT_WIDTH) <= gpsTiming.quantizationError(31 downto 16);
						--eventFifoIn(6*SLOT_WIDTH+SLOT_WIDTH-1 downto 6*SLOT_WIDTH) <= gpsTiming.quantizationError(15 downto 0);
						eventFifoIn(5*SLOT_WIDTH+SLOT_WIDTH-1 downto 5*SLOT_WIDTH) <= gpsTiming.realTimeCounterLatched(63 downto 48);
						eventFifoIn(6*SLOT_WIDTH+SLOT_WIDTH-1 downto 6*SLOT_WIDTH) <= gpsTiming.realTimeCounterLatched(47 downto 32);
						eventFifoIn(7*SLOT_WIDTH+SLOT_WIDTH-1 downto 7*SLOT_WIDTH) <= gpsTiming.realTimeCounterLatched(31 downto 16);
						eventFifoIn(8*SLOT_WIDTH+SLOT_WIDTH-1 downto 8*SLOT_WIDTH) <= gpsTiming.realTimeCounterLatched(15 downto 0);
						eventFifoWriteRequest <= '1'; -- autoreset
					else
						eventFifoErrorCounter <= eventFifoErrorCounter + 1;
					end if;
					state1 <= nextState;

				when writeWhiteRabbit =>
					newWhiteRabbitEvent <= '0';
					nextState := idle;
					if(unsigned(eventFifoWords) < (eventFifoWordsMax)) then
						eventFifoIn <= (others=>'0');
						eventFifoIn(0*SLOT_WIDTH+SLOT_WIDTH-1 downto 0*SLOT_WIDTH) <= DATATYPE_WHITERABBIT & "00" & x"00";
						eventFifoIn(1*SLOT_WIDTH+SLOT_WIDTH-1 downto 1*SLOT_WIDTH) <= "000000000" & whiteRabbitTiming.irigBinaryYearsLatched;
						eventFifoIn(2*SLOT_WIDTH+SLOT_WIDTH-1 downto 2*SLOT_WIDTH) <= "0000000" & whiteRabbitTiming.irigBinaryDaysLatched;
						eventFifoIn(3*SLOT_WIDTH+SLOT_WIDTH-1 downto 3*SLOT_WIDTH) <= whiteRabbitTiming.irigBinarySecondsLatched;
						eventFifoIn(4*SLOT_WIDTH+SLOT_WIDTH-1 downto 4*SLOT_WIDTH) <= x"dead";
						eventFifoIn(5*SLOT_WIDTH+SLOT_WIDTH-1 downto 5*SLOT_WIDTH) <= whiteRabbitTiming.realTimeCounterLatched(63 downto 48);
						eventFifoIn(6*SLOT_WIDTH+SLOT_WIDTH-1 downto 6*SLOT_WIDTH) <= whiteRabbitTiming.realTimeCounterLatched(47 downto 32);
						eventFifoIn(7*SLOT_WIDTH+SLOT_WIDTH-1 downto 7*SLOT_WIDTH) <= whiteRabbitTiming.realTimeCounterLatched(31 downto 16);
						eventFifoIn(8*SLOT_WIDTH+SLOT_WIDTH-1 downto 8*SLOT_WIDTH) <= whiteRabbitTiming.realTimeCounterLatched(15 downto 0);
						eventFifoWriteRequest <= '1'; -- autoreset
					else
						eventFifoErrorCounter <= eventFifoErrorCounter + 1;
					end if;
					state1 <= nextState;
					
				when waitForRoiData =>
					newTriggerEvent <= '0';
					if(drs4Data.roiBufferReady = '1') then
						state1 <= writeHeader;
					end if;

				when writeHeader =>
					increaseEventCounter <= '1'; -- autoreset
					if(unsigned(eventFifoWords) < (eventFifoWordsMax - eventLength)) then
						eventFifoIn <= (others=>'0');
						--eventFifoIn(0*SLOT_WIDTH+SLOT_WIDTH-1 downto 0*SLOT_WIDTH) <= DATATYPE_HEADER & "00" & x"00";
						eventFifoIn(1*SLOT_WIDTH+SLOT_WIDTH-1 downto 1*SLOT_WIDTH) <= std_logic_vector(eventCount(31 downto 16));
						eventFifoIn(2*SLOT_WIDTH+SLOT_WIDTH-1 downto 2*SLOT_WIDTH) <= std_logic_vector(eventCount(15 downto 0));
						eventFifoIn(3*SLOT_WIDTH+SLOT_WIDTH-1 downto 3*SLOT_WIDTH) <= std_logic_vector(eventLength);
						eventFifoIn(4*SLOT_WIDTH+SLOT_WIDTH-1 downto 4*SLOT_WIDTH) <= drs4Data.realTimeCounter_latched(63 downto 48);
						eventFifoIn(5*SLOT_WIDTH+SLOT_WIDTH-1 downto 5*SLOT_WIDTH) <= drs4Data.realTimeCounter_latched(47 downto 32);
						eventFifoIn(6*SLOT_WIDTH+SLOT_WIDTH-1 downto 6*SLOT_WIDTH) <= drs4Data.realTimeCounter_latched(31 downto 16);
						eventFifoIn(7*SLOT_WIDTH+SLOT_WIDTH-1 downto 7*SLOT_WIDTH) <= drs4Data.realTimeCounter_latched(15 downto 0);
						eventFifoIn(8*SLOT_WIDTH+SLOT_WIDTH-1 downto 8*SLOT_WIDTH) <= "000000" & drs4Data.roiBuffer;
							
						state1 <= writeDebug;
						
						if(testDataEventFifoStatic_bit = '1') then
							eventFifoIn(0*SLOT_WIDTH+SLOT_WIDTH-1 downto 0*SLOT_WIDTH) <= DATATYPE_TESTDATA_STATICEVENTFIFOHEADER & "00" & x"00"; -- ## not implemented...
						elsif(testDataEventFifoCounter_bit = '1') then
							eventFifoIn(0*SLOT_WIDTH+SLOT_WIDTH-1 downto 0*SLOT_WIDTH) <= DATATYPE_TESTDATA_COUNTEREVENTFIFOHEADER & "00" & x"00"; -- ## not implemented...
							state1 <= testData;
							testDataCounter <= (others=>'0');
							testDataWords <= to_unsigned(0,testDataWords'length);
						else
							eventFifoIn(0*SLOT_WIDTH+SLOT_WIDTH-1 downto 0*SLOT_WIDTH) <= DATATYPE_HEADER & "00" & x"00"; -- ## 'unknown' as default would be better						
						end if;
						eventFifoWriteRequest <= '1'; -- autoreset
					-- ## maybe we can save some LEs here if the assignment of eventFifoIn is changed
					else
						state1 <= idle;
						eventFifoErrorCounter <= eventFifoErrorCounter + 1;
					end if;
				
				when writeDebug =>
					nextState := writeTriggerTiming;
					if(writeDebugToFifo_bit = '1') then
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
					end if;
					state1 <= nextState;
					
				when writeTriggerTiming =>
					nextState := writeDrs4Sampling;
					if(writeTriggerTimingToFifo_bit = '1') then
						if(triggerTiming.newData = '1') then
							eventFifoIn <= (others=>'0');
							eventFifoIn(0*SLOT_WIDTH+SLOT_WIDTH-1 downto 0*SLOT_WIDTH) <= DATATYPE_TRIGGERTIMING & "00" & x"00";
							eventFifoIn(1*SLOT_WIDTH+SLOT_WIDTH-1 downto 1*SLOT_WIDTH) <= triggerTiming.channel(0);
							eventFifoIn(2*SLOT_WIDTH+SLOT_WIDTH-1 downto 2*SLOT_WIDTH) <= triggerTiming.channel(1);
							eventFifoIn(3*SLOT_WIDTH+SLOT_WIDTH-1 downto 3*SLOT_WIDTH) <= triggerTiming.channel(2);
							eventFifoIn(4*SLOT_WIDTH+SLOT_WIDTH-1 downto 4*SLOT_WIDTH) <= triggerTiming.channel(3);
							eventFifoIn(5*SLOT_WIDTH+SLOT_WIDTH-1 downto 5*SLOT_WIDTH) <= triggerTiming.channel(4);
							eventFifoIn(6*SLOT_WIDTH+SLOT_WIDTH-1 downto 6*SLOT_WIDTH) <= triggerTiming.channel(5);
							eventFifoIn(7*SLOT_WIDTH+SLOT_WIDTH-1 downto 7*SLOT_WIDTH) <= triggerTiming.channel(6);
							eventFifoIn(8*SLOT_WIDTH+SLOT_WIDTH-1 downto 8*SLOT_WIDTH) <= triggerTiming.channel(7);
							eventFifoWriteRequest <= '1'; -- autoreset
							state1 <= nextState;
						end if;
					else	
						state1 <= nextState;
					end if;
				
				when writeDrs4Sampling =>
					nextState := writeDrs4Baseline;
					if(writeDrs4SamplingToFifo_bit = '1') then
						if(drs4Data.newData = '1') then 
							eventFifoIn <= (others=>'0');
							eventFifoIn(0*SLOT_WIDTH+SLOT_WIDTH-1 downto 0*SLOT_WIDTH) <= DATATYPE_DSR4SAMPLING & std_logic_vector(dataTypeCounter);
							eventFifoIn(1*SLOT_WIDTH+SLOT_WIDTH-1 downto 1*SLOT_WIDTH) <= drs4Data.channel(0);
							eventFifoIn(2*SLOT_WIDTH+SLOT_WIDTH-1 downto 2*SLOT_WIDTH) <= drs4Data.channel(1);
							eventFifoIn(3*SLOT_WIDTH+SLOT_WIDTH-1 downto 3*SLOT_WIDTH) <= drs4Data.channel(2);
							eventFifoIn(4*SLOT_WIDTH+SLOT_WIDTH-1 downto 4*SLOT_WIDTH) <= drs4Data.channel(3);
							eventFifoIn(5*SLOT_WIDTH+SLOT_WIDTH-1 downto 5*SLOT_WIDTH) <= drs4Data.channel(4);
							eventFifoIn(6*SLOT_WIDTH+SLOT_WIDTH-1 downto 6*SLOT_WIDTH) <= drs4Data.channel(5);
							eventFifoIn(7*SLOT_WIDTH+SLOT_WIDTH-1 downto 7*SLOT_WIDTH) <= drs4Data.channel(6);
							eventFifoIn(8*SLOT_WIDTH+SLOT_WIDTH-1 downto 8*SLOT_WIDTH) <= drs4Data.channel(7);
							eventFifoWriteRequest <= '1'; -- autoreset
							dataTypeCounter <= dataTypeCounter + 1;
						end if;

						if(drs4Data.samplingDone = '1') then
							state1 <= nextState;
							dataTypeCounter <= (others=>'0');
						end if;
					else
						state1 <= nextState;
					end if;
					
				when writeDrs4Baseline =>
					nextState := writeDrs4Charge;
					if(writeDrs4BaselineToFifo_bit = '1') then
						if(baselineDone = '1') then
							if(baselinePart = '0') then
								eventFifoIn <= (others=>'0');
								eventFifoIn(0*SLOT_WIDTH+SLOT_WIDTH-1 downto 0*SLOT_WIDTH) <= DATATYPE_DSR4BASELINE & std_logic_vector(dataTypeCounter);
								eventFifoIn(1*SLOT_WIDTH+SLOT_WIDTH-1 downto 1*SLOT_WIDTH) <= x"00" & drs4Data.baseline(0)(23 downto 16);
								eventFifoIn(2*SLOT_WIDTH+SLOT_WIDTH-1 downto 2*SLOT_WIDTH) <= x"00" & drs4Data.baseline(1)(23 downto 16);
								eventFifoIn(3*SLOT_WIDTH+SLOT_WIDTH-1 downto 3*SLOT_WIDTH) <= x"00" & drs4Data.baseline(2)(23 downto 16);
								eventFifoIn(4*SLOT_WIDTH+SLOT_WIDTH-1 downto 4*SLOT_WIDTH) <= x"00" & drs4Data.baseline(3)(23 downto 16);
								eventFifoIn(5*SLOT_WIDTH+SLOT_WIDTH-1 downto 5*SLOT_WIDTH) <= x"00" & drs4Data.baseline(4)(23 downto 16);
								eventFifoIn(6*SLOT_WIDTH+SLOT_WIDTH-1 downto 6*SLOT_WIDTH) <= x"00" & drs4Data.baseline(5)(23 downto 16);
								eventFifoIn(7*SLOT_WIDTH+SLOT_WIDTH-1 downto 7*SLOT_WIDTH) <= x"00" & drs4Data.baseline(6)(23 downto 16);
								eventFifoIn(8*SLOT_WIDTH+SLOT_WIDTH-1 downto 8*SLOT_WIDTH) <= x"00" & drs4Data.baseline(7)(23 downto 16);
								eventFifoWriteRequest <= '1'; -- autoreset
								dataTypeCounter <= dataTypeCounter + 1;
								baselinePart <= '1';
							end if;
							if(baselinePart = '1') then
								eventFifoIn <= (others=>'0');
								eventFifoIn(0*SLOT_WIDTH+SLOT_WIDTH-1 downto 0*SLOT_WIDTH) <= DATATYPE_DSR4BASELINE & std_logic_vector(dataTypeCounter); 
								eventFifoIn(1*SLOT_WIDTH+SLOT_WIDTH-1 downto 1*SLOT_WIDTH) <= drs4Data.baseline(0)(15 downto 0);
								eventFifoIn(2*SLOT_WIDTH+SLOT_WIDTH-1 downto 2*SLOT_WIDTH) <= drs4Data.baseline(1)(15 downto 0);
								eventFifoIn(3*SLOT_WIDTH+SLOT_WIDTH-1 downto 3*SLOT_WIDTH) <= drs4Data.baseline(2)(15 downto 0);
								eventFifoIn(4*SLOT_WIDTH+SLOT_WIDTH-1 downto 4*SLOT_WIDTH) <= drs4Data.baseline(3)(15 downto 0);
								eventFifoIn(5*SLOT_WIDTH+SLOT_WIDTH-1 downto 5*SLOT_WIDTH) <= drs4Data.baseline(4)(15 downto 0);
								eventFifoIn(6*SLOT_WIDTH+SLOT_WIDTH-1 downto 6*SLOT_WIDTH) <= drs4Data.baseline(5)(15 downto 0);
								eventFifoIn(7*SLOT_WIDTH+SLOT_WIDTH-1 downto 7*SLOT_WIDTH) <= drs4Data.baseline(6)(15 downto 0);
								eventFifoIn(8*SLOT_WIDTH+SLOT_WIDTH-1 downto 8*SLOT_WIDTH) <= drs4Data.baseline(7)(15 downto 0);
								eventFifoWriteRequest <= '1'; -- autoreset
								dataTypeCounter <= dataTypeCounter + 1;
								baselinePart <= '0';
								
								state1 <= nextState;
								dataTypeCounter <= (others=>'0');
								baselineDone <= '0';
							end if;
						end if;
					else
						state1 <= nextState;
					end if;

				when writeDrs4Charge =>
					nextState := writeDrs4Timing;
					--nextState := writeDrs4Max;
					if(writeDrs4ChargeToFifo_bit = '1') then
						if(chargeDone = '1') then
							if(chargePart = '0') then
								eventFifoIn <= (others=>'0');
								eventFifoIn(0*SLOT_WIDTH+SLOT_WIDTH-1 downto 0*SLOT_WIDTH) <= DATATYPE_DSR4CHARGE & std_logic_vector(dataTypeCounter);
								eventFifoIn(1*SLOT_WIDTH+SLOT_WIDTH-1 downto 1*SLOT_WIDTH) <= x"00" & drs4Data.charge(0)(23 downto 16);
								eventFifoIn(2*SLOT_WIDTH+SLOT_WIDTH-1 downto 2*SLOT_WIDTH) <= x"00" & drs4Data.charge(1)(23 downto 16);
								eventFifoIn(3*SLOT_WIDTH+SLOT_WIDTH-1 downto 3*SLOT_WIDTH) <= x"00" & drs4Data.charge(2)(23 downto 16);
								eventFifoIn(4*SLOT_WIDTH+SLOT_WIDTH-1 downto 4*SLOT_WIDTH) <= x"00" & drs4Data.charge(3)(23 downto 16);
								eventFifoIn(5*SLOT_WIDTH+SLOT_WIDTH-1 downto 5*SLOT_WIDTH) <= x"00" & drs4Data.charge(4)(23 downto 16);
								eventFifoIn(6*SLOT_WIDTH+SLOT_WIDTH-1 downto 6*SLOT_WIDTH) <= x"00" & drs4Data.charge(5)(23 downto 16);
								eventFifoIn(7*SLOT_WIDTH+SLOT_WIDTH-1 downto 7*SLOT_WIDTH) <= x"00" & drs4Data.charge(6)(23 downto 16);
								eventFifoIn(8*SLOT_WIDTH+SLOT_WIDTH-1 downto 8*SLOT_WIDTH) <= x"00" & drs4Data.charge(7)(23 downto 16);
								eventFifoWriteRequest <= '1'; -- autoreset
								dataTypeCounter <= dataTypeCounter + 1;
								chargePart <= '1';
							end if;
							if(chargePart = '1') then
								eventFifoIn <= (others=>'0');
								eventFifoIn(0*SLOT_WIDTH+SLOT_WIDTH-1 downto 0*SLOT_WIDTH) <= DATATYPE_DSR4CHARGE & std_logic_vector(dataTypeCounter); 
								eventFifoIn(1*SLOT_WIDTH+SLOT_WIDTH-1 downto 1*SLOT_WIDTH) <= drs4Data.charge(0)(15 downto 0);
								eventFifoIn(2*SLOT_WIDTH+SLOT_WIDTH-1 downto 2*SLOT_WIDTH) <= drs4Data.charge(1)(15 downto 0);
								eventFifoIn(3*SLOT_WIDTH+SLOT_WIDTH-1 downto 3*SLOT_WIDTH) <= drs4Data.charge(2)(15 downto 0);
								eventFifoIn(4*SLOT_WIDTH+SLOT_WIDTH-1 downto 4*SLOT_WIDTH) <= drs4Data.charge(3)(15 downto 0);
								eventFifoIn(5*SLOT_WIDTH+SLOT_WIDTH-1 downto 5*SLOT_WIDTH) <= drs4Data.charge(4)(15 downto 0);
								eventFifoIn(6*SLOT_WIDTH+SLOT_WIDTH-1 downto 6*SLOT_WIDTH) <= drs4Data.charge(5)(15 downto 0);
								eventFifoIn(7*SLOT_WIDTH+SLOT_WIDTH-1 downto 7*SLOT_WIDTH) <= drs4Data.charge(6)(15 downto 0);
								eventFifoIn(8*SLOT_WIDTH+SLOT_WIDTH-1 downto 8*SLOT_WIDTH) <= drs4Data.charge(7)(15 downto 0);
								eventFifoWriteRequest <= '1'; -- autoreset
								dataTypeCounter <= dataTypeCounter + 1;
								chargePart <= '0';
								
								state1 <= nextState;
								dataTypeCounter <= (others=>'0');
								chargeDone <= '0';
							end if;
						end if;
					else
						state1 <= nextState;
					end if;

				when writeDrs4Max =>
					nextState := writeDrs4Timing;
					if(writeDrs4MaxValueToFifo_bit = '1') then
						--if(chargeDone = '1') then
							eventFifoIn <= (others=>'0');
							eventFifoIn(0*SLOT_WIDTH+SLOT_WIDTH-1 downto 0*SLOT_WIDTH) <= DATATYPE_DRS4MAX & "00" & x"00";
							eventFifoIn(1*SLOT_WIDTH+SLOT_WIDTH-1 downto 1*SLOT_WIDTH) <= "00" & drs4Data.maxValue(0)(13 downto 0);
							eventFifoIn(2*SLOT_WIDTH+SLOT_WIDTH-1 downto 2*SLOT_WIDTH) <= "00" & drs4Data.maxValue(1)(13 downto 0);
							eventFifoIn(3*SLOT_WIDTH+SLOT_WIDTH-1 downto 3*SLOT_WIDTH) <= "00" & drs4Data.maxValue(2)(13 downto 0);
							eventFifoIn(4*SLOT_WIDTH+SLOT_WIDTH-1 downto 4*SLOT_WIDTH) <= "00" & drs4Data.maxValue(3)(13 downto 0);
							eventFifoIn(5*SLOT_WIDTH+SLOT_WIDTH-1 downto 5*SLOT_WIDTH) <= "00" & drs4Data.maxValue(4)(13 downto 0);
							eventFifoIn(6*SLOT_WIDTH+SLOT_WIDTH-1 downto 6*SLOT_WIDTH) <= "00" & drs4Data.maxValue(5)(13 downto 0);
							eventFifoIn(7*SLOT_WIDTH+SLOT_WIDTH-1 downto 7*SLOT_WIDTH) <= "00" & drs4Data.maxValue(6)(13 downto 0);
							eventFifoIn(8*SLOT_WIDTH+SLOT_WIDTH-1 downto 8*SLOT_WIDTH) <= "00" & drs4Data.maxValue(7)(13 downto 0);
							eventFifoWriteRequest <= '1'; -- autoreset
						
							state1 <= nextState;
						--	chargeDone <= '0';
						--end if;
					else
						state1 <= nextState;
					end if;
					
				when writeDrs4Timing =>
					nextState := idle;
					if(writeDrs4TimingToFifo_bit = '1') then
					--	if(abc.drs4Timing.newData = '1') then
							eventFifoIn <= (others=>'0');
							eventFifoIn(0*SLOT_WIDTH+SLOT_WIDTH-1 downto 0*SLOT_WIDTH) <= DATATYPE_DSR4TIMING & "00" & x"00";
							-- ## not implemented...
							eventFifoIn(1*SLOT_WIDTH+SLOT_WIDTH-1 downto 1*SLOT_WIDTH) <= x"dead";
							eventFifoIn(2*SLOT_WIDTH+SLOT_WIDTH-1 downto 2*SLOT_WIDTH) <= x"dead";
							eventFifoIn(3*SLOT_WIDTH+SLOT_WIDTH-1 downto 3*SLOT_WIDTH) <= x"dead";
							eventFifoIn(4*SLOT_WIDTH+SLOT_WIDTH-1 downto 4*SLOT_WIDTH) <= x"dead";
							eventFifoIn(5*SLOT_WIDTH+SLOT_WIDTH-1 downto 5*SLOT_WIDTH) <= x"dead";
							eventFifoIn(6*SLOT_WIDTH+SLOT_WIDTH-1 downto 6*SLOT_WIDTH) <= x"dead";
							eventFifoIn(7*SLOT_WIDTH+SLOT_WIDTH-1 downto 7*SLOT_WIDTH) <= x"dead";
							eventFifoIn(8*SLOT_WIDTH+SLOT_WIDTH-1 downto 8*SLOT_WIDTH) <= x"dead";
							eventFifoWriteRequest <= '1'; -- autoreset
					--	end if;
					--	
					--	if(abc.drs4Timing.timingDone = '1') then
							state1 <= nextState;
					--	end if;
					else
						state1 <= nextState;
					end if;

				----------------
				when testDataHeader =>
					increaseEventCounter <= '1'; -- autoreset
					if(unsigned(eventFifoWords) < (eventFifoWordsMax - eventLength)) then
						eventFifoIn <= (others=>'0');
						eventFifoIn(0*SLOT_WIDTH+SLOT_WIDTH-1 downto 0*SLOT_WIDTH) <= DATATYPE_TESTDATA_COUNTER & std_logic_vector(testDataWords(9 downto 0));
						eventFifoIn(1*SLOT_WIDTH+SLOT_WIDTH-1 downto 1*SLOT_WIDTH) <= std_logic_vector(eventCount(31 downto 16));
						eventFifoIn(2*SLOT_WIDTH+SLOT_WIDTH-1 downto 2*SLOT_WIDTH) <= std_logic_vector(eventCount(15 downto 0));
						eventFifoIn(3*SLOT_WIDTH+SLOT_WIDTH-1 downto 3*SLOT_WIDTH) <= std_logic_vector(eventLength);
						eventFifoIn(4*SLOT_WIDTH+SLOT_WIDTH-1 downto 4*SLOT_WIDTH) <= std_logic_vector(testDataCounter) & "011";
						eventFifoIn(5*SLOT_WIDTH+SLOT_WIDTH-1 downto 5*SLOT_WIDTH) <= std_logic_vector(testDataCounter) & "100";
						eventFifoIn(6*SLOT_WIDTH+SLOT_WIDTH-1 downto 6*SLOT_WIDTH) <= std_logic_vector(testDataCounter) & "101";
						eventFifoIn(7*SLOT_WIDTH+SLOT_WIDTH-1 downto 7*SLOT_WIDTH) <= std_logic_vector(testDataCounter) & "110";
						eventFifoIn(8*SLOT_WIDTH+SLOT_WIDTH-1 downto 8*SLOT_WIDTH) <= std_logic_vector(testDataCounter) & "111";
						testDataCounter <= testDataCounter + 1;
						testDataWords <= testDataWords + 1;
						eventFifoWriteRequest <= '1'; -- autoreset
						state1 <= testData;
					else
						state1 <= idle;
						eventFifoErrorCounter <= eventFifoErrorCounter + 1;
					end if;

				when testData =>
					if(testDataWords < unsigned(registerSamplesToRead))then
						eventFifoIn <= (others=>'0');
						eventFifoIn(0*SLOT_WIDTH+SLOT_WIDTH-1 downto 0*SLOT_WIDTH) <= DATATYPE_TESTDATA_COUNTER & std_logic_vector(testDataWords(9 downto 0));
						eventFifoIn(1*SLOT_WIDTH+SLOT_WIDTH-1 downto 1*SLOT_WIDTH) <= std_logic_vector(testDataCounter) & "000";
						eventFifoIn(2*SLOT_WIDTH+SLOT_WIDTH-1 downto 2*SLOT_WIDTH) <= std_logic_vector(testDataCounter) & "001";
						eventFifoIn(3*SLOT_WIDTH+SLOT_WIDTH-1 downto 3*SLOT_WIDTH) <= std_logic_vector(testDataCounter) & "010";
						eventFifoIn(4*SLOT_WIDTH+SLOT_WIDTH-1 downto 4*SLOT_WIDTH) <= std_logic_vector(testDataCounter) & "011";
						eventFifoIn(5*SLOT_WIDTH+SLOT_WIDTH-1 downto 5*SLOT_WIDTH) <= std_logic_vector(testDataCounter) & "100";
						eventFifoIn(6*SLOT_WIDTH+SLOT_WIDTH-1 downto 6*SLOT_WIDTH) <= std_logic_vector(testDataCounter) & "101";
						eventFifoIn(7*SLOT_WIDTH+SLOT_WIDTH-1 downto 7*SLOT_WIDTH) <= std_logic_vector(testDataCounter) & "110";
						eventFifoIn(8*SLOT_WIDTH+SLOT_WIDTH-1 downto 8*SLOT_WIDTH) <= std_logic_vector(testDataCounter) & "111";
						testDataCounter <= testDataCounter + 1;
						testDataWords <= testDataWords + 1;
						eventFifoWriteRequest <= '1'; -- autoreset
					else
						state1 <= idle;
					end if;
				
				when others =>
					state1 <= idle;
			end case;	
			
		end if;
	end if;
end process P1;

--WeventFifoWordsDma32 <= (unsigned(eventFifoWordsDma) * 9) + eventFifoWordsDmaSlice;

-- ## todo: implement a 16Bit counting fifoWordCount to look like a real 16Bit per word fifo....
P2:process (registerWrite.clock)
	variable lookAheadWord : std_logic := '0';
	constant eventFifoWordWidth_c : std_logic_vector(3 downto 0) := x"9";
	variable temp : unsigned(31 downto 0);
begin
	if rising_edge(registerWrite.clock) then
		eventFifoReadRequest <= '0'; -- autoreset
		if (registerWrite.reset = '1') then
			state7 <= wait0;
			dmaBuffer <= x"0000";
			lookAheadWord := '0';
			eventFifoWordsDma <= (others=>'0');
			eventFifoWordsDmaAligned <= (others=>'0');
			eventFifoWordsDmaSlice <= (others=>'0');
			eventFifoWordsDma32 <= (others=>'0');
--			dmaLookAheadIsIdle <= '1';
			s <= 0;
		else
			if(registerWrite.eventFifoClear = '1') then
				eventFifoWordsDma <= (others=>'0');
				eventFifoWordsDmaAligned <= (others=>'0');
				eventFifoWordsDmaSlice <= (others=>'0');
				eventFifoWordsDma32 <= (others=>'0');
				state7 <= wait0;
			end if;

			case state7 is
				when wait0 =>
					state7 <= wait1;
					
				when wait1 =>
					state7 <= idle;
					
				when idle =>
					if (eventFifoWords /= x"0000") then
						state7 <= read0;
						eventFifoReadRequest <= '1'; -- autoreset
						eventFifoWordsDmaSlice <= eventFifoWordWidth_c;
					else
						dmaBuffer <= x"0000";
						lookAheadWord := '0'; -- ## ?!?!?!?!?! variable?
						eventFifoWordsDmaSlice <= (others=>'0');
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
						eventFifoWordsDmaSlice <= std_logic_vector(unsigned(eventFifoWordsDmaSlice) - 1);
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
								eventFifoWordsDmaSlice <= eventFifoWordWidth_c;
							else
								state7 <= idle;
								eventFifoWordsDmaSlice <= (others=>'0');
							end if;
						end if;
					end if;
					
				when others => null;
			end case;
			
			if (lookAheadWord = '1') then
				eventFifoWordsDmaAligned <= std_logic_vector(unsigned(eventFifoWords) + 1);
			else
				eventFifoWordsDmaAligned <= eventFifoWords;
			end if;

			eventFifoWordsDma <= eventFifoWords;
			eventFifoWordsDma32 <= std_logic_vector((x"00" & unsigned(eventFifoWords) & x"00") + unsigned(eventFifoWords) +  unsigned(eventFifoWordsDmaSlice));
			
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


-- irq generation
Reset_p:process (registerWrite.clock)
begin
	if rising_edge(registerWrite.clock) then
		irq2arm <= '0'; -- autoreset
		if (registerWrite.reset = '1') then
			eventsPerIRQcounter <= (others=>'0');
			irqCounter <= 0;
			stateIrq <= idle;
			eventCount <= (others=>'0');
			irqTimeoutCounter <= 1000; -- register?!
			irqRequest <= '0';
			irqRequest_eventsPerCount <= '0';
			irqRequest_eventFifoWords <= '0';
			irqRequest_timeout <= '0';
			irqRequest_eventsPerCount_old <= '0';
			irqRequest_eventFifoWords_old <= '0';
			irqRequest_timeout_old <= '0'; 
		else
			case stateIrq is -- max irq rate is 2kHz now (500us dead time after irq)
				when idle =>
					if((irqRequest = '1') and (registerWrite.irqStall = '0')) then -- irqStall can be used to reduce the irq rate during unfinished dma transfers
						irqRequest <= '0';
						irq2arm <= '1'; -- autoreset
						stateIrq <= irqBlock;
						irqCounter <= 0;
					end if;
				
				when irqBlock =>
					irqCounter <= irqCounter + 1;
					if (irqCounter >= 62500) then
						stateIrq <= idle;
					end if;
			end case;
							
			if (increaseEventCounter = '1') then 
				eventCount <= eventCount + 1;
				if (unsigned(registerWrite.eventsPerIrq) /= to_unsigned(0,registerWrite.eventsPerIrq'length)) then
					eventsPerIRQcounter <= eventsPerIRQcounter + 1;
				end if;
			end if;
			
			irqRequest_eventsPerCount_old <= irqRequest_eventsPerCount;
			irqRequest_eventFifoWords_old <= irqRequest_eventFifoWords;
			irqRequest_timeout_old <= irqRequest_timeout;

			if(registerWrite.forceIrq = '1') then
				irqRequest <= '1';
			end if;
			if((irqRequest_eventsPerCount = '1') and (irqRequest_eventsPerCount_old = '0')) then
				irqRequest <= '1';
			end if;
			if((irqRequest_eventFifoWords = '1') and (irqRequest_eventFifoWords_old = '0')) then
				irqRequest <= '1';
			end if;
			if((irqRequest_timeout = '1') and (irqRequest_timeout_old = '0')) then
				irqRequest <= '1';
			end if;

			if(registerWrite.enableIrq = '1') then
				if (registerWrite.eventsPerIrq /= (registerWrite.eventsPerIrq'range=>'0')) then
					if (eventsPerIRQcounter >= unsigned(registerWrite.eventsPerIrq)) then
						irqRequest_eventsPerCount <= '1';
						eventsPerIRQcounter <= (others=>'0');
					else
						irqRequest_eventsPerCount <= '0';
					end if;
				end if;		
				
				if (registerWrite.irqAtEventFifoWords /= (registerWrite.irqAtEventFifoWords'range=>'0')) then
					if (unsigned(eventFifoWords) >= unsigned(registerWrite.irqAtEventFifoWords)) then
						irqRequest_eventFifoWords <= '1';
					else
						irqRequest_eventFifoWords <= '0';
					end if;
				end if;
				
				if (eventFifoWords /= (eventFifoWords'range=>'0')) then
					if ((irqTimeoutCounter /= 0) and (internalTiming.tick_ms = '1')) then
						irqTimeoutCounter <= irqTimeoutCounter - 1;
					end if;
					if (irqTimeoutCounter = 1) then
						irqTimeoutCounter <= 0;
						irqRequest_timeout <= '1';
					else
						irqRequest_timeout <= '0';
					end if;
				else
					irqTimeoutCounter <= 1000; -- 1000 = 1sec timeout
				end if;
			end if;
			
			--if ((clearEventCounter = '1') or (resetEventCount_bit = '1')) then
			if (registerWrite.clearEventCounter = '1') then
				eventCount <= (others=>'0');
			end if;
		end if;
	end if;
end process Reset_p;

end behavioral;
