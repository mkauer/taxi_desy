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

entity eventFifoSystem_polarstern is
	port(
		newEvent : in std_logic;
		irq2arm : out std_logic;
		triggerTiming : in triggerTimeToEdge_t;
		pixelRateCounter : in pixelRateCounter_polarstern_t;
		triggerRateCounter : in p_triggerRateCounter_t;
		internalTiming : in internalTiming_t;
		gpsTiming : in gpsTiming_t;
		registerRead : out eventFifoSystem_registerRead_t;
		registerWrite : in eventFifoSystem_registerWrite_t	
		);
end eventFifoSystem_polarstern;

architecture behavioral of eventFifoSystem_polarstern is

	constant SLOTS : integer := 23;
	constant SLOT_WIDTH : integer := 16;

	signal eventFifoWriteRequest : std_logic := '0';
	signal eventFifoReadRequest : std_logic := '0';
	signal eventFifoFull : std_logic := '0';
	signal eventFifoEmpty : std_logic := '0';
	signal eventFifoClear : std_logic := '0';
	signal eventFifoOverflow : std_logic := '0';
	signal eventFifoUnderflow : std_logic := '0';
	signal eventFifoWords : std_logic_vector(15 downto 0) := (others=>'0');
	signal eventFifoIn : std_logic_vector(SLOTS*SLOT_WIDTH-1 downto 0) := (others=>'0');
	signal eventFifoOut : std_logic_vector(SLOTS*SLOT_WIDTH-1 downto 0) := (others=>'0');
	
--	signal eventFifoClearBuffer : std_logic := '0';
--	signal eventFifoClearBuffer_old : std_logic := '0';
	signal eventFifoClearCounter : integer range 0 to 7 := 0;
	
	signal dmaBuffer : std_logic_vector(15 downto 0) := (others=>'0');
	signal eventFifoWordsDma : std_logic_vector(15 downto 0) := (others=>'0');
	signal eventFifoWordsDmaAligned : std_logic_vector(15 downto 0) := (others=>'0');
	signal eventFifoWordsDmaSlice : std_logic_vector(3 downto 0) := (others=>'0');
	signal eventFifoWordsDma32 : std_logic_vector(31 downto 0) := (others=>'0');
	signal s : integer range 0 to 63 := 0;
	
	type state1_t is (wait0, idle, writePPSInfo, writeTiming, writeSlowControlConfig, writeTriggerRates, writeTriggerRatesSector, writeError);
	signal state1 : state1_t := idle;
	
	type state7_t is (wait0, wait1, idle, read0, read1, read2, read3);
	signal state7 : state7_t := wait0;
	
	signal eventFifoErrorCounter : unsigned(15 downto 0) := (others=>'0');
	--constant eventFifoWordsMax : unsigned(15 downto 0) := to_unsigned(1024,16);
	constant eventFifoWordsMax : unsigned(15 downto 0) := to_unsigned(4096,16);
	
	signal eventCount : unsigned(32 downto 0) := (others=>'0');

	--constant eventLength : unsigned(15 downto 0) := x"0001";
	signal eventFifoFull_old : std_logic := '0';
	signal eventFifoOverflow_old : std_logic := '0';
	signal eventFifoUnderflow_old : std_logic := '0';
	signal eventFifoOverflowCounter : unsigned(15 downto 0) := (others=>'0');
	signal eventFifoUnderflowCounter : unsigned(15 downto 0) := (others=>'0');
	signal eventFifoFullCounter : unsigned(15 downto 0) := (others=>'0');
	
	constant DATATYPE_TIMING : std_logic_vector(5 downto 0) := x"1" & "00";
	constant DATATYPE_GPS : std_logic_vector(5 downto 0) := x"2" & "00";
	constant DATATYPE_DEBUG : std_logic_vector(5 downto 0) := x"3" & "00";
	constant DATATYPE_SLOWCONTROLCONFIG : std_logic_vector(5 downto 0) := x"4" & "00";
	constant DATATYPE_TRIGGERRATES : std_logic_vector(5 downto 0) := x"5" & "00";
	constant DATATYPE_TRIGGERRATESSECTOR : std_logic_vector(5 downto 0) := x"6" & "00";
	constant DATATYPE_ERROR : std_logic_vector(5 downto 0) := x"7" & "00";

	constant DATATYPE_TESTDATA_STATICEVENTFIFOHEADER : std_logic_vector(5 downto 0) := x"a" & "00";
	constant DATATYPE_TESTDATA_COUNTEREVENTFIFOHEADER : std_logic_vector(5 downto 0) := x"b" & "00";
	constant DATATYPE_TESTDATA_COUNTER : std_logic_vector(5 downto 0) := x"c" & "00";
	
	signal nextWord : std_logic := '0';
	signal packetConfig : std_logic_vector(15 downto 0);
--	alias writeDsr4TimingToFifo_bit : std_logic is packetConfig(0);
--	alias writeDsr4TimingToFifo_bit_v : std_logic_vector(0 downto 0) is packetConfig(0 downto 0);
--	alias writeDsr4ChargeToFifo_bit : std_logic is packetConfig(1);
--	alias writeDsr4ChargeToFifo_bit_v : std_logic_vector(0 downto 0) is packetConfig(1 downto 1);
--	alias writeDsr4SamplingToFifo_bit : std_logic is packetConfig(2);
--	alias writeDsr4SamplingToFifo_bit_v : std_logic_vector(0 downto 0) is packetConfig(2 downto 2);
--	alias writeDebugToFifo_bit : std_logic is packetConfig(3);
--	alias writeDebugToFifo_bit_v : std_logic_vector(0 downto 0) is packetConfig(3 downto 3);

--	alias testDataEventFifoStatic_bit : std_logic is packetConfig(8);
--	alias testDataEventFifoCounter_bit : std_logic is packetConfig(9);
--	alias testDataFrondEndFifo_bit : std_logic is packetConfig(10);
	alias gpsData_bit : std_logic is packetConfig(12);
	alias ratesData_bit : std_logic is packetConfig(13);
	alias ratesSectorData_bit : std_logic is packetConfig(14);
	alias eventData_bit : std_logic is packetConfig(15);
	
--	signal numberOfSamplesToRead : std_logic_vector(15 downto 0) := x"0000";
	signal registerDeviceId : std_logic_vector(15 downto 0) := x"a5a5"; -- ## dummy
--	signal packetConfig : std_logic_vector(15 downto 0) := x"0000";
	
	signal testDataWords : unsigned(15 downto 0) := x"0000";
	signal testDataCounter : unsigned(12 downto 0) := (others=>'0'); --  range 0 to 2**16-1 := 0;
	signal fifoTestDataEnabled : std_logic := '0';
	signal newEvent_old : std_logic := '0';

	signal softPps : std_logic := '0'; 
	signal pixelRateNewData : std_logic := '0';
	signal pixelRateSectorNewData : std_logic := '0';

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
	
begin

	-- fifo: 368x4096
	l0: entity work.eventFifoPolarstern
	port map (
		clk => registerWrite.clock,
		srst => eventFifoClear,
		din => eventFifoIn,
		wr_en => eventFifoWriteRequest,
		rd_en => eventFifoReadRequest,
		dout => eventFifoOut,
		full => eventFifoFull,
		overflow => eventFifoOverflow,
		empty => eventFifoEmpty,
		underflow => eventFifoUnderflow,
		data_count => eventFifoWords(11 downto 0)
	);
	
	eventFifoWords(12) <= eventFifoFull;
	eventFifoWords(15 downto 13) <= "000";
	
	registerRead.dmaBuffer <= dmaBuffer;
	registerRead.eventFifoWordsDma <= eventFifoWordsDma;
	registerRead.eventFifoWordsDmaAligned <= eventFifoWordsDmaAligned;
	registerRead.eventFifoWordsDmaSlice <= eventFifoWordsDmaSlice;
	registerRead.eventFifoWordsDma32 <= eventFifoWordsDma32;
	registerRead.eventFifoWordsPerSlice <= std_logic_vector(to_unsigned(SLOTS,16));
	nextWord <= registerWrite.nextWord;

	packetConfig <= registerWrite.packetConfig;
	registerRead.packetConfig <= registerWrite.packetConfig;
	registerRead.eventsPerIrq <= registerWrite.eventsPerIrq;
	registerRead.irqAtEventFifoWords <= registerWrite.irqAtEventFifoWords;
	registerRead.enableIrq <= registerWrite.enableIrq;
	registerRead.irqStall <= registerWrite.irqStall;
	registerRead.eventFifoErrorCounter <= std_logic_vector(eventFifoErrorCounter);
	
--	numberOfSamplesToRead <= registerWrite.numberOfSamplesToRead;
--	registerRead.numberOfSamplesToRead <= registerWrite.numberOfSamplesToRead;
	
P1:process (registerWrite.clock)
begin
	if rising_edge(registerWrite.clock) then
		eventFifoWriteRequest <= '0'; -- autoreset
		increaseEventCounter <= '0'; -- autoreset
	
		if (registerWrite.reset = '1') then
			eventFifoClear <= '1';
			state1 <= idle;
		--	eventLength <= to_unsigned(0,eventLength'length);
			eventFifoErrorCounter <= to_unsigned(0,eventFifoErrorCounter'length);
			softPps <= '0';
			pixelRateNewData <= '0';
			pixelRateSectorNewData <= '0';
		else
			newEvent_old <= newEvent;
			eventFifoClear <= registerWrite.eventFifoClear;
			--eventFifoClearBuffer <= registerWrite.eventFifoClear;
			
			if(gpsTiming.newData = '1') then
				softPps <= '1';
			end if;
			if(pixelRateCounter.newData = '1') then
				pixelRateNewData <= '1';
			end if;
			if(pixelRateCounter.newData = '1') then
				pixelRateSectorNewData <= '1';
			end if;
						
			l0: for i in 0 to SLOTS-1 loop
				eventFifoIn(i*SLOT_WIDTH+SLOT_WIDTH-1 downto i*SLOT_WIDTH) <= x"dead";
			end loop;
			
			case state1 is
				when wait0 =>
					if(newEvent = '0') then
						state1 <= idle;
					end if;
					
				when idle =>
					if((newEvent = '1') and (newEvent_old = '0') and (eventData_bit = '1')) then
						state1 <= writeTiming;
					elsif((softPps = '1') and (gpsData_bit = '1')) then
						softPps <= '0';
						state1 <= writePPSInfo;
					elsif((pixelRateNewData = '1') and (ratesData_bit = '1')) then
						pixelRateNewData <= '0';
						state1 <= writeTriggerRates;
					elsif((pixelRateSectorNewData = '1') and (ratesSectorData_bit = '1')) then
						pixelRateSectorNewData <= '0';
						state1 <= writeTriggerRatesSector;
					end if;
				
	--			when testDataHeader =>
	--				eventFifoIn <= (others=>'0');
	--				eventFifoIn(0*SLOT_WIDTH+SLOT_WIDTH-1 downto 0*SLOT_WIDTH) <= DATATYPE_TESTDATA_COUNTER & std_logic_vector(testDataWords(9 downto 0));
	--				eventFifoIn(1*SLOT_WIDTH+SLOT_WIDTH-1 downto 1*SLOT_WIDTH) <= std_logic_vector(eventCount(31 downto 16));
	--				eventFifoIn(2*SLOT_WIDTH+SLOT_WIDTH-1 downto 2*SLOT_WIDTH) <= std_logic_vector(eventCount(15 downto 0));
	--				eventFifoIn(3*SLOT_WIDTH+SLOT_WIDTH-1 downto 3*SLOT_WIDTH) <= std_logic_vector(testDataCounter) & "010";
	--				eventFifoIn(4*SLOT_WIDTH+SLOT_WIDTH-1 downto 4*SLOT_WIDTH) <= std_logic_vector(testDataCounter) & "011";
	--				eventFifoIn(5*SLOT_WIDTH+SLOT_WIDTH-1 downto 5*SLOT_WIDTH) <= std_logic_vector(testDataCounter) & "100";
	--				eventFifoIn(6*SLOT_WIDTH+SLOT_WIDTH-1 downto 6*SLOT_WIDTH) <= std_logic_vector(testDataCounter) & "101";
	--				eventFifoIn(7*SLOT_WIDTH+SLOT_WIDTH-1 downto 7*SLOT_WIDTH) <= std_logic_vector(testDataCounter) & "110";
	--				eventFifoIn(8*SLOT_WIDTH+SLOT_WIDTH-1 downto 8*SLOT_WIDTH) <= std_logic_vector(testDataCounter) & "111";
	--				testDataCounter <= testDataCounter + 1;
	--				testDataWords <= testDataWords + 1;
	--				eventFifoWriteRequest <= '1'; -- autoreset
	--				eventCount <= eventCount + 1;
	--				state1 <= testData;

	--			when testData =>
	--				if(testDataWords < unsigned(numberOfSamplesToRead))then
	--					eventFifoIn <= (others=>'0');
	--					eventFifoIn(0*SLOT_WIDTH+SLOT_WIDTH-1 downto 0*SLOT_WIDTH) <= DATATYPE_TESTDATA_COUNTER & std_logic_vector(testDataWords(9 downto 0));
	--					eventFifoIn(1*SLOT_WIDTH+SLOT_WIDTH-1 downto 1*SLOT_WIDTH) <= std_logic_vector(testDataCounter) & "000";
	--					eventFifoIn(2*SLOT_WIDTH+SLOT_WIDTH-1 downto 2*SLOT_WIDTH) <= std_logic_vector(testDataCounter) & "001";
	--					eventFifoIn(3*SLOT_WIDTH+SLOT_WIDTH-1 downto 3*SLOT_WIDTH) <= std_logic_vector(testDataCounter) & "010";
	--					eventFifoIn(4*SLOT_WIDTH+SLOT_WIDTH-1 downto 4*SLOT_WIDTH) <= std_logic_vector(testDataCounter) & "011";
	--					eventFifoIn(5*SLOT_WIDTH+SLOT_WIDTH-1 downto 5*SLOT_WIDTH) <= std_logic_vector(testDataCounter) & "100";
	--					eventFifoIn(6*SLOT_WIDTH+SLOT_WIDTH-1 downto 6*SLOT_WIDTH) <= std_logic_vector(testDataCounter) & "101";
	--					eventFifoIn(7*SLOT_WIDTH+SLOT_WIDTH-1 downto 7*SLOT_WIDTH) <= std_logic_vector(testDataCounter) & "110";
	--					eventFifoIn(8*SLOT_WIDTH+SLOT_WIDTH-1 downto 8*SLOT_WIDTH) <= std_logic_vector(testDataCounter) & "111";
	--					testDataCounter <= testDataCounter + 1;
	--					testDataWords <= testDataWords + 1;
	--					eventFifoWriteRequest <= '1'; -- autoreset
	--				else
	--					state1 <= idle;
	--				end if;

				when writeError => -- will be send if fifo is full the first time, but could be send as soon as the fifo is not full again... in this case there is a lot more usefull debuginfo avaiable
					state1 <= idle;
					if(unsigned(eventFifoWords) < (eventFifoWordsMax)) then
						eventFifoIn(0*SLOT_WIDTH+SLOT_WIDTH-1 downto 0*SLOT_WIDTH) <= DATATYPE_ERROR & "00" & x"00";
						--eventFifoIn(1*SLOT_WIDTH+SLOT_WIDTH-1 downto 1*SLOT_WIDTH) <= error.counterXYZ();
						eventFifoWriteRequest <= '1'; -- autoreset
					end if;

				when writePPSInfo =>
					state1 <= idle;
					if(unsigned(eventFifoWords) < (eventFifoWordsMax - 1)) then
						eventFifoIn <= (others=>'0');
						eventFifoIn(0*SLOT_WIDTH+SLOT_WIDTH-1 downto 0*SLOT_WIDTH) <= DATATYPE_GPS & "00" & x"00";
						eventFifoIn(1*SLOT_WIDTH+SLOT_WIDTH-1 downto 1*SLOT_WIDTH) <= gpsTiming.week;
						eventFifoIn(2*SLOT_WIDTH+SLOT_WIDTH-1 downto 2*SLOT_WIDTH) <= gpsTiming.timeOfWeekMilliSecond(31 downto 16);
						eventFifoIn(3*SLOT_WIDTH+SLOT_WIDTH-1 downto 3*SLOT_WIDTH) <= gpsTiming.timeOfWeekMilliSecond(15 downto 0);
						eventFifoIn(4*SLOT_WIDTH+SLOT_WIDTH-1 downto 4*SLOT_WIDTH) <= gpsTiming.quantizationError(31 downto 16);
						eventFifoIn(5*SLOT_WIDTH+SLOT_WIDTH-1 downto 5*SLOT_WIDTH) <= gpsTiming.quantizationError(15 downto 0);
						eventFifoIn(6*SLOT_WIDTH+SLOT_WIDTH-1 downto 6*SLOT_WIDTH) <= gpsTiming.differenceGpsToLocalClock;
						eventFifoIn(7*SLOT_WIDTH+SLOT_WIDTH-1 downto 7*SLOT_WIDTH) <= gpsTiming.realTimeCounterLatched(63 downto 48);
						eventFifoIn(8*SLOT_WIDTH+SLOT_WIDTH-1 downto 8*SLOT_WIDTH) <= gpsTiming.realTimeCounterLatched(47 downto 32);
						eventFifoIn(9*SLOT_WIDTH+SLOT_WIDTH-1 downto 9*SLOT_WIDTH) <= gpsTiming.realTimeCounterLatched(31 downto 16);
						eventFifoIn(10*SLOT_WIDTH+SLOT_WIDTH-1 downto 10*SLOT_WIDTH) <= gpsTiming.realTimeCounterLatched(15 downto 0);
						--eventFifoIn(7*SLOT_WIDTH+SLOT_WIDTH-1 downto 7*SLOT_WIDTH) <= gpsTiming.
						--eventFifoIn(8*SLOT_WIDTH+SLOT_WIDTH-1 downto 8*SLOT_WIDTH) <= registerDeviceId;
						eventFifoWriteRequest <= '1'; -- autoreset
					else
						eventFifoErrorCounter <= eventFifoErrorCounter + 1;
						state1 <= writeError;
					end if;
					
				when writeTiming =>
					state1 <= idle;
					increaseEventCounter <= '1'; -- autoreset
					if(unsigned(eventFifoWords) < (eventFifoWordsMax - 1)) then
						eventFifoIn <= (others=>'0');
						eventFifoIn(0*SLOT_WIDTH+SLOT_WIDTH-1 downto 0*SLOT_WIDTH) <= DATATYPE_TIMING & "00" & x"00";
						eventFifoIn(1*SLOT_WIDTH+SLOT_WIDTH-1 downto 1*SLOT_WIDTH) <= std_logic_vector(eventCount(31 downto 16));
						eventFifoIn(2*SLOT_WIDTH+SLOT_WIDTH-1 downto 2*SLOT_WIDTH) <= std_logic_vector(eventCount(15 downto 0));
						eventFifoIn(3*SLOT_WIDTH+SLOT_WIDTH-1 downto 3*SLOT_WIDTH) <= triggerTiming.realTimeCounterLatched(63 downto 48);
						eventFifoIn(4*SLOT_WIDTH+SLOT_WIDTH-1 downto 4*SLOT_WIDTH) <= triggerTiming.realTimeCounterLatched(47 downto 32);
						eventFifoIn(5*SLOT_WIDTH+SLOT_WIDTH-1 downto 5*SLOT_WIDTH) <= triggerTiming.realTimeCounterLatched(31 downto 16);
						eventFifoIn(6*SLOT_WIDTH+SLOT_WIDTH-1 downto 6*SLOT_WIDTH) <= triggerTiming.realTimeCounterLatched(15 downto 0);
						
						for i in 0 to numberOfChannels-1 loop
							eventFifoIn((7+i)*SLOT_WIDTH+SLOT_WIDTH-1 downto (7+i)*SLOT_WIDTH) <= capValue(triggerTiming.timeToRisingEdge(i),8) & capValue(triggerTiming.timeToFallingEdge(i),8);
						end loop;
						
						eventFifoWriteRequest <= '1'; -- autoreset
					else
						eventFifoErrorCounter <= eventFifoErrorCounter + 1;
						state1 <= writeError;
					end if;
				
	--			when writeDebug =>
	--				eventFifoIn <= (others=>'0');
	--				eventFifoIn(0*SLOT_WIDTH+SLOT_WIDTH-1 downto 0*SLOT_WIDTH) <= DATATYPE_DEBUG & "00" & x"00";
	--				eventFifoIn(1*SLOT_WIDTH+SLOT_WIDTH-1 downto 1*SLOT_WIDTH) <= std_logic_vector(eventFifoFullCounter);
	--				eventFifoIn(2*SLOT_WIDTH+SLOT_WIDTH-1 downto 2*SLOT_WIDTH) <= std_logic_vector(eventFifoOverflowCounter);
	--				eventFifoIn(3*SLOT_WIDTH+SLOT_WIDTH-1 downto 3*SLOT_WIDTH) <= std_logic_vector(eventFifoUnderflowCounter);
	--				eventFifoIn(4*SLOT_WIDTH+SLOT_WIDTH-1 downto 4*SLOT_WIDTH) <= std_logic_vector(eventFifoErrorCounter); 
	--				--eventFifoIn(5*SLOT_WIDTH+SLOT_WIDTH-1 downto 5*SLOT_WIDTH) <= x"0000"; -- 
	--				--eventFifoIn(6*SLOT_WIDTH+SLOT_WIDTH-1 downto 6*SLOT_WIDTH) <= x"0000"; -- 
	--				--eventFifoIn(7*SLOT_WIDTH+SLOT_WIDTH-1 downto 7*SLOT_WIDTH) <= x"0000"; -- 
	--				--eventFifoIn(8*SLOT_WIDTH+SLOT_WIDTH-1 downto 8*SLOT_WIDTH) <= x"0000"; -- some masks...
	--				eventFifoWriteRequest <= '1'; -- autoreset
	--				state1 <= writeTriggerTiming;
	
				when writeSlowControlConfig =>
					state1 <= idle;
					if(unsigned(eventFifoWords) < (eventFifoWordsMax - 1)) then
	--					eventFifoIn(0*SLOT_WIDTH+SLOT_WIDTH-1 downto 0*SLOT_WIDTH) <= DATATYPE_SLOWCONTROLCONFIG & "00" & x"00";
	--					eventFifoIn(1*SLOT_WIDTH+SLOT_WIDTH-1 downto 1*SLOT_WIDTH) <= hvDacValues(0-1);
	--					eventFifoIn(2*SLOT_WIDTH+SLOT_WIDTH-1 downto 2*SLOT_WIDTH) <= thresholdDacValues(0-15);
	--					eventFifoIn(10*SLOT_WIDTH+SLOT_WIDTH-1 downto 10*SLOT_WIDTH) <= triggerMode;
	--					eventFifoIn(11*SLOT_WIDTH+SLOT_WIDTH-1 downto 11*SLOT_WIDTH) <= ???;
	--					eventFifoWriteRequest <= '1'; -- autoreset
					else
						eventFifoErrorCounter <= eventFifoErrorCounter + 1;
						state1 <= writeError;
					end if;
	
				when writeTriggerRates =>
					state1 <= idle;
					--state1 <= writeTriggerRatesSector;
					if(unsigned(eventFifoWords) < (eventFifoWordsMax - 1)) then
						eventFifoIn(0*SLOT_WIDTH+SLOT_WIDTH-1 downto 0*SLOT_WIDTH) <= DATATYPE_TRIGGERRATES & "00" & x"00";
						eventFifoIn(1*SLOT_WIDTH+SLOT_WIDTH-1 downto 1*SLOT_WIDTH) <= pixelRateCounter.counterPeriod;
						eventFifoIn(2*SLOT_WIDTH+SLOT_WIDTH-1 downto 2*SLOT_WIDTH) <= triggerRateCounter.rateCounterLatched(0);
						eventFifoIn(3*SLOT_WIDTH+SLOT_WIDTH-1 downto 3*SLOT_WIDTH) <= triggerRateCounter.rateCounterLatched(1);
						eventFifoIn(4*SLOT_WIDTH+SLOT_WIDTH-1 downto 4*SLOT_WIDTH) <= triggerRateCounter.rateCounterLatched(2);
						for i in 0 to numberOfChannels-1 loop
							eventFifoIn((7+i)*SLOT_WIDTH+SLOT_WIDTH-1 downto (7+i)*SLOT_WIDTH) <= pixelRateCounter.channelLatched(i);
						end loop;
						eventFifoWriteRequest <= '1'; -- autoreset
					else
						eventFifoErrorCounter <= eventFifoErrorCounter + 1;
						state1 <= writeError;
					end if;

				when writeTriggerRatesSector =>
					state1 <= idle;
					if(unsigned(eventFifoWords) < (eventFifoWordsMax - 1)) then
						eventFifoIn(0*SLOT_WIDTH+SLOT_WIDTH-1 downto 0*SLOT_WIDTH) <= DATATYPE_TRIGGERRATESSECTOR & "00" & x"00";
						for i in 0 to numberOfChannels-1 loop
							eventFifoIn((7+i)*SLOT_WIDTH+SLOT_WIDTH-1 downto (7+i)*SLOT_WIDTH) <= triggerRateCounter.rateCounterSectorLatched(i/2);
						end loop;
						eventFifoWriteRequest <= '1'; -- autoreset
					else
						eventFifoErrorCounter <= eventFifoErrorCounter + 1;
						state1 <= writeError;
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
			eventFifoWordsDma <= (others=>'0');
			eventFifoWordsDmaAligned <= (others=>'0');
			eventFifoWordsDmaSlice <= (others=>'0');
			eventFifoWordsDma32 <= (others=>'0');
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
						eventFifoWordsDmaSlice <= std_logic_vector(to_unsigned(SLOTS,eventFifoWordsDmaSlice'length));
					else
						dmaBuffer <= x"0000";
						lookAheadWord := '0'; -- ## ?!?!?!?!?! variable?
						eventFifoWordsDmaSlice <= (others=>'0');
					end if;
					
				when read0 =>
					state7 <= read1;
					
				when read1 =>
					--dmaBuffer <= eventFifoOut(eventFifoOut'length-1 downto eventFifoOut'length-16);
					dmaBuffer <= eventFifoOut(0*SLOT_WIDTH+SLOT_WIDTH-1 downto 0*SLOT_WIDTH);
					s <= 1;
					lookAheadWord := '1';
					state7 <= read2;
					
				when read2 =>
					if (nextWord = '1') then
						eventFifoWordsDmaSlice <= std_logic_vector(unsigned(eventFifoWordsDmaSlice) - 1);
						dmaBuffer <= eventFifoOut(s*SLOT_WIDTH+SLOT_WIDTH-1 downto s*SLOT_WIDTH);
						s <= s + 1;
						state7 <= read3;
					end if;
					
				when read3 =>
					if (nextWord = '0') then
						state7 <= read2;
						if (s > SLOTS) then
							if (eventFifoWords /= x"0000") then
								state7 <= read0;
								eventFifoReadRequest <= '1'; -- autoreset
								eventFifoWordsDmaSlice <= std_logic_vector(to_unsigned(SLOTS,eventFifoWordsDmaSlice'length));
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
			eventFifoWordsDma32 <= std_logic_vector((x"00" & unsigned(eventFifoWords) & x"00") + unsigned(eventFifoWords) +  unsigned(eventFifoWordsDmaSlice)); -- ## hack, to avoid multiplication ?!?
			
--			if(registerResetFifos(1) = '1') then
--				s <= 0;
--				state7 <= wait0;
--				--fifoWasEmpty <= '1';
--			end if;
			
		end if;
	end if;
end process P2;

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
P5:process (registerWrite.clock)
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
end process P5;

end behavioral;
