----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:05:09 03/01/2017 
-- Design Name: 
-- Module Name:    testRam_test - Behavioral 
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

entity registerInterface_polarstern is
	generic 
	(
		subAddress : std_logic_vector(15 downto 0) := x"0000";
		subAddressMask : std_logic_vector(15 downto 0) := x"0000";
		moduleEnabled : integer := 1
	);
	port
	(
		addressAndControlBus : in std_logic_vector(31 downto 0);
		dataBusIn : in std_logic_vector(15 downto 0);
		dataBusOut : out std_logic_vector(15 downto 0);

		triggerTimeToEdge_0r : in triggerTimeToEdge_registerRead_t;
		triggerTimeToEdge_0w : out triggerTimeToEdge_registerWrite_t;
		eventFifoSystem_0r : in eventFifoSystem_registerRead_t;
		eventFifoSystem_0w : out eventFifoSystem_registerWrite_t;
		triggerDataDelay_0r : in triggerDataDelay_registerRead_t;
		triggerDataDelay_0w : out triggerDataDelay_registerWrite_t;
		pixelRateCounter_0r : in pixelRateCounter_polarstern_registerRead_t;
		pixelRateCounter_0w : out pixelRateCounter_polarstern_registerWrite_t;
		dac088s085_x3_0r : in dac088s085_x3_registerRead_t;
		dac088s085_x3_0w : out dac088s085_x3_registerWrite_t;
		dac088s085_x3_1r : in dac088s085_x3_registerRead_t;
		dac088s085_x3_1w : out dac088s085_x3_registerWrite_t;
		gpsTiming_0r : in gpsTiming_registerRead_t;
		gpsTiming_0w : out gpsTiming_registerWrite_t;
		ad56x1_0r : in ad56x1_registerRead_t;
		ad56x1_0w : out ad56x1_registerWrite_t;
		triggerLogic_0r : in p_triggerLogic_registerRead_t;
		triggerLogic_0w : out p_triggerLogic_registerWrite_t;
		internalTiming_0r : in internalTiming_registerRead_t;
		internalTiming_0w : out internalTiming_registerWrite_t
	);
end registerInterface_polarstern;

architecture behavior of registerInterface_polarstern is

	signal chipSelectInternal : std_logic := '0';
	signal readDataBuffer : std_logic_vector(15 downto 0) := (others => '0');
	
	signal registerA : std_logic_vector(7 downto 0) := (others => '0');
	signal registerB : std_logic_vector(15 downto 0) := (others => '0');
	
	signal controlBus : smc_bus;
	
	signal debugReset : std_logic := '0';
	signal eventFifoClear : std_logic := '0';
	
begin

g0: if moduleEnabled /= 0 generate
	controlBus <= smc_vectorToBus(addressAndControlBus);
	--chipSelectInternal <= '1' when ((controlBus.chipSelect = '1') and ((controlBus.address(15 downto 0) and subAddressMask) = subAddress)) else '0';
	chipSelectInternal <= controlBus.chipSelect;
--	dataBusWrite <= '1' when ((chipSelectInternal = '1') and (controlBus.read = '1')) else '0';
	dataBusOut <= readDataBuffer;	
	
	triggerTimeToEdge_0w.clock <= controlBus.clock;
	triggerTimeToEdge_0w.reset <= controlBus.reset;
	eventFifoSystem_0w.clock <= controlBus.clock;
	eventFifoSystem_0w.reset <= controlBus.reset or debugReset;
	eventFifoSystem_0w.eventFifoClear <= eventFifoClear;
	triggerDataDelay_0w.clock <= controlBus.clock;
	triggerDataDelay_0w.reset <= controlBus.reset;
	pixelRateCounter_0w.clock <= controlBus.clock;
	pixelRateCounter_0w.reset <= controlBus.reset;
	dac088s085_x3_0w.clock <= controlBus.clock;
	dac088s085_x3_0w.reset <= controlBus.reset;
	dac088s085_x3_1w.clock <= controlBus.clock;
	dac088s085_x3_1w.reset <= controlBus.reset;
	gpsTiming_0w.clock <= controlBus.clock;
	gpsTiming_0w.reset <= controlBus.reset;
	ad56x1_0w.clock <= controlBus.clock;
	ad56x1_0w.reset <= controlBus.reset;
	triggerLogic_0w.clock <= controlBus.clock;
	triggerLogic_0w.reset <= controlBus.reset;
	internalTiming_0w.clock <= controlBus.clock;
	internalTiming_0w.reset <= controlBus.reset;
	--triggerLogic_0w.tick_ms <= gpsTiming_0r.tick_ms;
	
	
	P0:process (controlBus.clock)
	begin
		if rising_edge(controlBus.clock) then
			eventFifoSystem_0w.nextWord <= '0'; -- autoreset
			eventFifoSystem_0w.forceIrq <= '0'; -- autoreset
			eventFifoSystem_0w.clearEventCounter <= '0'; -- autoreset
			triggerDataDelay_0w.resetDelay <= '0'; -- autoreset
			pixelRateCounter_0w.resetCounter <= (others=>'0'); -- autoreset
			triggerLogic_0w.resetCounter <= (others=>'0'); -- autoreset
			debugReset <= '0'; -- autoreset
			eventFifoClear <= '0'; -- autoreset
			dac088s085_x3_0w.init <= '0'; -- autoreset
			dac088s085_x3_1w.init <= '0'; -- autoreset
			--ad56x1_0w.init <= '0'; -- autoreset
			ad56x1_0w.valueChangedChip0 <= '0'; -- autoreset
			ad56x1_0w.valueChangedChip1 <= '0'; -- autoreset
			--drs4_0w.stoftTrigger <= '0'; -- autoreset
			--drs4_0w.resetStates <= '0'; -- autoreset
			dac088s085_x3_0w.valuesChangedChip0 <= (others=>'0'); -- autoreset
			dac088s085_x3_0w.valuesChangedChip1 <= (others=>'0'); -- autoreset
			dac088s085_x3_0w.valuesChangedChip2 <= (others=>'0'); -- autoreset
			dac088s085_x3_1w.valuesChangedChip0 <= (others=>'0'); -- autoreset
			dac088s085_x3_1w.valuesChangedChip1 <= (others=>'0'); -- autoreset
			dac088s085_x3_1w.valuesChangedChip2 <= (others=>'0'); -- autoreset
			gpsTiming_0w.newDataLatchedReset <= '0'; -- autoreset
			pixelRateCounter_0w.newDataLatchedReset <= '0'; -- autoreset 
			pixelRateCounter_0w.resetAllCounter <= '0'; -- autoreset 
			pixelRateCounter_0w.resetCounterTime <= '0'; -- autoreset 
			if (controlBus.reset = '1') then
				registerA <= (others => '0');
				registerB <= (others => '0');
				triggerDataDelay_0w.numberOfDelayCycles <= x"0004";
				triggerDataDelay_0w.resetDelay <= '1';
				ad56x1_0w.valueChip0 <= x"800";
				ad56x1_0w.valueChip1 <= x"800";
				--ad56x1_0w.init <= '1';
				ad56x1_0w.valueChangedChip0 <= '1'; -- autoreset
				ad56x1_0w.valueChangedChip1 <= '1'; -- autoreset
				eventFifoSystem_0w.packetConfig <= x"000f";
				eventFifoSystem_0w.numberOfSamplesToRead <= x"0001"; -- ## not used....
				eventFifoSystem_0w.eventsPerIrq <= x"0001";
				eventFifoSystem_0w.irqAtEventFifoWords <= x"0100";
				eventFifoSystem_0w.enableIrq <= '0';
				eventFifoSystem_0w.irqStall <= '0';
				triggerTimeToEdge_0w.maxSearchTime <= x"010";
				triggerLogic_0w.mode <= x"2";
				pixelRateCounter_0w.counterPeriod <= x"0001"; -- 1 == 1sec
				triggerLogic_0w.counterPeriod <= x"0001";
				gpsTiming_0w.counterPeriod <= x"0001";
				gpsTiming_0w.fakePpsEnabled <= '0';
				readDataBuffer <= x"6666";
				--readDataBuffer <= std_logic_vector(unsigned(readDataBuffer) + 1);
			else
				if ((controlBus.writeStrobe = '1') and (controlBus.readStrobe = '0') and (chipSelectInternal = '1')) then
					case (controlBus.address(15 downto 0) and not(subAddressMask)) is
						-- address 0x0000-0x0fff has to be the same for all taxi based systems
						-- address 0x1000-0x1fff is used for icescint
						-- address 0x2000-0x2fff is used for polarstern
						-- address 0x3000-0x3fff is used for taxi classic (24ch. version)
						when x"0000" => registerA <= dataBusIn(7 downto 0);
						when x"0002" => registerB <= dataBusIn;
						
						when x"0102" => eventFifoClear <= '1'; -- autoreset
						when x"0108" => eventFifoSystem_0w.irqStall <= dataBusIn(0);
						
						when x"0200" => gpsTiming_0w.counterPeriod <= dataBusIn; 
						when x"0202" => gpsTiming_0w.newDataLatchedReset <= '1'; -- autoreset
						when x"0214" => gpsTiming_0w.fakePpsEnabled <= '1';
						
						when x"0310" => ad56x1_0w.valueChip0 <= dataBusIn(11 downto 0); ad56x1_0w.valueChangedChip0 <= '1'; -- autoreset
						when x"0312" => ad56x1_0w.valueChip1 <= dataBusIn(11 downto 0); ad56x1_0w.valueChangedChip1 <= '1'; -- autoreset
						when x"0314" => ad56x1_0w.valueChangedChip0 <= dataBusIn(0); ad56x1_0w.valueChangedChip1 <= dataBusIn(1); -- autoreset
					
						when x"0400" => dac088s085_x3_0w.init <= '1'; -- autoreset
						when x"0402" => dac088s085_x3_0w.valuesChangedChip0 <= dataBusIn(7 downto 0);
						when x"0404" => dac088s085_x3_0w.valuesChangedChip1 <= dataBusIn(7 downto 0);
						when x"0406" => dac088s085_x3_0w.valuesChangedChip2 <= dataBusIn(7 downto 0);
						when x"0410" => dac088s085_x3_0w.valuesChip0(0) <= dataBusIn(7 downto 0); dac088s085_x3_0w.valuesChangedChip0(0) <= '1'; -- autoreset
						when x"0412" => dac088s085_x3_0w.valuesChip0(1) <= dataBusIn(7 downto 0); dac088s085_x3_0w.valuesChangedChip0(1) <= '1'; -- autoreset
						when x"0414" => dac088s085_x3_0w.valuesChip0(2) <= dataBusIn(7 downto 0); dac088s085_x3_0w.valuesChangedChip0(2) <= '1'; -- autoreset
						when x"0416" => dac088s085_x3_0w.valuesChip0(3) <= dataBusIn(7 downto 0); dac088s085_x3_0w.valuesChangedChip0(3) <= '1'; -- autoreset
						when x"0418" => dac088s085_x3_0w.valuesChip0(4) <= dataBusIn(7 downto 0); dac088s085_x3_0w.valuesChangedChip0(4) <= '1'; -- autoreset
						when x"041a" => dac088s085_x3_0w.valuesChip0(5) <= dataBusIn(7 downto 0); dac088s085_x3_0w.valuesChangedChip0(5) <= '1'; -- autoreset
						when x"041c" => dac088s085_x3_0w.valuesChip0(6) <= dataBusIn(7 downto 0); dac088s085_x3_0w.valuesChangedChip0(6) <= '1'; -- autoreset
						when x"041e" => dac088s085_x3_0w.valuesChip0(7) <= dataBusIn(7 downto 0); dac088s085_x3_0w.valuesChangedChip0(7) <= '1'; -- autoreset
						when x"0420" => dac088s085_x3_0w.valuesChip1(0) <= dataBusIn(7 downto 0); dac088s085_x3_0w.valuesChangedChip1(0) <= '1'; -- autoreset
						when x"0422" => dac088s085_x3_0w.valuesChip1(1) <= dataBusIn(7 downto 0); dac088s085_x3_0w.valuesChangedChip1(1) <= '1'; -- autoreset
						when x"0424" => dac088s085_x3_0w.valuesChip1(2) <= dataBusIn(7 downto 0); dac088s085_x3_0w.valuesChangedChip1(2) <= '1'; -- autoreset
						when x"0426" => dac088s085_x3_0w.valuesChip1(3) <= dataBusIn(7 downto 0); dac088s085_x3_0w.valuesChangedChip1(3) <= '1'; -- autoreset
						when x"0428" => dac088s085_x3_0w.valuesChip1(4) <= dataBusIn(7 downto 0); dac088s085_x3_0w.valuesChangedChip1(4) <= '1'; -- autoreset
						when x"042a" => dac088s085_x3_0w.valuesChip1(5) <= dataBusIn(7 downto 0); dac088s085_x3_0w.valuesChangedChip1(5) <= '1'; -- autoreset
						when x"042c" => dac088s085_x3_0w.valuesChip1(6) <= dataBusIn(7 downto 0); dac088s085_x3_0w.valuesChangedChip1(6) <= '1'; -- autoreset
						when x"042e" => dac088s085_x3_0w.valuesChip1(7) <= dataBusIn(7 downto 0); dac088s085_x3_0w.valuesChangedChip1(7) <= '1'; -- autoreset
						when x"0430" => dac088s085_x3_0w.valuesChip2(0) <= dataBusIn(7 downto 0); dac088s085_x3_0w.valuesChangedChip2(0) <= '1'; -- autoreset
						when x"0432" => dac088s085_x3_0w.valuesChip2(1) <= dataBusIn(7 downto 0); dac088s085_x3_0w.valuesChangedChip2(1) <= '1'; -- autoreset
						when x"0434" => dac088s085_x3_0w.valuesChip2(2) <= dataBusIn(7 downto 0); dac088s085_x3_0w.valuesChangedChip2(2) <= '1'; -- autoreset
						when x"0436" => dac088s085_x3_0w.valuesChip2(3) <= dataBusIn(7 downto 0); dac088s085_x3_0w.valuesChangedChip2(3) <= '1'; -- autoreset
						when x"0438" => dac088s085_x3_0w.valuesChip2(4) <= dataBusIn(7 downto 0); dac088s085_x3_0w.valuesChangedChip2(4) <= '1'; -- autoreset
						when x"043a" => dac088s085_x3_0w.valuesChip2(5) <= dataBusIn(7 downto 0); dac088s085_x3_0w.valuesChangedChip2(5) <= '1'; -- autoreset
						when x"043c" => dac088s085_x3_0w.valuesChip2(6) <= dataBusIn(7 downto 0); dac088s085_x3_0w.valuesChangedChip2(6) <= '1'; -- autoreset
						when x"043e" => dac088s085_x3_0w.valuesChip2(7) <= dataBusIn(7 downto 0); dac088s085_x3_0w.valuesChangedChip2(7) <= '1'; -- autoreset

						when x"0440" => dac088s085_x3_1w.init <= '1'; -- autoreset
						when x"0442" => dac088s085_x3_1w.valuesChangedChip0 <= dataBusIn(7 downto 0);
						when x"0444" => dac088s085_x3_1w.valuesChangedChip1 <= dataBusIn(7 downto 0);
						when x"0446" => dac088s085_x3_1w.valuesChangedChip2 <= dataBusIn(7 downto 0);
						when x"0450" => dac088s085_x3_1w.valuesChip0(0) <= dataBusIn(7 downto 0); dac088s085_x3_1w.valuesChangedChip0(0) <= '1'; -- autoreset
						when x"0452" => dac088s085_x3_1w.valuesChip0(1) <= dataBusIn(7 downto 0); dac088s085_x3_1w.valuesChangedChip0(1) <= '1'; -- autoreset
						when x"0454" => dac088s085_x3_1w.valuesChip0(2) <= dataBusIn(7 downto 0); dac088s085_x3_1w.valuesChangedChip0(2) <= '1'; -- autoreset
						when x"0456" => dac088s085_x3_1w.valuesChip0(3) <= dataBusIn(7 downto 0); dac088s085_x3_1w.valuesChangedChip0(3) <= '1'; -- autoreset
						when x"0458" => dac088s085_x3_1w.valuesChip0(4) <= dataBusIn(7 downto 0); dac088s085_x3_1w.valuesChangedChip0(4) <= '1'; -- autoreset
						when x"045a" => dac088s085_x3_1w.valuesChip0(5) <= dataBusIn(7 downto 0); dac088s085_x3_1w.valuesChangedChip0(5) <= '1'; -- autoreset
						when x"045c" => dac088s085_x3_1w.valuesChip0(6) <= dataBusIn(7 downto 0); dac088s085_x3_1w.valuesChangedChip0(6) <= '1'; -- autoreset
						when x"045e" => dac088s085_x3_1w.valuesChip0(7) <= dataBusIn(7 downto 0); dac088s085_x3_1w.valuesChangedChip0(7) <= '1'; -- autoreset
						when x"0460" => dac088s085_x3_1w.valuesChip1(0) <= dataBusIn(7 downto 0); dac088s085_x3_1w.valuesChangedChip1(0) <= '1'; -- autoreset
						when x"0462" => dac088s085_x3_1w.valuesChip1(1) <= dataBusIn(7 downto 0); dac088s085_x3_1w.valuesChangedChip1(1) <= '1'; -- autoreset
						when x"0464" => dac088s085_x3_1w.valuesChip1(2) <= dataBusIn(7 downto 0); dac088s085_x3_1w.valuesChangedChip1(2) <= '1'; -- autoreset
						when x"0466" => dac088s085_x3_1w.valuesChip1(3) <= dataBusIn(7 downto 0); dac088s085_x3_1w.valuesChangedChip1(3) <= '1'; -- autoreset
						when x"0468" => dac088s085_x3_1w.valuesChip1(4) <= dataBusIn(7 downto 0); dac088s085_x3_1w.valuesChangedChip1(4) <= '1'; -- autoreset
						when x"046a" => dac088s085_x3_1w.valuesChip1(5) <= dataBusIn(7 downto 0); dac088s085_x3_1w.valuesChangedChip1(5) <= '1'; -- autoreset
						when x"046c" => dac088s085_x3_1w.valuesChip1(6) <= dataBusIn(7 downto 0); dac088s085_x3_1w.valuesChangedChip1(6) <= '1'; -- autoreset
						when x"046e" => dac088s085_x3_1w.valuesChip1(7) <= dataBusIn(7 downto 0); dac088s085_x3_1w.valuesChangedChip1(7) <= '1'; -- autoreset
						when x"0470" => dac088s085_x3_1w.valuesChip2(0) <= dataBusIn(7 downto 0); dac088s085_x3_1w.valuesChangedChip2(0) <= '1'; -- autoreset
						when x"0472" => dac088s085_x3_1w.valuesChip2(1) <= dataBusIn(7 downto 0); dac088s085_x3_1w.valuesChangedChip2(1) <= '1'; -- autoreset
						when x"0474" => dac088s085_x3_1w.valuesChip2(2) <= dataBusIn(7 downto 0); dac088s085_x3_1w.valuesChangedChip2(2) <= '1'; -- autoreset
						when x"0476" => dac088s085_x3_1w.valuesChip2(3) <= dataBusIn(7 downto 0); dac088s085_x3_1w.valuesChangedChip2(3) <= '1'; -- autoreset
						when x"0478" => dac088s085_x3_1w.valuesChip2(4) <= dataBusIn(7 downto 0); dac088s085_x3_1w.valuesChangedChip2(4) <= '1'; -- autoreset
						when x"047a" => dac088s085_x3_1w.valuesChip2(5) <= dataBusIn(7 downto 0); dac088s085_x3_1w.valuesChangedChip2(5) <= '1'; -- autoreset
						when x"047c" => dac088s085_x3_1w.valuesChip2(6) <= dataBusIn(7 downto 0); dac088s085_x3_1w.valuesChangedChip2(6) <= '1'; -- autoreset
						when x"047e" => dac088s085_x3_1w.valuesChip2(7) <= dataBusIn(7 downto 0); dac088s085_x3_1w.valuesChangedChip2(7) <= '1'; -- autoreset

						when x"2100" => eventFifoSystem_0w.packetConfig <= dataBusIn;
						when x"2102" => eventFifoSystem_0w.eventsPerIrq <= dataBusIn;
						when x"2104" => eventFifoSystem_0w.irqAtEventFifoWords <= dataBusIn;
						when x"2106" => eventFifoSystem_0w.enableIrq <= dataBusIn(0);
						when x"2108" => eventFifoSystem_0w.forceIrq <= dataBusIn(0); -- autoreset
						when x"210a" => eventFifoSystem_0w.clearEventCounter <= dataBusIn(0); -- autoreset
											
						when x"211c" => debugReset <= '1'; -- autoreset
						
						when x"2200" => triggerLogic_0w.mode <= dataBusIn(3 downto 0);
						when x"2240" => triggerDataDelay_0w.numberOfDelayCycles <= dataBusIn; triggerDataDelay_0w.resetDelay <= '1'; -- autoreset

						when x"2380" => pixelRateCounter_0w.counterPeriod <= dataBusIn; 
										triggerLogic_0w.counterPeriod <= dataBusIn;
						when x"2382" => pixelRateCounter_0w.resetCounter <= dataBusIn; -- autoreset
						when x"2384" =>	triggerLogic_0w.resetCounter <= dataBusIn; -- autoreset
						when x"2386" => pixelRateCounter_0w.newDataLatchedReset <= '1'; -- autoreset 
						when x"2388" => pixelRateCounter_0w.resetAllCounter <= dataBusIn(0); -- autoreset 
							pixelRateCounter_0w.resetCounterTime <= dataBusIn(1); -- autoreset
							triggerLogic_0w.resetAllCounter <= dataBusIn(0); -- autoreset 
							triggerLogic_0w.resetCounterTime <= dataBusIn(1);
						
						
						when others => null;
					end case;
				elsif ((controlBus.readStrobe = '1') and (controlBus.writeStrobe = '0') and (chipSelectInternal = '1')) then	
					case (controlBus.address(15 downto 0) and not(subAddressMask)) is
						when x"0000" => readDataBuffer <= x"00" & registerA;
						when x"0002" => readDataBuffer <= registerB;
						when x"0004" => readDataBuffer <= x"1234";
						
						when x"0100" => readDataBuffer <= eventFifoSystem_0r.dmaBuffer; eventFifoSystem_0w.nextWord <= '1'; -- autoreset
						--when x"0102" => eventFifoSystem_0w.reset;
						when x"0104" => readDataBuffer <= eventFifoSystem_0r.eventFifoWordsDmaAligned;
						when x"0106" => readDataBuffer <= eventFifoSystem_0r.eventFifoWordsPerSlice;
						when x"0108" => readDataBuffer <= x"000" & "000" & eventFifoSystem_0r.irqStall;
						
						when x"0200" => readDataBuffer <= gpsTiming_0r.counterPeriod;
						when x"0202" => readDataBuffer <= x"000" & "000" & gpsTiming_0r.newDataLatched;
						when x"0204" => readDataBuffer <= gpsTiming_0r.differenceGpsToLocalClock;
						when x"0206" => readDataBuffer <= gpsTiming_0r.week;
						when x"0208" => readDataBuffer <= gpsTiming_0r.quantizationError(31 downto 16);
						when x"020a" => readDataBuffer <= gpsTiming_0r.quantizationError(15 downto 0);
						when x"020c" => readDataBuffer <= gpsTiming_0r.timeOfWeekMilliSecond(31 downto 16);
						when x"020e" => readDataBuffer <= gpsTiming_0r.timeOfWeekMilliSecond(15 downto 0);
						--when x"0210" => readDataBuffer <= gpsTiming_0r.timeOfWeekSubMilliSecond(31 downto 16);
						--when x"0212" => readDataBuffer <= gpsTiming_0r.timeOfWeekSubMilliSecond(15 downto 0);
						when x"0214" => readDataBuffer <= x"000" & "000" & gpsTiming_0r.fakePpsEnabled;
					
					--	when x"0300" => readDataBuffer <=  x"000" & "000" & tmp05_0r.busy; 
					--	when x"0302" => readDataBuffer <= tmp05_0r.tl; tmp05_0r_thLatched <= tmp05_0r.th; 
					--	when x"0304" => readDataBuffer <= tmp05_0r_thLatched;
					--	when x"0306" => readDataBuffer <= tmp05_0r.debugCounter(15 downto 0);
					--	when x"0308" => readDataBuffer <= x"00" & tmp05_0r.debugCounter(23 downto 16);

						when x"0310" => readDataBuffer <= x"0" & ad56x1_0r.valueChip0;
						when x"0312" => readDataBuffer <= x"0" & ad56x1_0r.valueChip1;
						when x"0314" => readDataBuffer <= x"000" & "000" & ad56x1_0r.dacBusy;
						
						when x"0402" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChangedChip0;
						when x"0404" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChangedChip1;
						when x"0406" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChangedChip2;
						when x"0408" => readDataBuffer <= x"000" & "000" & dac088s085_x3_0r.dacBusy;
						when x"0410" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip0(0);
						when x"0412" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip0(1);
						when x"0414" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip0(2);
						when x"0416" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip0(3);
						when x"0418" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip0(4);
						when x"041a" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip0(5);
						when x"041c" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip0(6);
						when x"041e" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip0(7);
						when x"0420" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip1(0);
						when x"0422" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip1(1);
						when x"0424" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip1(2);
						when x"0426" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip1(3);
						when x"0428" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip1(4);
						when x"042a" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip1(5);
						when x"042c" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip1(6);
						when x"042e" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip1(7);
						when x"0430" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip2(0);
						when x"0432" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip2(1);
						when x"0434" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip2(2);
						when x"0436" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip2(3);
						when x"0438" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip2(4);
						when x"043a" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip2(5);
						when x"043c" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip2(6);
						when x"043e" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip2(7);

						when x"0442" => readDataBuffer <= x"00" & dac088s085_x3_1r.valuesChangedChip0;
						when x"0444" => readDataBuffer <= x"00" & dac088s085_x3_1r.valuesChangedChip1;
						when x"0446" => readDataBuffer <= x"00" & dac088s085_x3_1r.valuesChangedChip2;
						when x"0448" => readDataBuffer <= x"000" & "000" & dac088s085_x3_1r.dacBusy;
						when x"0450" => readDataBuffer <= x"00" & dac088s085_x3_1r.valuesChip0(0);
						when x"0452" => readDataBuffer <= x"00" & dac088s085_x3_1r.valuesChip0(1);
						when x"0454" => readDataBuffer <= x"00" & dac088s085_x3_1r.valuesChip0(2);
						when x"0456" => readDataBuffer <= x"00" & dac088s085_x3_1r.valuesChip0(3);
						when x"0458" => readDataBuffer <= x"00" & dac088s085_x3_1r.valuesChip0(4);
						when x"045a" => readDataBuffer <= x"00" & dac088s085_x3_1r.valuesChip0(5);
						when x"045c" => readDataBuffer <= x"00" & dac088s085_x3_1r.valuesChip0(6);
						when x"045e" => readDataBuffer <= x"00" & dac088s085_x3_1r.valuesChip0(7);
						when x"0460" => readDataBuffer <= x"00" & dac088s085_x3_1r.valuesChip1(0);
						when x"0462" => readDataBuffer <= x"00" & dac088s085_x3_1r.valuesChip1(1);
						when x"0464" => readDataBuffer <= x"00" & dac088s085_x3_1r.valuesChip1(2);
						when x"0466" => readDataBuffer <= x"00" & dac088s085_x3_1r.valuesChip1(3);
						when x"0468" => readDataBuffer <= x"00" & dac088s085_x3_1r.valuesChip1(4);
						when x"046a" => readDataBuffer <= x"00" & dac088s085_x3_1r.valuesChip1(5);
						when x"046c" => readDataBuffer <= x"00" & dac088s085_x3_1r.valuesChip1(6);
						when x"046e" => readDataBuffer <= x"00" & dac088s085_x3_1r.valuesChip1(7);
						when x"0470" => readDataBuffer <= x"00" & dac088s085_x3_1r.valuesChip2(0);
						when x"0472" => readDataBuffer <= x"00" & dac088s085_x3_1r.valuesChip2(1);
						when x"0474" => readDataBuffer <= x"00" & dac088s085_x3_1r.valuesChip2(2);
						when x"0476" => readDataBuffer <= x"00" & dac088s085_x3_1r.valuesChip2(3);
						when x"0478" => readDataBuffer <= x"00" & dac088s085_x3_1r.valuesChip2(4);
						when x"047a" => readDataBuffer <= x"00" & dac088s085_x3_1r.valuesChip2(5);
						when x"047c" => readDataBuffer <= x"00" & dac088s085_x3_1r.valuesChip2(6);
						when x"047e" => readDataBuffer <= x"00" & dac088s085_x3_1r.valuesChip2(7);

						when x"2100" => readDataBuffer <= eventFifoSystem_0r.packetConfig;
						when x"2102" => readDataBuffer <= eventFifoSystem_0r.eventsPerIrq;
						when x"2104" => readDataBuffer <= eventFifoSystem_0r.irqAtEventFifoWords;
						when x"2106" => readDataBuffer <= x"000" & "000" & eventFifoSystem_0r.enableIrq;

						when x"2110" => readDataBuffer <= eventFifoSystem_0r.eventRateCounter;
						when x"2112" => readDataBuffer <= eventFifoSystem_0r.eventLostRateCounter;
						when x"2114" => readDataBuffer <= eventFifoSystem_0r.eventFifoErrorCounter;
						when x"2116" => readDataBuffer <= eventFifoSystem_0r.eventFifoFullCounter;
						when x"2118" => readDataBuffer <= eventFifoSystem_0r.eventFifoOverflowCounter;
						when x"211a" => readDataBuffer <= eventFifoSystem_0r.eventFifoUnderflowCounter;
						when x"211c" => readDataBuffer <= eventFifoSystem_0r.eventFifoWords;
						when x"211e" => readDataBuffer <= eventFifoSystem_0r.eventFifoFlags;						
						
						when x"2200" => readDataBuffer <= x"000" & triggerLogic_0r.mode;
						when x"2202" => readDataBuffer <= triggerLogic_0r.rateCounterLatched(0);
						when x"2204" => readDataBuffer <= triggerLogic_0r.rateCounterLatched(1);
						when x"2206" => readDataBuffer <= triggerLogic_0r.rateCounterLatched(2);
						
						when x"2240" => readDataBuffer <= triggerDataDelay_0r.numberOfDelayCycles;

						when x"2300" => readDataBuffer <= triggerTimeToEdge_0r.timeToRisingEdge(0);
						when x"2302" => readDataBuffer <= triggerTimeToEdge_0r.timeToRisingEdge(1);
						when x"2304" => readDataBuffer <= triggerTimeToEdge_0r.timeToRisingEdge(2);
						when x"2306" => readDataBuffer <= triggerTimeToEdge_0r.timeToRisingEdge(3);
						when x"2308" => readDataBuffer <= triggerTimeToEdge_0r.timeToRisingEdge(4);
						when x"230a" => readDataBuffer <= triggerTimeToEdge_0r.timeToRisingEdge(5);
						when x"230c" => readDataBuffer <= triggerTimeToEdge_0r.timeToRisingEdge(6);
						when x"230e" => readDataBuffer <= triggerTimeToEdge_0r.timeToRisingEdge(7);
						when x"2310" => readDataBuffer <= triggerTimeToEdge_0r.timeToRisingEdge(8);
						when x"2312" => readDataBuffer <= triggerTimeToEdge_0r.timeToRisingEdge(9);
						when x"2314" => readDataBuffer <= triggerTimeToEdge_0r.timeToRisingEdge(10);
						when x"2316" => readDataBuffer <= triggerTimeToEdge_0r.timeToRisingEdge(11);
						when x"2318" => readDataBuffer <= triggerTimeToEdge_0r.timeToRisingEdge(12);
						when x"231a" => readDataBuffer <= triggerTimeToEdge_0r.timeToRisingEdge(13);
						when x"231c" => readDataBuffer <= triggerTimeToEdge_0r.timeToRisingEdge(14);
						when x"231e" => readDataBuffer <= triggerTimeToEdge_0r.timeToRisingEdge(15);
						
						when x"2340" => readDataBuffer <= triggerTimeToEdge_0r.timeToFallingEdge(0);
						when x"2342" => readDataBuffer <= triggerTimeToEdge_0r.timeToFallingEdge(1);
						when x"2344" => readDataBuffer <= triggerTimeToEdge_0r.timeToFallingEdge(2);
						when x"2346" => readDataBuffer <= triggerTimeToEdge_0r.timeToFallingEdge(3);
						when x"2348" => readDataBuffer <= triggerTimeToEdge_0r.timeToFallingEdge(4);
						when x"234a" => readDataBuffer <= triggerTimeToEdge_0r.timeToFallingEdge(5);
						when x"234c" => readDataBuffer <= triggerTimeToEdge_0r.timeToFallingEdge(6);
						when x"234e" => readDataBuffer <= triggerTimeToEdge_0r.timeToFallingEdge(7);
						when x"2350" => readDataBuffer <= triggerTimeToEdge_0r.timeToFallingEdge(8);
						when x"2352" => readDataBuffer <= triggerTimeToEdge_0r.timeToFallingEdge(9);
						when x"2354" => readDataBuffer <= triggerTimeToEdge_0r.timeToFallingEdge(10);
						when x"2356" => readDataBuffer <= triggerTimeToEdge_0r.timeToFallingEdge(11);
						when x"2358" => readDataBuffer <= triggerTimeToEdge_0r.timeToFallingEdge(12);
						when x"235a" => readDataBuffer <= triggerTimeToEdge_0r.timeToFallingEdge(13);
						when x"235c" => readDataBuffer <= triggerTimeToEdge_0r.timeToFallingEdge(14);
						when x"235e" => readDataBuffer <= triggerTimeToEdge_0r.timeToFallingEdge(15);

						when x"2380" => readDataBuffer <= pixelRateCounter_0r.counterPeriod;
						when x"2386" => readDataBuffer <= x"000" & "000" & pixelRateCounter_0r.newDataLatched;
						when x"2390" => readDataBuffer <= pixelRateCounter_0r.pixelCounterAllEdgesLatched(0);
						when x"2392" => readDataBuffer <= pixelRateCounter_0r.pixelCounterAllEdgesLatched(1);
						when x"2394" => readDataBuffer <= pixelRateCounter_0r.pixelCounterAllEdgesLatched(2);
						when x"2396" => readDataBuffer <= pixelRateCounter_0r.pixelCounterAllEdgesLatched(3);
						when x"2398" => readDataBuffer <= pixelRateCounter_0r.pixelCounterAllEdgesLatched(4);
						when x"239a" => readDataBuffer <= pixelRateCounter_0r.pixelCounterAllEdgesLatched(5);
						when x"239c" => readDataBuffer <= pixelRateCounter_0r.pixelCounterAllEdgesLatched(6);
						when x"239e" => readDataBuffer <= pixelRateCounter_0r.pixelCounterAllEdgesLatched(7);
						when x"23a0" => readDataBuffer <= pixelRateCounter_0r.pixelCounterAllEdgesLatched(8);
						when x"23a2" => readDataBuffer <= pixelRateCounter_0r.pixelCounterAllEdgesLatched(9);
						when x"23a4" => readDataBuffer <= pixelRateCounter_0r.pixelCounterAllEdgesLatched(10);
						when x"23a6" => readDataBuffer <= pixelRateCounter_0r.pixelCounterAllEdgesLatched(11);
						when x"23a8" => readDataBuffer <= pixelRateCounter_0r.pixelCounterAllEdgesLatched(12);
						when x"23aa" => readDataBuffer <= pixelRateCounter_0r.pixelCounterAllEdgesLatched(13);
						when x"23ac" => readDataBuffer <= pixelRateCounter_0r.pixelCounterAllEdgesLatched(14);
						when x"23ae" => readDataBuffer <= pixelRateCounter_0r.pixelCounterAllEdgesLatched(15);
						when x"23b0" => readDataBuffer <= triggerLogic_0r.rateCounterSectorLatched(0);
						when x"23b2" => readDataBuffer <= triggerLogic_0r.rateCounterSectorLatched(1);
						when x"23b4" => readDataBuffer <= triggerLogic_0r.rateCounterSectorLatched(2);
						when x"23b6" => readDataBuffer <= triggerLogic_0r.rateCounterSectorLatched(3);
						when x"23b8" => readDataBuffer <= triggerLogic_0r.rateCounterSectorLatched(4);
						when x"23ba" => readDataBuffer <= triggerLogic_0r.rateCounterSectorLatched(5);
						when x"23bc" => readDataBuffer <= triggerLogic_0r.rateCounterSectorLatched(6);
						when x"23be" => readDataBuffer <= triggerLogic_0r.rateCounterSectorLatched(7);
						
--						when others  => readDataBuffer <= (others => '0');
						when others  => readDataBuffer <= x"dead";
					end case;
				end if;
			end if;
		end if;
	end process P0;
	
	
end generate g0;
end behavior;
