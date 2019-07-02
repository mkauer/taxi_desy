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
		rateCounterTimeOut : in std_logic;
		irq2arm : out std_logic;
		triggerTiming : in triggerTiming_t;
		drs4AndAdcData : in drs4AndAdcData_t;
		--drs4Data : in ltm9007_14_to_eventFifoSystem_t;
		internalTiming : in internalTiming_t;
		--gpsTiming : in gpsTiming_t;
		--whiteRabbitTiming : in whiteRabbitTiming_t;
		pixelRateCounter : in pixelRateCounter_v2_t;
		dac1_stats : in dac1_uvLogger_stats_t;
		registerRead : out eventFifoSystem_registerRead_t;
		registerWrite : in eventFifoSystem_registerWrite_t	
		);
end eventFifoSystem;

architecture behavioral of eventFifoSystem is

	constant SLOTS : integer := 9;
	constant SLOT_WIDTH : integer := 16;
	constant FIRMWAREVERSION : std_logic_vector(15 downto 0) := x"0001";
	constant PROTOCOLVERSION : std_logic_vector(15 downto 0) := x"0002";

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
	type eventFifo_t is array (0 to SLOTS-1) of std_logic_vector(SLOT_WIDTH-1 downto 0);
	signal eventFifoInSlots : eventFifo_t := (others=>(others=>'0'));
	
--	signal eventFifoClearBuffer : std_logic := '0';
--	signal eventFifoClearBuffer_old : std_logic := '0';
	signal eventFifoClearCounter : integer range 0 to 7 := 0;
	
	signal dmaBuffer : std_logic_vector(15 downto 0) := (others=>'0');
	signal eventFifoWordsDma : std_logic_vector(15 downto 0) := (others=>'0');
	signal eventFifoWordsDmaAligned : std_logic_vector(15 downto 0) := (others=>'0');
	signal eventFifoWordsDmaSlice : std_logic_vector(3 downto 0) := (others=>'0');
	signal eventFifoWordsDma32 : std_logic_vector(31 downto 0) := (others=>'0');
	signal s : integer range 0 to 63 := 0;
	
	type state1_t is (wait0, idle, writeMisc1, writeMisc2, writeMisc3, writeMisc4, writeGps, writeWhiteRabbit, writePixelRateCounter0, writePixelRateCounter1, writePixelRateCounter2, writePixelRateCounter3, writeHeader, writeDebug, writeTriggerTiming, writeDrs4Sampling, writeDrs4Charge, writeDrs4Max, writeDrs4Baseline, writeDrs4Timing, testDataHeader, testData, waitForRoiData);
	signal state1 : state1_t := idle;
	
	type state7_t is (wait0, wait1, idle, read0, read1, read2, read3);
	signal state7 : state7_t := wait0;
	
	signal eventFifoErrorCounter : unsigned(15 downto 0) := (others=>'0');
	--constant eventFifoWordsMax : unsigned(15 downto 0) := to_unsigned(1024,16);
	--constant eventFifoWordsMax : unsigned(15 downto 0) := to_unsigned(4096,16);
	constant eventFifoWordsMax : unsigned(15 downto 0) := to_unsigned(8192,16);
	
	signal eventCount : unsigned(32 downto 0) := (others=>'0');
--	signal counterSecounds : unsigned(32 downto 0) := (others=>'0'); -- move
--	signal realTimeCounterSecounds : unsigned(32 downto 0) := (others=>'0'); -- move
--	signal realTimeCounterSubSecounds : unsigned(32 downto 0) := (others=>'0'); -- move

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
	constant DATATYPE_UVLOGGER_TRIGGERTIMING : std_logic_vector(5 downto 0) := x"a" & "00";
	constant DATATYPE_TESTDATA_STATICEVENTFIFOHEADER : std_logic_vector(5 downto 0) := x"a" & "00";
	constant DATATYPE_TESTDATA_COUNTEREVENTFIFOHEADER : std_logic_vector(5 downto 0) := x"b" & "00";
	constant DATATYPE_TESTDATA_COUNTER : std_logic_vector(5 downto 0) := x"c" & "00";
	constant DATATYPE_DRS4MAX : std_logic_vector(5 downto 0) := x"d" & "00";
	constant DATATYPE_MISC : std_logic_vector(5 downto 0) := x"e" & "00";
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
	 alias writeMiscToFifo_bit : std_logic is packetConfig(11);
	 alias writeWhiteRabbitToFifo_bit : std_logic is packetConfig(12);
	 alias writeGpsToFifo_bit : std_logic is packetConfig(13);
	 alias writePixelRatesToFifo_bit : std_logic is packetConfig(14);
	 alias writeDebugToFifo_bit : std_logic is packetConfig(15);
	
	signal numberOfSamplesToRead : std_logic_vector(15 downto 0) := x"0000";
	signal registerDeviceId : std_logic_vector(15 downto 0) := x"a5a5"; -- ## dummy
--	signal packetConfig : std_logic_vector(15 downto 0) := x"0000";
	
	signal testDataWords : unsigned(15 downto 0) := x"0000";
	signal testDataCounter : unsigned(12 downto 0) := (others=>'0'); --  range 0 to 2**16-1 := 0;
	signal fifoTestDataEnabled : std_logic := '0';
	signal triggerTimingAndDrs4 : std_logic := '0';
	signal triggerTimingAndDrs4_old : std_logic := '0';
	signal newTriggerTimingAndDrs4Event : std_logic := '0';
	signal triggerTimingOnly : std_logic := '0';
	signal triggerTimingOnly_old : std_logic := '0';
	signal newTriggerTimingOnlyEvent : std_logic := '0';
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
	signal miscEvent : std_logic := '0';
	signal miscEvent_old : std_logic := '0';
	signal newMiscEvent : std_logic := '0';
					
	signal eventRateCounter : unsigned(15 downto 0) := (others=>'0');
	signal eventLostRateCounter : unsigned(15 downto 0) := (others=>'0');
	signal eventRateCounter_latched : std_logic_vector(15 downto 0) := (others=>'0');
	signal eventLostRateCounter_latched : std_logic_vector(15 downto 0) := (others=>'0');
	
	signal deviceId : std_logic_vector(15 downto 0) := (others=>'0');

	signal adcData : ltm9007_14_to_eventFifoSystem_t;
	signal drs4Data : drs4_to_eventFifoSystem_t;

begin

	adcData <= drs4AndAdcData.adcData;
	drs4Data <= drs4AndAdcData.drs4Data;

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
	
	gx: for i in 0 to SLOTS-1 generate 
		eventFifoIn(i*SLOT_WIDTH+SLOT_WIDTH-1 downto i*SLOT_WIDTH) <= eventFifoInSlots(i);
	end generate;

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
	registerRead.deviceId <= registerWrite.deviceId;
	deviceId <= registerWrite.deviceId;

	numberOfSamplesToRead <= registerWrite.numberOfSamplesToRead;
	registerRead.numberOfSamplesToRead <= registerWrite.numberOfSamplesToRead;
			
	--triggerEvent <= trigger.triggerNotDelayed or trigger.softTrigger;
	--triggerEvent <= trigger.eventFifoSystem;
	--triggerEvent <= trigger.stopDrs4;
	triggerTimingAndDrs4 <= trigger.timingAndDrs4;
	triggerTimingOnly <= trigger.timingOnly;
	gpsEvent <= '0'; --gpsTiming.newData;
	whiteRabbitEvent <= '0'; --whiteRabbitTiming.newData;
	miscEvent <= internalTiming.tick_min; -- or registerWrite.forceMiscData;
	pixelRateCounterEvent <= pixelRateCounter.newData;
	
	registerRead.eventRateCounter <= eventRateCounter_latched;
	registerRead.eventLostRateCounter <= eventLostRateCounter_latched;
	


P1:process (registerWrite.clock)
	constant HEADER_LENGTH : integer := 1;
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
			state1 <= idle;
			eventLength <= to_unsigned(0,eventLength'length);
			eventFifoErrorCounter <= to_unsigned(0,eventFifoErrorCounter'length);
			chargeDone <= '0';
			baselineDone <= '0';
			gpsEvent_old <= '0';
			newGpsEvent <= '0';
			whiteRabbitEvent_old <= '0';
			newWhiteRabbitEvent <= '0';
			triggerTimingAndDrs4_old <= '0';
			triggerTimingOnly_old <= '0';
			newTriggerTimingAndDrs4Event <= '0';
			newTriggerTimingOnlyEvent <= '0';
			pixelRateCounterEvent_old <= '0';
			miscEvent_old <= '0';
			newMiscEvent <= '0';
			newPixelRateCounterEvent <= '0';
			eventRateCounter <= (others => '0');
			eventLostRateCounter <= (others => '0');
			eventRateCounter_latched <= (others => '0');
			eventLostRateCounter_latched <= (others => '0');
		else
			eventFifoClear <= registerWrite.eventFifoClear;
			--eventFifoClearBuffer <= registerWrite.eventFifoClear;
			
			chargeDone <= chargeDone or adcData.chargeDone;
			baselineDone <= baselineDone or adcData.baselineDone;

			miscEvent_old <= miscEvent;
			if(((miscEvent = '1') and (miscEvent_old = '0') and (writeMiscToFifo_bit = '1')) or (registerWrite.forceMiscData = '1')) then
				newMiscEvent <= '1';
			end if;
					
			gpsEvent_old <= gpsEvent;
			if((gpsEvent = '1') and (gpsEvent_old = '0') and (writeGpsToFifo_bit = '1')) then
				newGpsEvent <= '1';
			end if;
					
			whiteRabbitEvent_old <= whiteRabbitEvent;
			if((whiteRabbitEvent = '1') and (whiteRabbitEvent_old = '0') and (writeGpsToFifo_bit = '1')) then
				newWhiteRabbitEvent <= '1';
			end if;
					
			triggerTimingAndDrs4_old <= triggerTimingAndDrs4;
			if((triggerTimingAndDrs4 = '1') and (triggerTimingAndDrs4_old = '0')) then
				newTriggerTimingAndDrs4Event <= '1';
			end if;
			
			triggerTimingOnly_old <= triggerTimingOnly;
			if((triggerTimingOnly = '1') and (triggerTimingOnly_old = '0')) then
				newTriggerTimingOnlyEvent <= '1';
			end if;
			
			pixelRateCounterEvent_old <= pixelRateCounterEvent;
			if((pixelRateCounterEvent = '1') and (pixelRateCounterEvent_old = '0') and (writePixelRatesToFifo_bit = '1')) then
				newPixelRateCounterEvent <= '1';
			end if;


			case state1 is
				when idle =>
					if((newTriggerTimingAndDrs4Event = '1') and (headerNeeded = '1')) then
						state1 <= waitForRoiData;
						
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
							eventLength <= unsigned(numberOfSamplesToRead) + tempLength;
						end if;
						if(testDataEventFifoCounter_bit = '1') then
							eventLength <= unsigned(numberOfSamplesToRead) + HEADER_LENGTH;
						end if;
					end if;

					-- ## hack.... the logic here ist not well distributed
					if((newTriggerTimingOnlyEvent = '1') and (headerNeeded = '1')) then
						state1 <= writeHeader;
						
						tempLength := to_unsigned(HEADER_LENGTH,tempLength'length)
							+ lutAdder6(writeDebugToFifo_bit
								& '0' --writeDrs4ChargeToFifo_bit
								& '0' --writeDrs4ChargeToFifo_bit
								& '0' --writeDrs4BaselineToFifo_bit
								& '0' --writeDrs4BaselineToFifo_bit
								& '0') --writeDrs4TimingToFifo_bit)
							+ lutAdder6(writeTriggerTimingToFifo_bit
								& "00000");
						
						eventLength <= tempLength;
						
						--if(writeDrs4SamplingToFifo_bit = '1') then
						--	eventLength <= unsigned(numberOfSamplesToRead) + tempLength;
						--end if;
						--if(testDataEventFifoCounter_bit = '1') then
						--	eventLength <= unsigned(numberOfSamplesToRead) + HEADER_LENGTH;
						--end if;
					end if;

					if(newMiscEvent = '1') then
						state1 <= writeMisc1;
					end if;
					
					if(newGpsEvent = '1') then
						state1 <= writeGps;
					end if;
					
					if(newWhiteRabbitEvent = '1') then
						state1 <= writeWhiteRabbit;
					end if;

					if(newPixelRateCounterEvent = '1') then
						state1 <= writePixelRateCounter0;
					end if;

					dataTypeCounter <= (others=>'0'); -- ## not nice... should be a separate prepare state
					chargePart <= '0'; -- ## not nice...
					baselinePart <= '0'; -- ## not nice...
				
				when writePixelRateCounter0 => -- no timing information here....
					newPixelRateCounterEvent <= '0';
					nextState := writePixelRateCounter1;
					if(unsigned(eventFifoWords) < (eventFifoWordsMax-3)) then
						eventFifoInSlots <= (others=>x"0000");
						eventFifoInSlots(0) <= DATATYPE_PIXELRATES & "00" & x"00";
						eventFifoInSlots(1) <= pixelRateCounter.realTimeCounterLatched(63 downto 48);
						eventFifoInSlots(2) <= pixelRateCounter.realTimeCounterLatched(47 downto 32);
						eventFifoInSlots(3) <= pixelRateCounter.realTimeCounterLatched(31 downto 16);
						eventFifoInSlots(4) <= pixelRateCounter.realTimeCounterLatched(15 downto 0); 
						eventFifoInSlots(5) <= pixelRateCounter.realTimeDeltaCounterLatched(63 downto 48);
						eventFifoInSlots(6) <= pixelRateCounter.realTimeDeltaCounterLatched(47 downto 32);
						eventFifoInSlots(7) <= pixelRateCounter.realTimeDeltaCounterLatched(31 downto 16);
						eventFifoInSlots(8) <= pixelRateCounter.realTimeDeltaCounterLatched(15 downto 0);
						eventFifoWriteRequest <= '1'; -- autoreset
					else
						eventFifoErrorCounter <= eventFifoErrorCounter + 1;
						state1 <= idle;
					end if;
					state1 <= nextState;

				when writePixelRateCounter1 => -- no timing information here....
					newPixelRateCounterEvent <= '0'; -- ## two times?!
					nextState := writePixelRateCounter2;
					--if(unsigned(eventFifoWords) < (eventFifoWordsMax-2)) then
						eventFifoInSlots <= (others=>x"0000");
						eventFifoInSlots(0) <= DATATYPE_PIXELRATES & "00" & x"01";
						eventFifoInSlots(1) <= pixelRateCounter.rateAllEdgesLatched(0);
						eventFifoInSlots(2) <= pixelRateCounter.rateAllEdgesLatched(1);
						eventFifoInSlots(3) <= pixelRateCounter.rateAllEdgesLatched(2);
						eventFifoInSlots(4) <= pixelRateCounter.rateAllEdgesLatched(3);
						eventFifoInSlots(5) <= pixelRateCounter.rateAllEdgesLatched(4);
						eventFifoInSlots(6) <= pixelRateCounter.rateAllEdgesLatched(5);
						eventFifoInSlots(7) <= pixelRateCounter.rateAllEdgesLatched(6);
						eventFifoInSlots(8) <= pixelRateCounter.rateAllEdgesLatched(7);
						eventFifoWriteRequest <= '1'; -- autoreset
					--else
					--	eventFifoErrorCounter <= eventFifoErrorCounter + 1;
					--end if;
					state1 <= nextState;

				when writePixelRateCounter2 =>
					newPixelRateCounterEvent <= '0'; -- ## 3 times?!
					nextState := writePixelRateCounter3;
					--if(unsigned(eventFifoWords) < (eventFifoWordsMax-1)) then
						eventFifoInSlots <= (others=>x"0000");
						eventFifoInSlots(0) <= DATATYPE_PIXELRATES & "00" & x"02";
						eventFifoInSlots(1) <= pixelRateCounter.rateFirstHitsDuringGateLatched(0);
						eventFifoInSlots(2) <= pixelRateCounter.rateFirstHitsDuringGateLatched(1);
						eventFifoInSlots(3) <= pixelRateCounter.rateFirstHitsDuringGateLatched(2);
						eventFifoInSlots(4) <= pixelRateCounter.rateFirstHitsDuringGateLatched(3);
						eventFifoInSlots(5) <= pixelRateCounter.rateFirstHitsDuringGateLatched(4);
						eventFifoInSlots(6) <= pixelRateCounter.rateFirstHitsDuringGateLatched(5);
						eventFifoInSlots(7) <= pixelRateCounter.rateFirstHitsDuringGateLatched(6);
						eventFifoInSlots(8) <= pixelRateCounter.rateFirstHitsDuringGateLatched(7);
						eventFifoWriteRequest <= '1'; -- autoreset
					--else
					--	eventFifoErrorCounter <= eventFifoErrorCounter + 1;
					--end if;
					state1 <= nextState;

				when writePixelRateCounter3 =>
					newPixelRateCounterEvent <= '0'; -- ## 4 times?!
					nextState := idle;
					--if(unsigned(eventFifoWords) < (eventFifoWordsMax)) then
						eventFifoInSlots <= (others=>x"0000");
						eventFifoInSlots(0) <= DATATYPE_PIXELRATES & "00" & x"03";
						eventFifoInSlots(1) <= pixelRateCounter.rateAdditionalHitsDuringGateLatched(0);
						eventFifoInSlots(2) <= pixelRateCounter.rateAdditionalHitsDuringGateLatched(1);
						eventFifoInSlots(3) <= pixelRateCounter.rateAdditionalHitsDuringGateLatched(2);
						eventFifoInSlots(4) <= pixelRateCounter.rateAdditionalHitsDuringGateLatched(3);
						eventFifoInSlots(5) <= pixelRateCounter.rateAdditionalHitsDuringGateLatched(4);
						eventFifoInSlots(6) <= pixelRateCounter.rateAdditionalHitsDuringGateLatched(5);
						eventFifoInSlots(7) <= pixelRateCounter.rateAdditionalHitsDuringGateLatched(6);
						eventFifoInSlots(8) <= pixelRateCounter.rateAdditionalHitsDuringGateLatched(7);
						eventFifoWriteRequest <= '1'; -- autoreset
					--else
					--	eventFifoErrorCounter <= eventFifoErrorCounter + 1;
					--end if;
					state1 <= nextState;

				when writeMisc1 =>
					newMiscEvent <= '0';
					nextState := writeMisc2;
					if(unsigned(eventFifoWords) < (eventFifoWordsMax)) then
						eventFifoInSlots <= (others=>x"dead");
						eventFifoInSlots(0) <= DATATYPE_MISC & "00" & x"00";
						eventFifoInSlots(1) <= FIRMWAREVERSION;
						eventFifoInSlots(2) <= PROTOCOLVERSION;
						eventFifoInSlots(3) <= deviceId;
						eventFifoWriteRequest <= '1'; -- autoreset
					else
						eventFifoErrorCounter <= eventFifoErrorCounter + 1;
					end if;
					state1 <= nextState;

				when writeMisc2 =>
					newMiscEvent <= '0';
					nextState := writeMisc3;
					if(unsigned(eventFifoWords) < (eventFifoWordsMax)) then
						eventFifoInSlots <= (others=>x"dead");
						eventFifoInSlots(0) <= DATATYPE_MISC & "00" & x"01";
						eventFifoInSlots(1) <= x"0" & dac1_stats.channelB(0); --thesholds
						eventFifoInSlots(2) <= x"0" & dac1_stats.channelB(1);
						eventFifoInSlots(3) <= x"0" & dac1_stats.channelB(2);
						eventFifoInSlots(4) <= x"0" & dac1_stats.channelB(3);
						eventFifoInSlots(5) <= x"0" & dac1_stats.channelB(4);
						eventFifoInSlots(6) <= x"0" & dac1_stats.channelB(5);
						eventFifoInSlots(7) <= x"0" & dac1_stats.channelB(6);
						eventFifoInSlots(8) <= x"0" & dac1_stats.channelB(7);
						eventFifoWriteRequest <= '1'; -- autoreset
					else
						eventFifoErrorCounter <= eventFifoErrorCounter + 1;
					end if;
					state1 <= nextState;

				when writeMisc3 =>
					newMiscEvent <= '0';
					nextState := writeMisc4;
					if(unsigned(eventFifoWords) < (eventFifoWordsMax)) then
						eventFifoInSlots <= (others=>x"dead");
						eventFifoInSlots(0) <= DATATYPE_MISC & "00" & x"02";
						eventFifoInSlots(1) <= registerWrite.miscSlotA(0); -- defined by software, may be pmt hv
						eventFifoInSlots(2) <= registerWrite.miscSlotA(1);
						eventFifoInSlots(3) <= registerWrite.miscSlotA(2);
						eventFifoInSlots(4) <= registerWrite.miscSlotA(3);
						eventFifoInSlots(5) <= registerWrite.miscSlotA(4);
						eventFifoInSlots(6) <= registerWrite.miscSlotA(5);
						eventFifoInSlots(7) <= registerWrite.miscSlotA(6);
						eventFifoInSlots(8) <= registerWrite.miscSlotA(7);
						eventFifoWriteRequest <= '1'; -- autoreset
					else
						eventFifoErrorCounter <= eventFifoErrorCounter + 1;
					end if;
					state1 <= nextState;

				when writeMisc4 =>
					newMiscEvent <= '0';
					nextState := idle;
					if(unsigned(eventFifoWords) < (eventFifoWordsMax)) then
						eventFifoInSlots <= (others=>x"dead");
						eventFifoInSlots(0) <= DATATYPE_MISC & "00" & x"03";
						eventFifoInSlots(1) <= registerWrite.miscSlotB(0); -- defined by software, may be LED voltages
						eventFifoInSlots(2) <= registerWrite.miscSlotB(1);
						eventFifoInSlots(3) <= registerWrite.miscSlotB(2);
						eventFifoInSlots(4) <= registerWrite.miscSlotB(3);
						eventFifoInSlots(5) <= registerWrite.miscSlotB(4);
						eventFifoInSlots(6) <= registerWrite.miscSlotB(5);
						eventFifoInSlots(7) <= registerWrite.miscSlotB(6);
						eventFifoInSlots(8) <= registerWrite.miscSlotB(7);
						eventFifoWriteRequest <= '1'; -- autoreset
					else
						eventFifoErrorCounter <= eventFifoErrorCounter + 1;
					end if;
					state1 <= nextState;

				when writeGps =>
					newGpsEvent <= '0';
					nextState := idle;
					if(unsigned(eventFifoWords) < (eventFifoWordsMax)) then
						eventFifoInSlots <= (others=>x"0000");
						eventFifoInSlots(0) <= DATATYPE_GPS & "00" & x"00";
					--	eventFifoInSlots(1) <= gpsTiming.week;
					--	eventFifoInSlots(2) <= gpsTiming.timeOfWeekMilliSecond(31 downto 16);
					--	eventFifoInSlots(3) <= gpsTiming.timeOfWeekMilliSecond(15 downto 0);
					--	eventFifoInSlots(4) <= gpsTiming.differenceGpsToLocalClock;
					--	eventFifoInSlots(5) <= gpsTiming.realTimeCounterLatched(63 downto 48);
					--	eventFifoInSlots(6) <= gpsTiming.realTimeCounterLatched(47 downto 32);
					--	eventFifoInSlots(7) <= gpsTiming.realTimeCounterLatched(31 downto 16);
					--	eventFifoInSlots(8) <= gpsTiming.realTimeCounterLatched(15 downto 0);
						eventFifoWriteRequest <= '1'; -- autoreset
					else
						eventFifoErrorCounter <= eventFifoErrorCounter + 1;
					end if;
					state1 <= nextState;

				when writeWhiteRabbit =>
					newWhiteRabbitEvent <= '0';
					nextState := idle;
					if(unsigned(eventFifoWords) < (eventFifoWordsMax)) then
						eventFifoInSlots <= (others=>x"0000");
						eventFifoInSlots(0) <= DATATYPE_WHITERABBIT & "00" & x"00";
					--	eventFifoInSlots(1) <= "000000000" & whiteRabbitTiming.irigBinaryYearsLatched;
					--	eventFifoInSlots(2) <= "0000000" & whiteRabbitTiming.irigBinaryDaysLatched;
					--	eventFifoInSlots(3) <= x"000" & "000" & whiteRabbitTiming.irigBinarySecondsLatched(16);
					--	eventFifoInSlots(4) <= whiteRabbitTiming.irigBinarySecondsLatched(15 downto 0);
					--	eventFifoInSlots(5) <= whiteRabbitTiming.realTimeCounterLatched(63 downto 48);
					--	eventFifoInSlots(6) <= whiteRabbitTiming.realTimeCounterLatched(47 downto 32);
					--	eventFifoInSlots(7) <= whiteRabbitTiming.realTimeCounterLatched(31 downto 16);
					--	eventFifoInSlots(8) <= whiteRabbitTiming.realTimeCounterLatched(15 downto 0);
						eventFifoWriteRequest <= '1'; -- autoreset
					else
						eventFifoErrorCounter <= eventFifoErrorCounter + 1;
					end if;
					state1 <= nextState;
					
				when waitForRoiData =>
					if(drs4Data.regionOfInterestReady = '1') then
						state1 <= writeHeader;
					end if;

				when writeHeader =>
					increaseEventCounter <= '1'; -- autoreset
					if(unsigned(eventFifoWords) < (eventFifoWordsMax - eventLength)) then
						eventFifoInSlots <= (others=>x"0000");
						eventFifoInSlots(0) <= DATATYPE_HEADER & "00" & x"00";
						eventFifoInSlots(1) <= std_logic_vector(eventCount(31 downto 16));
						eventFifoInSlots(2) <= std_logic_vector(eventCount(15 downto 0));
						eventFifoInSlots(3) <= std_logic_vector(eventLength);
						eventFifoInSlots(4) <= drs4Data.realTimeCounter_latched(63 downto 48);
						eventFifoInSlots(5) <= drs4Data.realTimeCounter_latched(47 downto 32);
						eventFifoInSlots(6) <= drs4Data.realTimeCounter_latched(31 downto 16);
						eventFifoInSlots(7) <= drs4Data.realTimeCounter_latched(15 downto 0);
						eventFifoInSlots(8) <= "000000" & drs4Data.regionOfInterest;
							
						state1 <= writeDebug;

						if(newTriggerTimingAndDrs4Event = '1') then
							newTriggerTimingAndDrs4Event <= '0';
							state1 <= writeDrs4Sampling;
						end if;
						if(newTriggerTimingOnlyEvent = '1') then
							newTriggerTimingOnlyEvent <= '0';
							state1 <= writeTriggerTiming;
						end if;
						
						--if(testDataEventFifoStatic_bit = '1') then
						--	eventFifoInSlots(0) <= DATATYPE_TESTDATA_STATICEVENTFIFOHEADER & "00" & x"00"; -- ## not implemented...
						--elsif(testDataEventFifoCounter_bit = '1') then
						--	eventFifoInSlots(0) <= DATATYPE_TESTDATA_COUNTEREVENTFIFOHEADER & "00" & x"00"; -- ## not implemented...
						--	state1 <= testData;
						--	testDataCounter <= (others=>'0');
						--	testDataWords <= to_unsigned(0,testDataWords'length);
						--else
						--	eventFifoInSlots(0) <= DATATYPE_HEADER & "00" & x"00"; -- ## 'unknown' as default would be better
						--end if;
						
						eventFifoWriteRequest <= '1'; -- autoreset
						
						-- ## maybe we can save some LEs here if the assignment of eventFifoIn is changed
						
						eventRateCounter <= eventRateCounter + 1;
						if(eventRateCounter = x"ffff") then 
							eventRateCounter <= x"ffff";
						end if;
					else
						state1 <= idle;
						eventFifoErrorCounter <= eventFifoErrorCounter + 1;
							
						eventLostRateCounter <= eventLostRateCounter + 1;
						if(eventLostRateCounter = x"ffff") then 
							eventLostRateCounter <= x"ffff";
						end if;
					end if;
				
				when writeDebug =>
					nextState := writeTriggerTiming;
					if(writeDebugToFifo_bit = '1') then
						eventFifoInSlots <= (others=>x"0000");
						eventFifoInSlots(0) <= DATATYPE_DEBUG & "00" & x"00";
						eventFifoInSlots(1) <= std_logic_vector(eventFifoFullCounter);
						eventFifoInSlots(2) <= std_logic_vector(eventFifoOverflowCounter);
						eventFifoInSlots(3) <= std_logic_vector(eventFifoUnderflowCounter);
						eventFifoInSlots(4) <= std_logic_vector(eventFifoErrorCounter); 
						--eventFifoInSlots(5) <= x"0000"; -- 
						--eventFifoInSlots(6) <= x"0000"; -- 
						--eventFifoInSlots(7) <= x"0000"; -- 
						--eventFifoInSlots(8) <= x"0000"; -- some masks...
						eventFifoWriteRequest <= '1'; -- autoreset
					end if;
					state1 <= nextState;
					
				when writeTriggerTiming =>
					nextState := idle;
					if(writeTriggerTimingToFifo_bit = '1') then
						if(triggerTiming.newDataValid = '1') then
							eventFifoInSlots <= (others=>x"0000");
							--eventFifoInSlots(0) <= DATATYPE_TRIGGERTIMING & "00" & x"00";
							eventFifoInSlots(0) <= DATATYPE_UVLOGGER_TRIGGERTIMING & "00" & x"00";
							eventFifoInSlots(1) <= triggerTiming.channel(0);
							eventFifoInSlots(2) <= triggerTiming.channel(1);
							eventFifoInSlots(3) <= triggerTiming.channel(2);
							eventFifoInSlots(4) <= triggerTiming.channel(3);
							eventFifoInSlots(5) <= triggerTiming.channel(4);
							eventFifoInSlots(6) <= triggerTiming.channel(5);
							eventFifoInSlots(7) <= triggerTiming.channel(6);
							eventFifoInSlots(8) <= triggerTiming.channel(7);
							eventFifoWriteRequest <= '1'; -- autoreset
							state1 <= nextState;
						end if;
					else	
						state1 <= nextState;
					end if;
				
				when writeDrs4Sampling =>
					nextState := writeDrs4Baseline;
					if(writeDrs4SamplingToFifo_bit = '1') then
						if(adcData.newData = '1') then 
							eventFifoInSlots <= (others=>x"0000");
							eventFifoInSlots(0) <= DATATYPE_DSR4SAMPLING & std_logic_vector(dataTypeCounter);
							eventFifoInSlots(1) <= adcData.channel(0);
							eventFifoInSlots(2) <= adcData.channel(1);
							eventFifoInSlots(3) <= adcData.channel(2);
							eventFifoInSlots(4) <= adcData.channel(3);
							eventFifoInSlots(5) <= adcData.channel(4);
							eventFifoInSlots(6) <= adcData.channel(5);
							eventFifoInSlots(7) <= adcData.channel(6);
							eventFifoInSlots(8) <= adcData.channel(7);
							eventFifoWriteRequest <= '1'; -- autoreset
							dataTypeCounter <= dataTypeCounter + 1;
						end if;

						if(adcData.samplingDone = '1') then
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
								eventFifoInSlots <= (others=>x"0000");
								eventFifoInSlots(0) <= DATATYPE_DSR4BASELINE & std_logic_vector(dataTypeCounter);
								eventFifoInSlots(1) <= x"00" & adcData.baseline(0)(23 downto 16);
								eventFifoInSlots(2) <= x"00" & adcData.baseline(1)(23 downto 16);
								eventFifoInSlots(3) <= x"00" & adcData.baseline(2)(23 downto 16);
								eventFifoInSlots(4) <= x"00" & adcData.baseline(3)(23 downto 16);
								eventFifoInSlots(5) <= x"00" & adcData.baseline(4)(23 downto 16);
								eventFifoInSlots(6) <= x"00" & adcData.baseline(5)(23 downto 16);
								eventFifoInSlots(7) <= x"00" & adcData.baseline(6)(23 downto 16);
								eventFifoInSlots(8) <= x"00" & adcData.baseline(7)(23 downto 16);
								eventFifoWriteRequest <= '1'; -- autoreset
								dataTypeCounter <= dataTypeCounter + 1;
								baselinePart <= '1';
							end if;
							if(baselinePart = '1') then
								eventFifoInSlots <= (others=>x"0000");
								eventFifoInSlots(0) <= DATATYPE_DSR4BASELINE & std_logic_vector(dataTypeCounter); 
								eventFifoInSlots(1) <= adcData.baseline(0)(15 downto 0);
								eventFifoInSlots(2) <= adcData.baseline(1)(15 downto 0);
								eventFifoInSlots(3) <= adcData.baseline(2)(15 downto 0);
								eventFifoInSlots(4) <= adcData.baseline(3)(15 downto 0);
								eventFifoInSlots(5) <= adcData.baseline(4)(15 downto 0);
								eventFifoInSlots(6) <= adcData.baseline(5)(15 downto 0);
								eventFifoInSlots(7) <= adcData.baseline(6)(15 downto 0);
								eventFifoInSlots(8) <= adcData.baseline(7)(15 downto 0);
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
								eventFifoInSlots <= (others=>x"0000");
								eventFifoInSlots(0) <= DATATYPE_DSR4CHARGE & std_logic_vector(dataTypeCounter);
								eventFifoInSlots(1) <= x"00" & adcData.charge(0)(23 downto 16);
								eventFifoInSlots(2) <= x"00" & adcData.charge(1)(23 downto 16);
								eventFifoInSlots(3) <= x"00" & adcData.charge(2)(23 downto 16);
								eventFifoInSlots(4) <= x"00" & adcData.charge(3)(23 downto 16);
								eventFifoInSlots(5) <= x"00" & adcData.charge(4)(23 downto 16);
								eventFifoInSlots(6) <= x"00" & adcData.charge(5)(23 downto 16);
								eventFifoInSlots(7) <= x"00" & adcData.charge(6)(23 downto 16);
								eventFifoInSlots(8) <= x"00" & adcData.charge(7)(23 downto 16);
								eventFifoWriteRequest <= '1'; -- autoreset
								dataTypeCounter <= dataTypeCounter + 1;
								chargePart <= '1';
							end if;
							if(chargePart = '1') then
								eventFifoInSlots <= (others=>x"0000");
								eventFifoInSlots(0) <= DATATYPE_DSR4CHARGE & std_logic_vector(dataTypeCounter); 
								eventFifoInSlots(1) <= adcData.charge(0)(15 downto 0);
								eventFifoInSlots(2) <= adcData.charge(1)(15 downto 0);
								eventFifoInSlots(3) <= adcData.charge(2)(15 downto 0);
								eventFifoInSlots(4) <= adcData.charge(3)(15 downto 0);
								eventFifoInSlots(5) <= adcData.charge(4)(15 downto 0);
								eventFifoInSlots(6) <= adcData.charge(5)(15 downto 0);
								eventFifoInSlots(7) <= adcData.charge(6)(15 downto 0);
								eventFifoInSlots(8) <= adcData.charge(7)(15 downto 0);
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
							eventFifoInSlots <= (others=>x"0000");
							eventFifoInSlots(0) <= DATATYPE_DRS4MAX & "00" & x"00";
							eventFifoInSlots(1) <= "00" & adcData.maxValue(0)(13 downto 0);
							eventFifoInSlots(2) <= "00" & adcData.maxValue(1)(13 downto 0);
							eventFifoInSlots(3) <= "00" & adcData.maxValue(2)(13 downto 0);
							eventFifoInSlots(4) <= "00" & adcData.maxValue(3)(13 downto 0);
							eventFifoInSlots(5) <= "00" & adcData.maxValue(4)(13 downto 0);
							eventFifoInSlots(6) <= "00" & adcData.maxValue(5)(13 downto 0);
							eventFifoInSlots(7) <= "00" & adcData.maxValue(6)(13 downto 0);
							eventFifoInSlots(8) <= "00" & adcData.maxValue(7)(13 downto 0);
							eventFifoWriteRequest <= '1'; -- autoreset
						
							state1 <= nextState;
						--	chargeDone <= '0';
						--end if;
					else
						state1 <= nextState;
					end if;
					
				when writeDrs4Timing =>
					nextState := writeTriggerTiming;
					if(writeDrs4TimingToFifo_bit = '1') then
					--	if(abc.drs4Timing.newData = '1') then
							eventFifoInSlots <= (others=>x"dead");
							eventFifoInSlots(0) <= DATATYPE_DSR4TIMING & "00" & x"00";
							-- ## not implemented...
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
						eventFifoInSlots <= (others=>x"0000");
						eventFifoInSlots(0) <= DATATYPE_TESTDATA_COUNTER & std_logic_vector(testDataWords(9 downto 0));
						eventFifoInSlots(1) <= std_logic_vector(eventCount(31 downto 16));
						eventFifoInSlots(2) <= std_logic_vector(eventCount(15 downto 0));
						eventFifoInSlots(3) <= std_logic_vector(eventLength);
						eventFifoInSlots(4) <= std_logic_vector(testDataCounter) & "011";
						eventFifoInSlots(5) <= std_logic_vector(testDataCounter) & "100";
						eventFifoInSlots(6) <= std_logic_vector(testDataCounter) & "101";
						eventFifoInSlots(7) <= std_logic_vector(testDataCounter) & "110";
						eventFifoInSlots(8) <= std_logic_vector(testDataCounter) & "111";
						testDataCounter <= testDataCounter + 1;
						testDataWords <= testDataWords + 1;
						eventFifoWriteRequest <= '1'; -- autoreset
						state1 <= testData;
					else
						state1 <= idle;
						eventFifoErrorCounter <= eventFifoErrorCounter + 1;
					end if;

				when testData =>
					if(testDataWords < unsigned(numberOfSamplesToRead))then
						eventFifoInSlots <= (others=>x"0000");
						eventFifoInSlots(0) <= DATATYPE_TESTDATA_COUNTER & std_logic_vector(testDataWords(9 downto 0));
						eventFifoInSlots(1) <= std_logic_vector(testDataCounter) & "000";
						eventFifoInSlots(2) <= std_logic_vector(testDataCounter) & "001";
						eventFifoInSlots(3) <= std_logic_vector(testDataCounter) & "010";
						eventFifoInSlots(4) <= std_logic_vector(testDataCounter) & "011";
						eventFifoInSlots(5) <= std_logic_vector(testDataCounter) & "100";
						eventFifoInSlots(6) <= std_logic_vector(testDataCounter) & "101";
						eventFifoInSlots(7) <= std_logic_vector(testDataCounter) & "110";
						eventFifoInSlots(8) <= std_logic_vector(testDataCounter) & "111";
						testDataCounter <= testDataCounter + 1;
						testDataWords <= testDataWords + 1;
						eventFifoWriteRequest <= '1'; -- autoreset
					else
						state1 <= idle;
					end if;
				
				when others =>
					state1 <= idle;
			end case;

			if(rateCounterTimeOut = '1') then
				eventRateCounter_latched <= std_logic_vector(eventRateCounter);
				eventRateCounter <= (others => '0');
				eventLostRateCounter_latched <= std_logic_vector(eventLostRateCounter);
				eventLostRateCounter <= (others => '0');
			end if;
			
		end if;
	end if;
end process P1;

--WeventFifoWordsDma32 <= (unsigned(eventFifoWordsDma) * 9) + eventFifoWordsDmaSlice;


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

--P3:process (registerWrite.clock)
--begin
--	if rising_edge(registerWrite.clock) then
--		if (registerWrite.reset = '1') then
--			counterSecounds <= to_unsigned(0,counterSecounds'length);
--			realTimeCounterSecounds <= to_unsigned(0,realTimeCounterSecounds'length);
--			realTimeCounterSubSecounds <= to_unsigned(0,realTimeCounterSubSecounds'length);
--		else
--		
--			counterSecounds <= counterSecounds + 1;
--			if(counterSecounds >= to_unsigned(118750000,counterSecounds'length)) then
--				counterSecounds <= to_unsigned(0,counterSecounds'length);
--				realTimeCounterSecounds <= realTimeCounterSecounds + 1;
--				realTimeCounterSubSecounds <= to_unsigned(0,realTimeCounterSubSecounds'length);
--			else
--				realTimeCounterSubSecounds <= realTimeCounterSubSecounds + 8;
--			end if;			
--		end if;
--	end if;
--end process P3;

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
