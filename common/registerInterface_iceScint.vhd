----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:05:09 03/01/2017 
-- Design Name: 
-- Module Name:    registerInterface_iceScint - Behavioral 
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

entity registerInterface_iceScint is
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
		
		triggerTimeToRisingEdge_0r : in triggerTimeToRisingEdge_registerRead_t;
		triggerTimeToRisingEdge_0w : out triggerTimeToRisingEdge_registerWrite_t;
		eventFifoSystem_0r : in eventFifoSystem_registerRead_t;
		eventFifoSystem_0w : out eventFifoSystem_registerWrite_t;
		triggerDataDelay_0r : in triggerDataDelay_registerRead_t;
		triggerDataDelay_0w : out triggerDataDelay_registerWrite_t;
		pixelRateCounter_0r : in pixelRateCounter_registerRead_t;
		pixelRateCounter_0w : out pixelRateCounter_registerWrite_t;
		dac088s085_x3_0r : in dac088s085_x3_registerRead_t;
		dac088s085_x3_0w : out dac088s085_x3_registerWrite_t;
		gpsTiming_0r : in gpsTiming_registerRead_t;
		gpsTiming_0w : out gpsTiming_registerWrite_t;
		whiteRabbitTiming_0r : in whiteRabbitTiming_registerRead_t;
		whiteRabbitTiming_0w : out whiteRabbitTiming_registerWrite_t;
		internalTiming_0r : in internalTiming_registerRead_t;
		internalTiming_0w : out internalTiming_registerWrite_t;
		ad56x1_0r : in ad56x1_registerRead_t;
		ad56x1_0w : out ad56x1_registerWrite_t;
		drs4_0r : in drs4_registerRead_t;
		drs4_0w : out drs4_registerWrite_t;
		ltm9007_14_0r : in ltm9007_14_registerRead_t;
		ltm9007_14_0w : out ltm9007_14_registerWrite_t;
		triggerLogic_0r : in triggerLogic_registerRead_t;
		triggerLogic_0w : out triggerLogic_registerWrite_t;
		iceTad_0r : in iceTad_registerRead_t;
		iceTad_0w : out iceTad_registerWrite_t;
		panelPower_0r : in panelPower_registerRead_t;
		panelPower_0w : out panelPower_registerWrite_t;
		clockConfig_debug_0w : out clockConfig_debug_t
	);
end registerInterface_iceScint;

architecture behavior of registerInterface_iceScint is

	signal chipSelectInternal : std_logic := '0';
	signal readDataBuffer : std_logic_vector(15 downto 0) := (others => '0');
	
	signal registerA : std_logic_vector(7 downto 0) := (others => '0');
	signal registerb : std_logic_vector(15 downto 0) := (others => '0');
	
	signal controlBus : smc_bus;
	
	signal debugReset : std_logic := '0';
	signal eventFifoClear : std_logic := '0';
	
	signal valuesChangedChip0Temp : std_logic_vector(7 downto 0) := (others => '0');
	signal valuesChangedChip1Temp : std_logic_vector(7 downto 0) := (others => '0');
	signal valuesChangedChip2Temp : std_logic_vector(7 downto 0) := (others => '0');
	
	signal numberOfSamplesToRead : std_logic_vector(15 downto 0) := (others => '0');
	signal actualOffsetCorrectionRamValue : std_logic_vector(15 downto 0) := (others => '0');

	signal eventFifoWordsDmaSlice_latched : std_logic_vector(3 downto 0) := (others => '0');
	
begin

g0: if moduleEnabled /= 0 generate
	controlBus <= smc_vectorToBus(addressAndControlBus);
	chipSelectInternal <= '1' when ((controlBus.chipSelect = '1') and ((controlBus.address(15 downto 0) and subAddressMask) = subAddress)) else '0';
--	dataBusWrite <= '1' when ((chipSelectInternal = '1') and (controlBus.read = '1')) else '0';
	dataBusOut <= readDataBuffer;	
	
	triggerTimeToRisingEdge_0w.clock <= controlBus.clock;
	triggerTimeToRisingEdge_0w.reset <= controlBus.reset;
	eventFifoSystem_0w.clock <= controlBus.clock;
	eventFifoSystem_0w.reset <= controlBus.reset or debugReset;
	eventFifoSystem_0w.eventFifoClear <= eventFifoClear;
	--eventFifoSystem_0w.tick_ms <= internalTiming_0r.tick_ms;
	triggerDataDelay_0w.clock <= controlBus.clock;
	triggerDataDelay_0w.reset <= controlBus.reset;
	pixelRateCounter_0w.clock <= controlBus.clock;
	pixelRateCounter_0w.reset <= controlBus.reset;
	--pixelRateCounter_0w.tick_ms <= internalTiming_0r.tick_ms;
	dac088s085_x3_0w.clock <= controlBus.clock;
	dac088s085_x3_0w.reset <= controlBus.reset;
	gpsTiming_0w.clock <= controlBus.clock;
	gpsTiming_0w.reset <= controlBus.reset;
	--gpsTiming_0w.tick_ms <= internalTiming_0r.tick_ms;
	whiteRabbitTiming_0w.clock <= controlBus.clock;
	whiteRabbitTiming_0w.reset <= controlBus.reset;
	internalTiming_0w.clock <= controlBus.clock;
	internalTiming_0w.reset <= controlBus.reset;
	ad56x1_0w.clock <= controlBus.clock;
	ad56x1_0w.reset <= controlBus.reset;
	drs4_0w.clock <= controlBus.clock;
	drs4_0w.reset <= controlBus.reset;
	ltm9007_14_0w.clock <= controlBus.clock;
	ltm9007_14_0w.reset <= controlBus.reset;
	triggerLogic_0w.clock <= controlBus.clock;
	triggerLogic_0w.reset <= controlBus.reset;
	iceTad_0w.clock <= controlBus.clock;
	iceTad_0w.reset <= controlBus.reset;
	panelPower_0w.clock <= controlBus.clock;
	panelPower_0w.reset <= controlBus.reset;
	
	
	dac088s085_x3_0w.valuesChangedChip0 <= valuesChangedChip0Temp;
	dac088s085_x3_0w.valuesChangedChip1 <= valuesChangedChip1Temp;
	dac088s085_x3_0w.valuesChangedChip2 <= valuesChangedChip2Temp;
				
	drs4_0w.numberOfSamplesToRead <= numberOfSamplesToRead;
	ltm9007_14_0w.numberOfSamplesToRead <= numberOfSamplesToRead;
	eventFifoSystem_0w.registerSamplesToRead <= numberOfSamplesToRead;
	
	--ltm9007_14_0r.offsetCorrectionRamAddress <= controlBus.address(10 downto 1) when controlBus.address(15 downto 11) = x"1"&"0" else "0000000000";
	--da sollte 'Jemand' mal einen richtigen address decoder fuer den ram bauen.....
	
	P0:process (controlBus.clock)
	begin
		if rising_edge(controlBus.clock) then
			eventFifoSystem_0w.nextWord <= '0'; -- autoreset
			triggerDataDelay_0w.resetDelay <= '0'; -- autoreset
			pixelRateCounter_0w.resetCounter <= (others=>'0'); -- autoreset
			debugReset <= '0'; -- autoreset
			eventFifoClear <= '0'; -- autoreset
			dac088s085_x3_0w.init <= '0'; -- autoreset
			--ad56x1_0w.init <= '0'; -- autoreset
			ad56x1_0w.valueChangedChip0 <= '0'; -- autoreset
			ad56x1_0w.valueChangedChip1 <= '0'; -- autoreset
			--drs4_0w.stoftTrigger <= '0'; -- autoreset
			drs4_0w.resetStates <= '0'; -- autoreset
			ltm9007_14_0w.init <= '0'; --autoreset
			ltm9007_14_0w.bitslipStart <= '0'; --autoreset
			triggerLogic_0w.triggerSerdesDelayInit <= '0'; --autoreset
			triggerLogic_0w.softTrigger <= '0'; --autoreset
			panelPower_0w.init <= '0'; -- autoreset
			ltm9007_14_0w.offsetCorrectionRamWrite <= (others=>'0'); -- autoreset
			eventFifoSystem_0w.forceIrq <= '0'; -- autoreset
			eventFifoSystem_0w.clearEventCounter <= '0'; -- autoreset
			iceTad_0w.rs485TxStart <= (others=>'0'); -- autoreset
			if (controlBus.reset = '1') then
				registerA <= (others => '0');
				registerb <= (others => '0');
				triggerDataDelay_0w.numberOfDelayCycles <= x"0004";
				triggerDataDelay_0w.resetDelay <= '1';
				valuesChangedChip0Temp <= x"ff";
				valuesChangedChip1Temp <= x"ff";
				valuesChangedChip2Temp <= x"ff";
				ad56x1_0w.valueChip0 <= x"800";
				ad56x1_0w.valueChip1 <= x"800";
				--ad56x1_0w.init <= '1';
				ad56x1_0w.valueChangedChip0 <= '1'; -- autoreset
				ad56x1_0w.valueChangedChip1 <= '1'; -- autoreset
				eventFifoSystem_0w.packetConfig <= x"0006";
				eventFifoSystem_0w.eventsPerIrq <= x"0001";
				eventFifoSystem_0w.irqAtEventFifoWords <= x"0100";
				eventFifoSystem_0w.enableIrq <= '0';
				eventFifoSystem_0w.irqStall <= '0';
				numberOfSamplesToRead <= x"0020";
				drs4_0w.sampleMode <= x"1";
				drs4_0w.readoutMode <= x"5"; 
				ltm9007_14_0w.testMode <= x"0";
				ltm9007_14_0w.init <= '1'; --autoreset
				triggerLogic_0w.triggerMask <= x"ff"; -- ## debug
				triggerLogic_0w.triggerSerdesDelayInit <= '1'; --autoreset
				triggerLogic_0w.triggerSerdesDelay <= "00" & x"68";
				triggerLogic_0w.triggerSerdesDelayInit <= '1'; --autoreset
				triggerLogic_0w.triggerSerdesDelayInit <= '1'; --autoreset
				triggerLogic_0w.triggerGeneratorPeriod <= x"00c00000"; -- 0xc0000 ~ 10Hz
				--notOnPaddle <= (others=>'0');
				panelPower_0w.enable <= '0';
				dac088s085_x3_0w.valuesChip0 <= (others=>x"30");
				dac088s085_x3_0w.valuesChip1 <= (others=>x"00");
				dac088s085_x3_0w.valuesChip2 <= (others=>x"00");
				--dac088s085_x3_0w.valuesChip1(0) <= x"80";
				--dac088s085_x3_0w.valuesChip1(2) <= x"80";
				--dac088s085_x3_0w.valuesChip1(4) <= x"80";
				--dac088s085_x3_0w.valuesChip1(6) <= x"80";
				--dac088s085_x3_0w.valuesChip2(0) <= x"80";
				--dac088s085_x3_0w.valuesChip2(2) <= x"80";
				--dac088s085_x3_0w.valuesChip2(4) <= x"80";
				--dac088s085_x3_0w.valuesChip2(6) <= x"80";
				clockConfig_debug_0w.drs4RefClockPeriod <= x"7f";
				eventFifoWordsDmaSlice_latched <= (others=>'0');
				pixelRateCounter_0w.counterPeriod <= x"0001"; -- 1 sec
			else
				valuesChangedChip0Temp <= valuesChangedChip0Temp and not(dac088s085_x3_0r.valuesChangedChip0Reset); -- ## move to module.....
				valuesChangedChip1Temp <= valuesChangedChip1Temp and not(dac088s085_x3_0r.valuesChangedChip1Reset);
				valuesChangedChip2Temp <= valuesChangedChip2Temp and not(dac088s085_x3_0r.valuesChangedChip2Reset);

				if ((controlBus.writeStrobe = '1') and (controlBus.readStrobe = '0') and (chipSelectInternal = '1')) then
					case (controlBus.address(15 downto 0) and not(subAddressMask)) is
						when x"0000" => registerA <= dataBusIn(7 downto 0);
						when x"0002" => registerB <= dataBusIn;
						
						when x"0100" => eventFifoSystem_0w.packetConfig <= dataBusIn;
						when x"0102" => eventFifoSystem_0w.eventsPerIrq <= dataBusIn;
						when x"0104" => eventFifoSystem_0w.irqAtEventFifoWords <= dataBusIn;
						when x"0106" => eventFifoSystem_0w.enableIrq <= dataBusIn(0);
						when x"0108" => eventFifoSystem_0w.forceIrq <= dataBusIn(0); -- autoreset
						when x"010a" => eventFifoSystem_0w.clearEventCounter <= dataBusIn(0); -- autoreset
						when x"010c" => eventFifoSystem_0w.irqStall <= dataBusIn(0);

						when x"000a" => clockConfig_debug_0w.drs4RefClockPeriod <= dataBusIn(7 downto 0);
											
						when x"0022" => eventFifoClear <= '1'; -- autoreset
						
						when x"012c" => debugReset <= '1'; -- autoreset
						when x"012e" => triggerDataDelay_0w.numberOfDelayCycles <= dataBusIn; triggerDataDelay_0w.resetDelay <= '1'; -- autoreset
						when x"0040" => pixelRateCounter_0w.resetCounter <= dataBusIn; -- autoreset
						when x"0042" => pixelRateCounter_0w.counterPeriod <= dataBusIn; -- autoreset
						
						when x"0048" => dac088s085_x3_0w.init <= '1'; -- autoreset
						when x"004a" => valuesChangedChip0Temp <= dataBusIn(7 downto 0);
						when x"004c" => valuesChangedChip1Temp <= dataBusIn(7 downto 0);
						when x"004e" => valuesChangedChip2Temp <= dataBusIn(7 downto 0);
						when x"0050" => dac088s085_x3_0w.valuesChip0(0) <= dataBusIn(7 downto 0); valuesChangedChip0Temp(0) <= '1';
						when x"0052" => dac088s085_x3_0w.valuesChip0(1) <= dataBusIn(7 downto 0); valuesChangedChip0Temp(1) <= '1';
						when x"0054" => dac088s085_x3_0w.valuesChip0(2) <= dataBusIn(7 downto 0); valuesChangedChip0Temp(2) <= '1';
						when x"0056" => dac088s085_x3_0w.valuesChip0(3) <= dataBusIn(7 downto 0); valuesChangedChip0Temp(3) <= '1';
						when x"0058" => dac088s085_x3_0w.valuesChip0(4) <= dataBusIn(7 downto 0); valuesChangedChip0Temp(4) <= '1';
						when x"005a" => dac088s085_x3_0w.valuesChip0(5) <= dataBusIn(7 downto 0); valuesChangedChip0Temp(5) <= '1';
						when x"005c" => dac088s085_x3_0w.valuesChip0(6) <= dataBusIn(7 downto 0); valuesChangedChip0Temp(6) <= '1';
						when x"005e" => dac088s085_x3_0w.valuesChip0(7) <= dataBusIn(7 downto 0); valuesChangedChip0Temp(7) <= '1';
						when x"0060" => dac088s085_x3_0w.valuesChip1(0) <= dataBusIn(7 downto 0); valuesChangedChip1Temp(0) <= '1';
						when x"0062" => dac088s085_x3_0w.valuesChip1(1) <= dataBusIn(7 downto 0); valuesChangedChip1Temp(1) <= '1';
						when x"0064" => dac088s085_x3_0w.valuesChip1(2) <= dataBusIn(7 downto 0); valuesChangedChip1Temp(2) <= '1';
						when x"0066" => dac088s085_x3_0w.valuesChip1(3) <= dataBusIn(7 downto 0); valuesChangedChip1Temp(3) <= '1';
						when x"0068" => dac088s085_x3_0w.valuesChip1(4) <= dataBusIn(7 downto 0); valuesChangedChip1Temp(4) <= '1';
						when x"006a" => dac088s085_x3_0w.valuesChip1(5) <= dataBusIn(7 downto 0); valuesChangedChip1Temp(5) <= '1';
						when x"006c" => dac088s085_x3_0w.valuesChip1(6) <= dataBusIn(7 downto 0); valuesChangedChip1Temp(6) <= '1';
						when x"006e" => dac088s085_x3_0w.valuesChip1(7) <= dataBusIn(7 downto 0); valuesChangedChip1Temp(7) <= '1';
						when x"0070" => dac088s085_x3_0w.valuesChip2(0) <= dataBusIn(7 downto 0); valuesChangedChip2Temp(0) <= '1';
						when x"0072" => dac088s085_x3_0w.valuesChip2(1) <= dataBusIn(7 downto 0); valuesChangedChip2Temp(1) <= '1';
						when x"0074" => dac088s085_x3_0w.valuesChip2(2) <= dataBusIn(7 downto 0); valuesChangedChip2Temp(2) <= '1';
						when x"0076" => dac088s085_x3_0w.valuesChip2(3) <= dataBusIn(7 downto 0); valuesChangedChip2Temp(3) <= '1';
						when x"0078" => dac088s085_x3_0w.valuesChip2(4) <= dataBusIn(7 downto 0); valuesChangedChip2Temp(4) <= '1';
						when x"007a" => dac088s085_x3_0w.valuesChip2(5) <= dataBusIn(7 downto 0); valuesChangedChip2Temp(5) <= '1';
						when x"007c" => dac088s085_x3_0w.valuesChip2(6) <= dataBusIn(7 downto 0); valuesChangedChip2Temp(6) <= '1';
						when x"007e" => dac088s085_x3_0w.valuesChip2(7) <= dataBusIn(7 downto 0); valuesChangedChip2Temp(7) <= '1';
						
						when x"0090" => ad56x1_0w.valueChip0 <= dataBusIn(11 downto 0); ad56x1_0w.valueChangedChip0 <= '1'; -- autoreset
						when x"0092" => ad56x1_0w.valueChip1 <= dataBusIn(11 downto 0); ad56x1_0w.valueChangedChip1 <= '1'; -- autoreset
						when x"0094" => ad56x1_0w.valueChangedChip0 <= dataBusIn(0); ad56x1_0w.valueChangedChip1 <= dataBusIn(1); -- autoreset
						
						--when x"00a0" => drs4_0w.stoftTrigger <= '1'; -- autoreset
						when x"00a4" => drs4_0w.resetStates <= '1'; -- autoreset
						when x"00a6" => numberOfSamplesToRead <= dataBusIn;
						when x"00a8" => drs4_0w.sampleMode <= dataBusIn(3 downto 0);
						when x"00aa" => drs4_0w.readoutMode <= dataBusIn(3 downto 0);
						
						when x"00b0" => ltm9007_14_0w.testMode <= dataBusIn(3 downto 0);
							ltm9007_14_0w.init <= '1'; -- autoreset
						when x"00b2" => ltm9007_14_0w.testPattern <= dataBusIn(13 downto 0); 
						when x"00b4" => ltm9007_14_0w.bitslipStart <= '1'; -- autoreset 
						when x"00b6" => ltm9007_14_0w.bitslipPattern <= dataBusIn(6 downto 0); 
						
						when x"00d0" => triggerLogic_0w.triggerSerdesDelay <= dataBusIn(9 downto 0);
							triggerLogic_0w.triggerSerdesDelayInit <= '1'; --autoreset
						when x"00d2" => triggerLogic_0w.softTrigger <= '1'; --autoreset
						when x"00d4" => triggerLogic_0w.triggerMask <= dataBusIn(7 downto 0);
						when x"00d6" => triggerLogic_0w.singleSeq <= dataBusIn(0);
						when x"00d8" => triggerLogic_0w.triggerGeneratorEnabled <= dataBusIn(0);
						when x"00da" => triggerLogic_0w.triggerGeneratorPeriod(15 downto 0) <= unsigned(dataBusIn);
						when x"00dc" => triggerLogic_0w.triggerGeneratorPeriod(31 downto 16) <= unsigned(dataBusIn);
						
						when x"00e0" => ltm9007_14_0w.offsetCorrectionRamWrite <= dataBusIn(7 downto 0); -- autoreset 
						--when x"00e0" => ltm9007_14_0w.offsetCorrectionRamWrite <= dataBusIn(2 downto 0); 
						when x"00e2" => ltm9007_14_0w.offsetCorrectionRamAddress <= dataBusIn(9 downto 0); 
						when x"00e4" => ltm9007_14_0w.offsetCorrectionRamData <= dataBusIn(15 downto 0); 
						when x"00e6" => ltm9007_14_0w.baselineStart <= dataBusIn(9 downto 0); 
						when x"00e8" => ltm9007_14_0w.baselineEnd <= dataBusIn(9 downto 0); 
						
						when x"00f0" => iceTad_0w.powerOn <= dataBusIn(7 downto 0); 
						when x"00f2" => panelPower_0w.init <= '1'; -- autoreset 
						when x"00f4" => panelPower_0w.enable <= dataBusIn(0); 
						when x"0300" => iceTad_0w.rs485Data(0) <= dataBusIn(7 downto 0); 
						when x"0302" => iceTad_0w.rs485Data(1) <= dataBusIn(7 downto 0); 
						when x"0304" => iceTad_0w.rs485Data(2) <= dataBusIn(7 downto 0); 
						when x"0306" => iceTad_0w.rs485Data(3) <= dataBusIn(7 downto 0); 
						when x"0308" => iceTad_0w.rs485Data(4) <= dataBusIn(7 downto 0); 
						when x"030a" => iceTad_0w.rs485Data(5) <= dataBusIn(7 downto 0); 
						when x"030c" => iceTad_0w.rs485Data(6) <= dataBusIn(7 downto 0); 
						when x"030e" => iceTad_0w.rs485Data(7) <= dataBusIn(7 downto 0); 
						when x"0310" => iceTad_0w.rs485TxStart <= dataBusIn(7 downto 0); -- autoreset 
						
						--when x"1000" => ltm9007_14_0w.offsetCorrectionRamData <= dataBusIn(7 downto 0); 
						--when x"1800" => ltm9007_14_0w.offsetCorrectionRamData <= dataBusIn(7 downto 0); 
						
						when others => null;
					end case;
				elsif ((controlBus.readStrobe = '1') and (controlBus.writeStrobe = '0') and (chipSelectInternal = '1')) then	
					case (controlBus.address(15 downto 0) and not(subAddressMask)) is
						when x"0000" => readDataBuffer <= x"00"&registerA;
						when x"0002" => readDataBuffer <= registerB;
						
						when x"000c" => readDataBuffer <= triggerDataDelay_0r.numberOfDelayCycles;
						
						when x"0100" => readDataBuffer <= eventFifoSystem_0r.packetConfig;
						when x"0102" => readDataBuffer <= eventFifoSystem_0r.eventsPerIrq;
						when x"0104" => readDataBuffer <= eventFifoSystem_0r.irqAtEventFifoWords;
						when x"0106" => readDataBuffer <= x"000" & "000" & eventFifoSystem_0r.enableIrq;
						when x"010c" => readDataBuffer <= x"000" & "000" &eventFifoSystem_0r.irqStall;
						when x"010e" => readDataBuffer <= eventFifoSystem_0r.eventFifoErrorCounter;						
						
						when x"0010" => readDataBuffer <= triggerTimeToRisingEdge_0r.channel(0);
						when x"0012" => readDataBuffer <= triggerTimeToRisingEdge_0r.channel(1);
						when x"0014" => readDataBuffer <= triggerTimeToRisingEdge_0r.channel(2);
						when x"0016" => readDataBuffer <= triggerTimeToRisingEdge_0r.channel(3);
						when x"0018" => readDataBuffer <= triggerTimeToRisingEdge_0r.channel(4);
						when x"001a" => readDataBuffer <= triggerTimeToRisingEdge_0r.channel(5);
						when x"001c" => readDataBuffer <= triggerTimeToRisingEdge_0r.channel(6);
						when x"001e" => readDataBuffer <= triggerTimeToRisingEdge_0r.channel(7);
						
						when x"0020" => readDataBuffer <= eventFifoSystem_0r.dmaBuffer; eventFifoSystem_0w.nextWord <= '1'; -- autoreset
						when x"0022" => readDataBuffer <= eventFifoSystem_0r.eventFifoWordsDma32(15 downto 0); -- has to be locked
						when x"0024" => readDataBuffer <= eventFifoSystem_0r.eventFifoWordsDma32(31 downto 16);
						when x"0026" => readDataBuffer <= eventFifoSystem_0r.eventFifoWordsDma;
							eventFifoWordsDmaSlice_latched <= eventFifoSystem_0r.eventFifoWordsDmaSlice;
						when x"0028" => readDataBuffer <= x"900" & eventFifoWordsDmaSlice_latched; -- msb is max. value for the slice
						when x"002a" => readDataBuffer <= eventFifoSystem_0r.eventFifoWordsDmaAligned;
						
						when x"0126" => readDataBuffer <= eventFifoSystem_0r.eventFifoFullCounter;
						when x"0128" => readDataBuffer <= eventFifoSystem_0r.eventFifoOverflowCounter;
						when x"012a" => readDataBuffer <= eventFifoSystem_0r.eventFifoUnderflowCounter;
						when x"012c" => readDataBuffer <= eventFifoSystem_0r.eventFifoWords;
						when x"012e" => readDataBuffer <= eventFifoSystem_0r.eventFifoFlags;						
						
						when x"0030" => readDataBuffer <= pixelRateCounter_0r.channel(0);
						when x"0032" => readDataBuffer <= pixelRateCounter_0r.channel(1);
						when x"0034" => readDataBuffer <= pixelRateCounter_0r.channel(2);
						when x"0036" => readDataBuffer <= pixelRateCounter_0r.channel(3);
						when x"0038" => readDataBuffer <= pixelRateCounter_0r.channel(4);
						when x"003a" => readDataBuffer <= pixelRateCounter_0r.channel(5);
						when x"003c" => readDataBuffer <= pixelRateCounter_0r.channel(6);
						when x"003e" => readDataBuffer <= pixelRateCounter_0r.channel(7);
						
						when x"0042" => readDataBuffer <= pixelRateCounter_0r.counterPeriod;
						
						when x"0048" => readDataBuffer <= x"000" & "000" & dac088s085_x3_0r.dacBusy;
						when x"004a" => readDataBuffer <= x"00" & valuesChangedChip0Temp;
						when x"004c" => readDataBuffer <= x"00" & valuesChangedChip1Temp;
						when x"004e" => readDataBuffer <= x"00" & valuesChangedChip2Temp;
						
						when x"0050" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip0(0);
						when x"0052" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip0(1);
						when x"0054" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip0(2);
						when x"0056" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip0(3);
						when x"0058" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip0(4);
						when x"005a" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip0(5);
						when x"005c" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip0(6);
						when x"005e" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip0(7);
						when x"0060" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip1(0);
						when x"0062" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip1(1);
						when x"0064" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip1(2);
						when x"0066" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip1(3);
						when x"0068" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip1(4);
						when x"006a" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip1(5);
						when x"006c" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip1(6);
						when x"006e" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip1(7);
						when x"0070" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip2(0);
						when x"0072" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip2(1);
						when x"0074" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip2(2);
						when x"0076" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip2(3);
						when x"0078" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip2(4);
						when x"007a" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip2(5);
						when x"007c" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip2(6);
						when x"007e" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip2(7);
						
						when x"0080" => readDataBuffer <= gpsTiming_0r.week;
						when x"0082" => readDataBuffer <= gpsTiming_0r.quantizationError(31 downto 16);
						when x"0084" => readDataBuffer <= gpsTiming_0r.quantizationError(15 downto 0);
						when x"0086" => readDataBuffer <= gpsTiming_0r.timeOfWeekMilliSecond(31 downto 16);
						when x"0088" => readDataBuffer <= gpsTiming_0r.timeOfWeekMilliSecond(15 downto 0);
						when x"008a" => readDataBuffer <= gpsTiming_0r.timeOfWeekSubMilliSecond(31 downto 16);
						when x"008c" => readDataBuffer <= gpsTiming_0r.timeOfWeekSubMilliSecond(15 downto 0);
						when x"008e" => readDataBuffer <= gpsTiming_0r.differenceGpsToLocalClock;
						
						when x"0090" => readDataBuffer <= x"0" & ad56x1_0r.valueChip0;
						when x"0092" => readDataBuffer <= x"0" & ad56x1_0r.valueChip1;
						when x"0094" => readDataBuffer <= x"000" & "000" & ad56x1_0r.dacBusy;
						
						when x"00a2" => readDataBuffer <= x"0" & "00" & drs4_0r.regionOfInterest;
						when x"00a6" => readDataBuffer <= drs4_0r.numberOfSamplesToRead;
						when x"00a8" => readDataBuffer <= x"000" & drs4_0r.sampleMode;
						when x"00aa" => readDataBuffer <= x"000" & drs4_0r.readoutMode;
						
						when x"00b0" => readDataBuffer <= x"000" & ltm9007_14_0r.testMode;
						when x"00b2" => readDataBuffer <= "00" & ltm9007_14_0r.testPattern;
						when x"00b4" => readDataBuffer <= x"000" & "00" & ltm9007_14_0r.bitslipFailed;
						when x"00b6" => readDataBuffer <= x"00" & "0" & ltm9007_14_0r.bitslipPattern;
						when x"00c0" => readDataBuffer <= "00" & ltm9007_14_0r.fifoA(13+0*14 downto 0+0*14);
						when x"00c2" => readDataBuffer <= "00" & ltm9007_14_0r.fifoA(13+1*14 downto 0+1*14);
						when x"00c4" => readDataBuffer <= "00" & ltm9007_14_0r.fifoA(13+2*14 downto 0+2*14);
						when x"00c6" => readDataBuffer <= "00" & ltm9007_14_0r.fifoA(13+3*14 downto 0+3*14);
						when x"00c8" => readDataBuffer <= "00" & ltm9007_14_0r.fifoB(13+0*14 downto 0+0*14);
						when x"00ca" => readDataBuffer <= "00" & ltm9007_14_0r.fifoB(13+1*14 downto 0+1*14);
						when x"00cc" => readDataBuffer <= "00" & ltm9007_14_0r.fifoB(13+2*14 downto 0+2*14);
						when x"00ce" => readDataBuffer <= "00" & ltm9007_14_0r.fifoB(13+3*14 downto 0+3*14);
						
						when x"00d0" => readDataBuffer <= x"0" & "00" & triggerLogic_0r.triggerSerdesDelay;
						when x"00d4" => readDataBuffer <= x"00" & triggerLogic_0r.triggerMask;
						when x"00d6" => readDataBuffer <= x"000" & "000" &  triggerLogic_0r.singleSeq;
						when x"00d8" => readDataBuffer <= x"000" & "000" &  triggerLogic_0r.triggerGeneratorEnabled;
						when x"00da" => readDataBuffer <= std_logic_vector(triggerLogic_0r.triggerGeneratorPeriod(15 downto 0));
						when x"00dc" => readDataBuffer <= std_logic_vector(triggerLogic_0r.triggerGeneratorPeriod(31 downto 16));
						
						when x"00e0" => readDataBuffer <= x"00" & ltm9007_14_0r.offsetCorrectionRamWrite;
						when x"00e2" => readDataBuffer <= "000000" & ltm9007_14_0r.offsetCorrectionRamAddress;
						--when x"00e4" => readDataBuffer <= x"00" & actualOffsetCorrectionRamValue;
						when x"00e4" => readDataBuffer <= ltm9007_14_0r.offsetCorrectionRamData(0);
						when x"00e6" => readDataBuffer <= "000000" & ltm9007_14_0r.baselineStart;
						when x"00e8" => readDataBuffer <= "000000" & ltm9007_14_0r.baselineEnd;
						
						when x"00f0" => readDataBuffer <= x"00" & iceTad_0r.powerOn;
						when x"0300" => readDataBuffer <= x"00" & iceTad_0r.rs485Data(0);
						when x"0302" => readDataBuffer <= x"00" & iceTad_0r.rs485Data(1);
						when x"0304" => readDataBuffer <= x"00" & iceTad_0r.rs485Data(2);
						when x"0306" => readDataBuffer <= x"00" & iceTad_0r.rs485Data(3);
						when x"0308" => readDataBuffer <= x"00" & iceTad_0r.rs485Data(4);
						when x"030a" => readDataBuffer <= x"00" & iceTad_0r.rs485Data(5);
						when x"030c" => readDataBuffer <= x"00" & iceTad_0r.rs485Data(6);
						when x"030e" => readDataBuffer <= x"00" & iceTad_0r.rs485Data(7);
						when x"0310" => readDataBuffer <= x"00" & iceTad_0r.rs485TxBusy;
						when x"0312" => readDataBuffer <= x"00" & iceTad_0r.rs485RxBusy;
						
						when x"f000" => readDataBuffer <= x"000" & "000" & ltm9007_14_0r.fifoEmptyA;
						when x"f002" => readDataBuffer <= x"000" & "000" & ltm9007_14_0r.fifoValidA;
						when x"f004" => readDataBuffer <= x"00" & ltm9007_14_0r.fifoWordsA;
						when x"f006" => readDataBuffer <= x"00" & ltm9007_14_0r.fifoWordsA2;
						
						when x"f0d0" => readDataBuffer <= x"00" & triggerLogic_0r.trigger.triggerSerdesDelayed;
						when x"f0d2" => readDataBuffer <= x"00" & triggerLogic_0r.trigger.triggerSerdesNotDelayed;
						when x"f0d4" => readDataBuffer <= x"000" & "000" & triggerLogic_0r.trigger.triggerDelayed;
						when x"f0d6" => readDataBuffer <= x"000" & "000" & triggerLogic_0r.trigger.triggerNotDelayed;
						
--						when others  => readDataBuffer <= (others => '0');
						when others  => readDataBuffer <= x"dead";
					end case;
				end if;
			end if;
		end if;
	end process P0;

	actualOffsetCorrectionRamValue <= ltm9007_14_0r.offsetCorrectionRamData(0) when ltm9007_14_0r.offsetCorrectionRamWrite(0) = '1' else 
		ltm9007_14_0r.offsetCorrectionRamData(1) when ltm9007_14_0r.offsetCorrectionRamWrite(1) = '1' else 
		ltm9007_14_0r.offsetCorrectionRamData(2) when ltm9007_14_0r.offsetCorrectionRamWrite(2) = '1' else 
		ltm9007_14_0r.offsetCorrectionRamData(3) when ltm9007_14_0r.offsetCorrectionRamWrite(3) = '1' else 
		ltm9007_14_0r.offsetCorrectionRamData(4) when ltm9007_14_0r.offsetCorrectionRamWrite(4) = '1' else 
		ltm9007_14_0r.offsetCorrectionRamData(5) when ltm9007_14_0r.offsetCorrectionRamWrite(5) = '1' else 
		ltm9007_14_0r.offsetCorrectionRamData(6) when ltm9007_14_0r.offsetCorrectionRamWrite(6) = '1' else 
		ltm9007_14_0r.offsetCorrectionRamData(7) when ltm9007_14_0r.offsetCorrectionRamWrite(7) = '1' else
		x"d00f";

--	P1:process (controlBus.clock)
--	begin
--		if rising_edge(controlBus.clock) then
--			if (controlBus.reset = '1') then
--				actualOffsetCorrectionRamValue <= x"8000";
--			else
--				if(ltm9007_14_0r.offsetCorrectionRamWrite(0) = '1') then
--					actualOffsetCorrectionRamValue <= x"00" & ltm9007_14_0r.offsetCorrectionRamData(0);
--				elsif(ltm9007_14_0r.offsetCorrectionRamWrite(1) = '1') then
--					actualOffsetCorrectionRamValue <= x"00" & ltm9007_14_0r.offsetCorrectionRamData(1);
--				elsif(ltm9007_14_0r.offsetCorrectionRamWrite(2) = '1') then
--					actualOffsetCorrectionRamValue <= x"00" & ltm9007_14_0r.offsetCorrectionRamData(2);
--				elsif(ltm9007_14_0r.offsetCorrectionRamWrite(3) = '1') then
--					actualOffsetCorrectionRamValue <= x"00" & ltm9007_14_0r.offsetCorrectionRamData(3);
--				elsif(ltm9007_14_0r.offsetCorrectionRamWrite(4) = '1') then
--					actualOffsetCorrectionRamValue <= x"00" & ltm9007_14_0r.offsetCorrectionRamData(4);
--				elsif(ltm9007_14_0r.offsetCorrectionRamWrite(5) = '1') then
--					actualOffsetCorrectionRamValue <= x"00" & ltm9007_14_0r.offsetCorrectionRamData(5);
--				elsif(ltm9007_14_0r.offsetCorrectionRamWrite(6) = '1') then
--					actualOffsetCorrectionRamValue <= x"00" & ltm9007_14_0r.offsetCorrectionRamData(6);
--				elsif(ltm9007_14_0r.offsetCorrectionRamWrite(7) = '1') then
--					actualOffsetCorrectionRamValue <= x"00" & ltm9007_14_0r.offsetCorrectionRamData(7);
--				else
--					actualOffsetCorrectionRamValue <= x"8000";
--				end if;
--			end if;
--		end if;
--	end process P1;
	
end generate g0;
end behavior;
