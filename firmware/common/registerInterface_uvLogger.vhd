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

entity registerInterface_uvLogger is
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
	
		internalTiming_0r : in internalTiming_registerRead_t;
		internalTiming_0w : out internalTiming_registerWrite_t;
		triggerDataDelay_0r : in triggerDataDelay_registerRead_t;
		triggerDataDelay_0w : out triggerDataDelay_registerWrite_t;
		triggerDataDelay_1r : in triggerDataDelay_registerRead_t;
		triggerDataDelay_1w : out triggerDataDelay_registerWrite_t;
		drs4_0r : in drs4_registerRead_t;
		drs4_0w : out drs4_registerWrite_t;
		ltm9007_14_0r : in ltm9007_14_registerRead_t;
		ltm9007_14_0w : out ltm9007_14_registerWrite_t;
		triggerTimeToRisingEdge_0r : in triggerTimeToRisingEdge_registerRead_t;
		triggerTimeToRisingEdge_0w : out triggerTimeToRisingEdge_registerWrite_t;
		eventFifoSystem_0r : in eventFifoSystem_registerRead_t;
		eventFifoSystem_0w : out eventFifoSystem_registerWrite_t;
		pixelRateCounter_0r_p0 : in pixelRateCounter_v2_registerRead_t;
		pixelRateCounter_0w : out pixelRateCounter_v2_registerWrite_t;
		triggerLogic_0r_p : in triggerLogic_registerRead_t;
		triggerLogic_0w : out triggerLogic_registerWrite_t;
		dac1_uvLogger_0r : in dac1_uvLogger_registerRead_t;
		dac1_uvLogger_0w : out dac1_uvLogger_registerWrite_t;
--		tmp10x_uvLogger_0r : in tmp10x_uvLogger_registerRead_t;
--		tmp10x_uvLogger_0w : out tmp10x_uvLogger_registerWrite_t;
		i2c_genericBus_0r : in i2c_genericBus_registerRead_t;
		i2c_genericBus_0w : out i2c_genericBus_registerWrite_t;
		i2c_genericBus_1r : in i2c_genericBus_registerRead_t;
		i2c_genericBus_1w : out i2c_genericBus_registerWrite_t;
		i2c_genericBus_2r : in i2c_genericBus_registerRead_t;
		i2c_genericBus_2w : out i2c_genericBus_registerWrite_t;
		i2c_genericBus_3r : in i2c_genericBus_registerRead_t;
		i2c_genericBus_3w : out i2c_genericBus_registerWrite_t;
		i2c_genericBus_4r : in i2c_genericBus_registerRead_t;
		i2c_genericBus_4w : out i2c_genericBus_registerWrite_t;
		i2c_genericBus_5r : in i2c_genericBus_registerRead_t;
		i2c_genericBus_5w : out i2c_genericBus_registerWrite_t;
		ledFlasher_0r : in ledFlasher_registerRead_t;
		ledFlasher_0w : out ledFlasher_registerWrite_t;
		houseKeeping_0r : in houseKeeping_registerRead_t;
		houseKeeping_0w : out houseKeeping_registerWrite_t;
		--commDebug_0r : in commDebug_registerRead_t;
		commDebug_0w : out commDebug_registerWrite_t;


--		dac088s085_x3_0r : in dac088s085_x3_registerRead_t;
--		dac088s085_x3_0w : out dac088s085_x3_registerWrite_t;
--		gpsTiming_0r : in gpsTiming_registerRead_t;
--		gpsTiming_0w : out gpsTiming_registerWrite_t;
--		whiteRabbitTiming_0r : in whiteRabbitTiming_registerRead_t;
--		whiteRabbitTiming_0w : out whiteRabbitTiming_registerWrite_t;
--		ad56x1_0r : in ad56x1_registerRead_t;
--		ad56x1_0w : out ad56x1_registerWrite_t;
--		iceTad_0r : in iceTad_registerRead_t;
--		iceTad_0w : out iceTad_registerWrite_t;
--		panelPower_0r : in panelPower_registerRead_t;
--		panelPower_0w : out panelPower_registerWrite_t;
--		tmp05_0r : in tmp05_registerRead_t;
--		tmp05_0w : out tmp05_registerWrite_t;
		clockConfig_debug_0w : out clockConfig_debug_t -- ## remove me!!!
	);
end registerInterface_uvLogger;

architecture behavior of registerInterface_uvLogger is

	signal chipSelectInternal : std_logic := '0';
	signal readDataBuffer : std_logic_vector(15 downto 0) := (others => '0');
	
	signal registerA : std_logic_vector(7 downto 0) := (others => '0');
	signal registerb : std_logic_vector(15 downto 0) := (others => '0');
	
	signal controlBus : smc_bus;
	
	signal debugReset : std_logic := '0';
	signal eventFifoClear : std_logic := '0';
	
	--signal valuesChangedChip0Temp : std_logic_vector(7 downto 0) := (others => '0');
	--signal valuesChangedChip1Temp : std_logic_vector(7 downto 0) := (others => '0');
	--signal valuesChangedChip2Temp : std_logic_vector(7 downto 0) := (others => '0');
	
	signal numberOfSamplesToRead : std_logic_vector(15 downto 0) := (others => '0');
	signal actualOffsetCorrectionRamValue : std_logic_vector(15 downto 0) := (others => '0');

--	signal eventFifoWordsDmaSlice_latched : std_logic_vector(3 downto 0) := (others => '0');
	signal whiteRabbitTiming_0r_irigDataLatched : std_logic_vector(88 downto 0) := (others => '0');
	signal whiteRabbitTiming_0r_irigBinaryYearsLatched : std_logic_vector(6 downto 0) := (others => '0');
	signal whiteRabbitTiming_0r_irigBinaryDaysLatched : std_logic_vector(8 downto 0) := (others => '0');
	signal whiteRabbitTiming_0r_irigBinarySecondsLatched : std_logic_vector(16 downto 0) := (others => '0');
--	signal irigDataLatched : std_logic_vector(72 downto 0) := (others => '0');
	signal tmp05_0r_thLatched : std_logic_vector(15 downto 0) := (others => '0');
	
	signal pixelRateCounter_0r : pixelRateCounter_v2_registerRead_t;
	signal pixelRateCounter_0r_p1 : pixelRateCounter_v2_registerRead_t;
	signal pixelRateCounter_0r_p2 : pixelRateCounter_v2_registerRead_t;
	signal triggerLogic_0r : triggerLogic_registerRead_t;

	signal ltm9007_14_0w_debug_init : std_logic;
	signal i2c_genericBus_reset : std_logic;

begin

--	irigDataLatched <= whiteRabbitTiming_0r.irigDataLatched(87 downto 49)
--					   & whiteRabbitTiming_0r.irigDataLatched(47 downto 44)
--					   & whiteRabbitTiming_0r.irigDataLatched(36 downto 31)
--					   & whiteRabbitTiming_0r.irigDataLatched(29 downto 26)
--					   & whiteRabbitTiming_0r.irigDataLatched(23 downto 22)
--					   & whiteRabbitTiming_0r.irigDataLatched(20 downto 17)
--					   & whiteRabbitTiming_0r.irigDataLatched(15 downto 13)
--					   & whiteRabbitTiming_0r.irigDataLatched(11 downto 5)
--					   & whiteRabbitTiming_0r.irigDataLatched(3 downto 0);

	process (controlBus.clock)
	begin
		if rising_edge(controlBus.clock) then
			pixelRateCounter_0r <= pixelRateCounter_0r_p2; -- ## debug ?!?
			pixelRateCounter_0r_p2 <= pixelRateCounter_0r_p1; -- ## debug ?!?
			pixelRateCounter_0r_p1 <= pixelRateCounter_0r_p0; -- ## debug ?!?
			triggerLogic_0r <= triggerLogic_0r_p; -- ## debug ?!?
		end if;
	end process;

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
	triggerDataDelay_0w.clock <= controlBus.clock;
	triggerDataDelay_0w.reset <= controlBus.reset;
	triggerDataDelay_1w.clock <= controlBus.clock;
	triggerDataDelay_1w.reset <= controlBus.reset;
	pixelRateCounter_0w.clock <= controlBus.clock;
	pixelRateCounter_0w.reset <= controlBus.reset;
	dac1_uvLogger_0w.clock <= controlBus.clock;
	dac1_uvLogger_0w.reset <= controlBus.reset;
--	tmp10x_uvLogger_0w.clock <= controlBus.clock;
--	tmp10x_uvLogger_0w.reset <= controlBus.reset;
	i2c_genericBus_0w.clock <= controlBus.clock;
	i2c_genericBus_0w.reset <= controlBus.reset or i2c_genericBus_reset; -- debug
	i2c_genericBus_1w.clock <= controlBus.clock;
	i2c_genericBus_1w.reset <= controlBus.reset or i2c_genericBus_reset; -- debug
	i2c_genericBus_2w.clock <= controlBus.clock;
	i2c_genericBus_2w.reset <= controlBus.reset or i2c_genericBus_reset; -- debug
	i2c_genericBus_3w.clock <= controlBus.clock;
	i2c_genericBus_3w.reset <= controlBus.reset or i2c_genericBus_reset; -- debug
	i2c_genericBus_4w.clock <= controlBus.clock;
	i2c_genericBus_4w.reset <= controlBus.reset or i2c_genericBus_reset; -- debug
	i2c_genericBus_5w.clock <= controlBus.clock;
	i2c_genericBus_5w.reset <= controlBus.reset or i2c_genericBus_reset; -- debug
	internalTiming_0w.clock <= controlBus.clock;
	internalTiming_0w.reset <= controlBus.reset;
	ledFlasher_0w.clock <= controlBus.clock;
	ledFlasher_0w.reset <= controlBus.reset;
	houseKeeping_0w.clock <= controlBus.clock;
	houseKeeping_0w.reset <= controlBus.reset;
	drs4_0w.clock <= controlBus.clock;
	drs4_0w.reset <= controlBus.reset;
	ltm9007_14_0w.clock <= controlBus.clock;
	ltm9007_14_0w.reset <= controlBus.reset or ltm9007_14_0w_debug_init;
	triggerLogic_0w.clock <= controlBus.clock;
	triggerLogic_0w.reset <= controlBus.reset;
	--_0w.clock <= controlBus.clock;
	--_0w.reset <= controlBus.reset;
	
	--dac088s085_x3_0w.valuesChangedChip0 <= valuesChangedChip0Temp;
	--dac088s085_x3_0w.valuesChangedChip1 <= valuesChangedChip1Temp;
	--dac088s085_x3_0w.valuesChangedChip2 <= valuesChangedChip2Temp;
				
	drs4_0w.numberOfSamplesToRead <= numberOfSamplesToRead;
	ltm9007_14_0w.numberOfSamplesToRead <= numberOfSamplesToRead;
	eventFifoSystem_0w.numberOfSamplesToRead <= numberOfSamplesToRead;
	
	--ltm9007_14_0r.offsetCorrectionRamAddress <= controlBus.address(10 downto 1) when controlBus.address(15 downto 11) = x"1"&"0" else "0000000000";
	--da sollte 'Jemand' mal einen richtigen address decoder fuer den ram bauen.....
	
	P0:process (controlBus.clock)
	begin
		if rising_edge(controlBus.clock) then
			eventFifoSystem_0w.nextWord <= '0'; -- autoreset
			eventFifoSystem_0w.forceIrq <= '0'; -- autoreset
			eventFifoSystem_0w.clearEventCounter <= '0'; -- autoreset
			triggerDataDelay_0w.resetDelay <= '0'; -- autoreset
			triggerDataDelay_1w.resetDelay <= '0'; -- autoreset
			pixelRateCounter_0w.resetCounter <= (others=>'0'); -- autoreset
			pixelRateCounter_0w.newDataReset <= '0'; -- autoreset
			debugReset <= '0'; -- autoreset
			eventFifoClear <= '0'; -- autoreset
--			dac088s085_x3_0w.init <= '0'; -- autoreset
			--ad56x1_0w.init <= '0'; -- autoreset
--			ad56x1_0w.valueChangedChip0 <= '0'; -- autoreset
--			ad56x1_0w.valueChangedChip1 <= '0'; -- autoreset
			--drs4_0w.stoftTrigger <= '0'; -- autoreset
			drs4_0w.resetStates <= '0'; -- autoreset
			ltm9007_14_0w.init <= '0'; --autoreset
			ltm9007_14_0w.bitslipStart <= '0'; --autoreset
			triggerLogic_0w.triggerSerdesDelayInit <= '0'; --autoreset
			triggerLogic_0w.singleSoftTrigger <= '0'; --autoreset
			--triggerLogic_0w.resetCounter <= '0'; -- autoreset
			triggerLogic_0w.drs4TriggerDelayReset <= '0'; --autoreset
--			panelPower_0w.init <= '0'; -- autoreset
			ltm9007_14_0w.offsetCorrectionRamWrite <= (others=>'0'); -- autoreset
--			iceTad_0w.rs485TxStart <= (others=>'0'); -- autoreset
--			iceTad_0w.rs485FifoClear <= (others=>'0'); -- autoreset
--			iceTad_0w.rs485FifoRead <= (others=>'0'); -- autoreset
--			gpsTiming_0w.newDataLatchedReset <= '0'; -- autoreset
--			whiteRabbitTiming_0w.newDataLatchedReset <= '0'; -- autoreset
--			tmp05_0w.conversionStart <= '0'; -- autoreset
--			dac088s085_x3_0w.valuesChangedChip0 <= x"00"; -- autoreset
--			dac088s085_x3_0w.valuesChangedChip1 <= x"00"; -- autoreset
--			dac088s085_x3_0w.valuesChangedChip2 <= x"00"; -- autoreset
			dac1_uvLogger_0w.valuesChangedA <= (others=>'0'); -- autoreset
			dac1_uvLogger_0w.valuesChangedB <= (others=>'0'); -- autoreset
			--dac1_uvLogger_0w.channelB(3) <= x"860");
			eventFifoSystem_0w.forceMiscData <= '0'; -- autoreset
			--dac1_uvLogger_0w.debug2 <= '0'; -- autoreset
--			tmp10x_uvLogger_0w.startConversion <= '0'; -- autoreset
			i2c_genericBus_0w.startTransfer <= '0'; -- autoreset
			i2c_genericBus_1w.startTransfer <= '0'; -- autoreset
			i2c_genericBus_2w.startTransfer <= '0'; -- autoreset
			i2c_genericBus_3w.startTransfer <= '0'; -- autoreset
			i2c_genericBus_4w.startTransfer <= '0'; -- autoreset
			i2c_genericBus_5w.startTransfer <= '0'; -- autoreset
			ltm9007_14_0w_debug_init <= '0'; -- autoreset
			i2c_genericBus_reset <= '0'; -- autoreset
			ledFlasher_0w.doSingleShot <= (others=>'0'); -- autoreset
			if (controlBus.reset = '1') then
				registerA <= (others => '0');
				registerb <= (others => '0');
				triggerDataDelay_0w.numberOfDelayCycles <= x"0004";
				triggerDataDelay_0w.resetDelay <= '1';
				triggerDataDelay_1w.numberOfDelayCycles <= x"0005";
				triggerDataDelay_1w.resetDelay <= '1';
--				ad56x1_0w.valueChip0 <= x"800";
--				ad56x1_0w.valueChip1 <= x"800";
--				--ad56x1_0w.init <= '1';
--				ad56x1_0w.valueChangedChip0 <= '1'; -- autoreset
--				ad56x1_0w.valueChangedChip1 <= '1'; -- autoreset
				eventFifoSystem_0w.packetConfig <= x"0006";
				eventFifoSystem_0w.eventsPerIrq <= x"0001";
				eventFifoSystem_0w.irqAtEventFifoWords <= x"0100";
				eventFifoSystem_0w.enableIrq <= '0';
				eventFifoSystem_0w.irqStall <= '0';
				eventFifoSystem_0w.deviceId <= x"0000";
				eventFifoSystem_0w.miscSlotA <= (others=>(others=>'0'));
				eventFifoSystem_0w.miscSlotB <= (others=>(others=>'0'));
				numberOfSamplesToRead <= x"0040";
				drs4_0w.sampleMode <= x"0";
				drs4_0w.readoutMode <= x"5"; 
				drs4_0w.writeShiftRegister <= "11111111"; 
				ltm9007_14_0w.testMode <= x"0";
				ltm9007_14_0w.init <= '1'; --autoreset
				triggerLogic_0w.triggerMask <= x"00"; -- "00" = all on 
				triggerLogic_0w.triggerSerdesDelayInit <= '1'; --autoreset
				triggerLogic_0w.triggerSerdesDelay <= "00" & x"68";
				triggerLogic_0w.triggerGeneratorPeriod <= x"00c00000"; -- 0xc0000 ~ 10Hz
				--triggerLogic_0w.sameEventTime <= x"080"; -- like numberOfSamplesToRead/8  but different time per tick
				--notOnPaddle <= (others=>'0');
--				panelPower_0w.enable <= '0';
--				dac088s085_x3_0w.valuesChip0 <= (others=>x"30");
--				dac088s085_x3_0w.valuesChip1 <= (others=>x"00");
--				dac088s085_x3_0w.valuesChip2 <= (others=>x"00");
--				dac088s085_x3_0w.valuesChangedChip0 <= x"ff";
--				dac088s085_x3_0w.valuesChangedChip1 <= x"ff";
--				dac088s085_x3_0w.valuesChangedChip2 <= x"ff";
				--dac088s085_x3_0w.valuesChip1(0) <= x"80";
				--dac088s085_x3_0w.valuesChip1(2) <= x"80";
				--dac088s085_x3_0w.valuesChip1(4) <= x"80";
				--dac088s085_x3_0w.valuesChip1(6) <= x"80";
				--dac088s085_x3_0w.valuesChip2(0) <= x"80";
				--dac088s085_x3_0w.valuesChip2(2) <= x"80";
				--dac088s085_x3_0w.valuesChip2(4) <= x"80";
				--dac088s085_x3_0w.valuesChip2(6) <= x"80";
				clockConfig_debug_0w.drs4RefClockPeriod <= x"7f";
--				eventFifoWordsDmaSlice_latched <= (others=>'0');
				--pixelRateCounter_0w.doublePulsePrevention <= '1';
				--pixelRateCounter_0w.doublePulseTime <= x"80"; -- 0x30 ~ 400ns; 0x80 ~ like 1us; maybe it shoud be like 'sameEventTime' 
				pixelRateCounter_0w.rateCounterPeriod <= x"0001"; -- 1 sec
				triggerLogic_0w.gateTime <= x"0164"; -- 0x164 == 356 ~3us@118.75MHz
				triggerLogic_0w.drs4TriggerDelay <= "0" & x"78"; -- 0x78 ~1us
				triggerLogic_0w.drs4Decimator <= x"0000";
--				whiteRabbitTiming_0w.counterPeriod <= x"0001"; -- 1 sec
				--triggerLogic_0w.counterPeriod <= x"0001"; -- 1 sec
--				iceTad_0w.rs485Data <= (others=>(others=>'0'));
--				iceTad_0w.softTxEnable <= (others=>'0');
--				iceTad_0w.softTxMask <= (others=>'0');
				dac1_uvLogger_0w.channelB <= (others=>x"c00");
				--dac1_uvLogger_0w.channelB <= (others=>(others=>'0'));
				dac1_uvLogger_0w.channelA <= (others=>(others=>'0'));
				dac1_uvLogger_0w.channelA(0) <= x"47a"; -- bias 0.7V
				dac1_uvLogger_0w.channelA(1) <= x"6b6"; -- rofs 1.05V
				dac1_uvLogger_0w.channelA(2) <= x"000"; -- cmofs
				dac1_uvLogger_0w.channelA(3) <= x"860"; -- oofs 1.3V
				dac1_uvLogger_0w.channelA(4) <= x"5b0"; -- offset+
				dac1_uvLogger_0w.channelA(5) <= x"5b0"; -- offset-
				ledFlasher_0w.enableGenerator <= (others=>'0');
				ledFlasher_0w.useNegativePolarity <= "01";
				ledFlasher_0w.pulseWidth0 <= x"02";
				ledFlasher_0w.pulseWidth1 <= x"02";
				ledFlasher_0w.generatorPeriod0 <= x"00b532b8"; -- ## 00b532b8 == 10HZ
				ledFlasher_0w.generatorPeriod1 <= x"00b532b8";
				houseKeeping_0w.enablePcbLeds <= '0';
				houseKeeping_0w.enableJ24TestPins <= '0';
				--triggerTimeToRisingEdge_0w.timeout <= x"0164"; -- 0x164 == 356 ~ 3us@118.75MHz
				commDebug_0w.tx_baud_div <= i2v(300,16); 
				commDebug_0w.dU_1mV <= x"0190";
				commDebug_0w.com_adc_thr <= x"0083";
				commDebug_0w.dac_valueIdle <= x"800";
				commDebug_0w.dac_valueLow <= x"001";
				commDebug_0w.dac_valueHigh <= x"ffe";
				commDebug_0w.dac_incDacValue <= x"200";
				commDebug_0w.dac_time1 <= i2v(60,16);
				commDebug_0w.dac_time2 <= i2v(62,16);
				commDebug_0w.dac_time3 <= i2v(10,16);
				commDebug_0w.dac_clkTime <= x"0001";
				commDebug_0w.com_thr_adj <= "000";
				commDebug_0w.adc_deadTime <= x"0f0";
				commDebug_0w.adc_syncTimeout <= x"1000";
				commDebug_0w.adc_baselineAveragingTime <= x"03ff";
				commDebug_0w.jumper <= x"0000";
				commDebug_0w.adc_threshold_p <= i2v(8400,16);
				commDebug_0w.adc_threshold_n <= i2v(8000,16);
				commDebug_0w.fifo_avrFactor <= x"4";
				commDebug_0w.adc_decoder_t1 <= x"1000";
				commDebug_0w.adc_decoder_t2 <= x"0030";
				commDebug_0w.adc_decoder_t3 <= x"0100";
				commDebug_0w.adc_decoder_t4 <= x"0130";
				commDebug_0w.adc_decoder_bits <= x"0008";
				commDebug_0w.decoder2frameWidth <= x"0009";
				commDebug_0w.adc_debug <= x"0000";
				commDebug_0w.uartDebugLoop0Enable <= '0';
				commDebug_0w.uartDebugLoop1Enable <= '0';
			else
				--valuesChangedChip0Temp <= valuesChangedChip0Temp and not(dac088s085_x3_0r.valuesChangedChip0Reset); -- ## move to module.....
				--valuesChangedChip1Temp <= valuesChangedChip1Temp and not(dac088s085_x3_0r.valuesChangedChip1Reset);
				--valuesChangedChip2Temp <= valuesChangedChip2Temp and not(dac088s085_x3_0r.valuesChangedChip2Reset);
	
				if ((controlBus.writeStrobe = '1') and (controlBus.readStrobe = '0') and (chipSelectInternal = '1')) then
					case (controlBus.address(15 downto 0) and not(subAddressMask)) is
						-- address 0x0000-0x0fff has to be the same for all taxi based systems
						-- address 0x1000-0x1fff is used for icescint
						-- address 0x2000-0x2fff is used for polarstern
						-- address 0x3000-0x3fff is used for taxi classic (24ch. version)
						when x"0000" => registerA <= dataBusIn(7 downto 0);
						when x"0002" => registerB <= dataBusIn;
						
						when x"0010" => ltm9007_14_0w_debug_init <= '1'; -- autoreset
					
						when x"0102" => eventFifoClear <= '1'; -- autoreset
						when x"0108" => eventFifoSystem_0w.irqStall <= dataBusIn(0);
						when x"010a" => eventFifoSystem_0w.deviceId <= dataBusIn;
					
--						when x"0200" => gpsTiming_0w.counterPeriod <= dataBusIn;
--						when x"0202" => gpsTiming_0w.newDataLatchedReset <= '1'; -- autoreset
						
--						when x"0300" => tmp05_0w.conversionStart <= dataBusIn(0); -- autoreset
						when others => null;
					end case;

--					case (controlBus.address(15 downto 0) and not(subAddressMask)) is
--						when x"0310" => ad56x1_0w.valueChip0 <= dataBusIn(11 downto 0); ad56x1_0w.valueChangedChip0 <= '1'; -- autoreset
--						when x"0312" => ad56x1_0w.valueChip1 <= dataBusIn(11 downto 0); ad56x1_0w.valueChangedChip1 <= '1'; -- autoreset
--						when x"0314" => ad56x1_0w.valueChangedChip0 <= dataBusIn(0); ad56x1_0w.valueChangedChip1 <= dataBusIn(1); -- autoreset
--						when others => null;
--					end case;

					case (controlBus.address(15 downto 0) and not(subAddressMask)) is
						--when x"0400" => dac1_uvLogger_0w.debug2 <= '1'; -- autoreset
						when x"0402" => dac1_uvLogger_0w.valuesChangedA <= dataBusIn(7 downto 0); -- autoreset
						when x"0410" => dac1_uvLogger_0w.channelA(0) <= dataBusIn(11 downto 0); dac1_uvLogger_0w.valuesChangedA(0) <= '1';
						when x"0412" => dac1_uvLogger_0w.channelA(1) <= dataBusIn(11 downto 0); dac1_uvLogger_0w.valuesChangedA(1) <= '1';
						when x"0414" => dac1_uvLogger_0w.channelA(2) <= dataBusIn(11 downto 0); dac1_uvLogger_0w.valuesChangedA(2) <= '1';
						when x"0416" => dac1_uvLogger_0w.channelA(3) <= dataBusIn(11 downto 0); dac1_uvLogger_0w.valuesChangedA(3) <= '1';
						when x"0418" => dac1_uvLogger_0w.channelA(4) <= dataBusIn(11 downto 0); dac1_uvLogger_0w.valuesChangedA(4) <= '1';
						when x"041a" => dac1_uvLogger_0w.channelA(5) <= dataBusIn(11 downto 0); dac1_uvLogger_0w.valuesChangedA(5) <= '1';
						when x"041c" => dac1_uvLogger_0w.channelA(6) <= dataBusIn(11 downto 0); dac1_uvLogger_0w.valuesChangedA(6) <= '1';
						when x"041e" => dac1_uvLogger_0w.channelA(7) <= dataBusIn(11 downto 0); dac1_uvLogger_0w.valuesChangedA(7) <= '1';
						
						when x"0404" => dac1_uvLogger_0w.valuesChangedB <= dataBusIn(7 downto 0); -- autoreset
						when x"0420" => dac1_uvLogger_0w.channelB(0) <= dataBusIn(11 downto 0); dac1_uvLogger_0w.valuesChangedB(0) <= '1';
						when x"0422" => dac1_uvLogger_0w.channelB(1) <= dataBusIn(11 downto 0); dac1_uvLogger_0w.valuesChangedB(1) <= '1';
						when x"0424" => dac1_uvLogger_0w.channelB(2) <= dataBusIn(11 downto 0); dac1_uvLogger_0w.valuesChangedB(2) <= '1';
						when x"0426" => dac1_uvLogger_0w.channelB(3) <= dataBusIn(11 downto 0); dac1_uvLogger_0w.valuesChangedB(3) <= '1';
						when x"0428" => dac1_uvLogger_0w.channelB(4) <= dataBusIn(11 downto 0); dac1_uvLogger_0w.valuesChangedB(4) <= '1';
						when x"042a" => dac1_uvLogger_0w.channelB(5) <= dataBusIn(11 downto 0); dac1_uvLogger_0w.valuesChangedB(5) <= '1';
						when x"042c" => dac1_uvLogger_0w.channelB(6) <= dataBusIn(11 downto 0); dac1_uvLogger_0w.valuesChangedB(6) <= '1';
						when x"042e" => dac1_uvLogger_0w.channelB(7) <= dataBusIn(11 downto 0); dac1_uvLogger_0w.valuesChangedB(7) <= '1';
						when others => null;
					end case;
--					case (controlBus.address(15 downto 0) and not(subAddressMask)) is
--						when x"0400" => dac088s085_x3_0w.init <= '1'; -- autoreset
--						when x"0402" => dac088s085_x3_0w.valuesChangedChip0 <= dataBusIn(7 downto 0); -- autoreset
--						when x"0404" => dac088s085_x3_0w.valuesChangedChip1 <= dataBusIn(7 downto 0); -- autoreset
--						when x"0406" => dac088s085_x3_0w.valuesChangedChip2 <= dataBusIn(7 downto 0); -- autoreset
--						when x"0410" => dac088s085_x3_0w.valuesChip0(0) <= dataBusIn(7 downto 0); dac088s085_x3_0w.valuesChangedChip0(0) <= '1';
--						when x"0412" => dac088s085_x3_0w.valuesChip0(1) <= dataBusIn(7 downto 0); dac088s085_x3_0w.valuesChangedChip0(1) <= '1';
--						when x"0414" => dac088s085_x3_0w.valuesChip0(2) <= dataBusIn(7 downto 0); dac088s085_x3_0w.valuesChangedChip0(2) <= '1';
--						when x"0416" => dac088s085_x3_0w.valuesChip0(3) <= dataBusIn(7 downto 0); dac088s085_x3_0w.valuesChangedChip0(3) <= '1';
--						when x"0418" => dac088s085_x3_0w.valuesChip0(4) <= dataBusIn(7 downto 0); dac088s085_x3_0w.valuesChangedChip0(4) <= '1';
--						when x"041a" => dac088s085_x3_0w.valuesChip0(5) <= dataBusIn(7 downto 0); dac088s085_x3_0w.valuesChangedChip0(5) <= '1';
--						when x"041c" => dac088s085_x3_0w.valuesChip0(6) <= dataBusIn(7 downto 0); dac088s085_x3_0w.valuesChangedChip0(6) <= '1';
--						when x"041e" => dac088s085_x3_0w.valuesChip0(7) <= dataBusIn(7 downto 0); dac088s085_x3_0w.valuesChangedChip0(7) <= '1';
--						when x"0420" => dac088s085_x3_0w.valuesChip1(0) <= dataBusIn(7 downto 0); dac088s085_x3_0w.valuesChangedChip0(0) <= '1';
--						when x"0422" => dac088s085_x3_0w.valuesChip1(1) <= dataBusIn(7 downto 0); dac088s085_x3_0w.valuesChangedChip1(1) <= '1';
--						when x"0424" => dac088s085_x3_0w.valuesChip1(2) <= dataBusIn(7 downto 0); dac088s085_x3_0w.valuesChangedChip1(2) <= '1';
--						when x"0426" => dac088s085_x3_0w.valuesChip1(3) <= dataBusIn(7 downto 0); dac088s085_x3_0w.valuesChangedChip1(3) <= '1';
--						when x"0428" => dac088s085_x3_0w.valuesChip1(4) <= dataBusIn(7 downto 0); dac088s085_x3_0w.valuesChangedChip1(4) <= '1';
--						when x"042a" => dac088s085_x3_0w.valuesChip1(5) <= dataBusIn(7 downto 0); dac088s085_x3_0w.valuesChangedChip1(5) <= '1';
--						when x"042c" => dac088s085_x3_0w.valuesChip1(6) <= dataBusIn(7 downto 0); dac088s085_x3_0w.valuesChangedChip1(6) <= '1';
--						when x"042e" => dac088s085_x3_0w.valuesChip1(7) <= dataBusIn(7 downto 0); dac088s085_x3_0w.valuesChangedChip1(7) <= '1';
--						when x"0430" => dac088s085_x3_0w.valuesChip2(0) <= dataBusIn(7 downto 0); dac088s085_x3_0w.valuesChangedChip2(0) <= '1';
--						when x"0432" => dac088s085_x3_0w.valuesChip2(1) <= dataBusIn(7 downto 0); dac088s085_x3_0w.valuesChangedChip2(1) <= '1';
--						when x"0434" => dac088s085_x3_0w.valuesChip2(2) <= dataBusIn(7 downto 0); dac088s085_x3_0w.valuesChangedChip2(2) <= '1';
--						when x"0436" => dac088s085_x3_0w.valuesChip2(3) <= dataBusIn(7 downto 0); dac088s085_x3_0w.valuesChangedChip2(3) <= '1';
--						when x"0438" => dac088s085_x3_0w.valuesChip2(4) <= dataBusIn(7 downto 0); dac088s085_x3_0w.valuesChangedChip2(4) <= '1';
--						when x"043a" => dac088s085_x3_0w.valuesChip2(5) <= dataBusIn(7 downto 0); dac088s085_x3_0w.valuesChangedChip2(5) <= '1';
--						when x"043c" => dac088s085_x3_0w.valuesChip2(6) <= dataBusIn(7 downto 0); dac088s085_x3_0w.valuesChangedChip2(6) <= '1';
--						when x"043e" => dac088s085_x3_0w.valuesChip2(7) <= dataBusIn(7 downto 0); dac088s085_x3_0w.valuesChangedChip2(7) <= '1';
--						when others => null;
--					end case;

--					case (controlBus.address(15 downto 0) and not(subAddressMask)) is
--						when x"4000" => tmp10x_uvLogger_0w.startConversion <= dataBusIn(0); -- autoreset
--						when others => null;
--					end case;

					case (controlBus.address(15 downto 0) and not(subAddressMask)) is
						when x"4012" => i2c_genericBus_0w.data <= dataBusIn(7 downto 0);
						when x"4014" => 
							i2c_genericBus_0w.direction <= dataBusIn(0);
							i2c_genericBus_0w.sendStartBeforeData <= dataBusIn(1);
							i2c_genericBus_0w.sendStopAfterData <= dataBusIn(2);
							i2c_genericBus_0w.waitForAckAfterData <= dataBusIn(3);
							i2c_genericBus_0w.sendAckAfterData <= dataBusIn(4);
						when x"4016" => i2c_genericBus_0w.startTransfer <= dataBusIn(0); -- autoreset
						when x"4018" => i2c_genericBus_reset <= '1'; -- autoreset
						when others => null;
					end case;

					case (controlBus.address(15 downto 0) and not(subAddressMask)) is
						when x"4022" => i2c_genericBus_1w.data <= dataBusIn(7 downto 0);
						when x"4024" => 
							i2c_genericBus_1w.direction <= dataBusIn(0);
							i2c_genericBus_1w.sendStartBeforeData <= dataBusIn(1);
							i2c_genericBus_1w.sendStopAfterData <= dataBusIn(2);
							i2c_genericBus_1w.waitForAckAfterData <= dataBusIn(3);
							i2c_genericBus_1w.sendAckAfterData <= dataBusIn(4);
						when x"4026" => i2c_genericBus_1w.startTransfer <= dataBusIn(0); -- autoreset
						when x"4028" => i2c_genericBus_reset <= '1'; -- autoreset
						when others => null;
					end case;

					case (controlBus.address(15 downto 0) and not(subAddressMask)) is
						when x"4032" => i2c_genericBus_2w.data <= dataBusIn(7 downto 0);
						when x"4034" => 
							i2c_genericBus_2w.direction <= dataBusIn(0);
							i2c_genericBus_2w.sendStartBeforeData <= dataBusIn(1);
							i2c_genericBus_2w.sendStopAfterData <= dataBusIn(2);
							i2c_genericBus_2w.waitForAckAfterData <= dataBusIn(3);
							i2c_genericBus_2w.sendAckAfterData <= dataBusIn(4);
						when x"4036" => i2c_genericBus_2w.startTransfer <= dataBusIn(0); -- autoreset
						when x"4038" => i2c_genericBus_reset <= '1'; -- autoreset
						when others => null;
					end case;

					case (controlBus.address(15 downto 0) and not(subAddressMask)) is
						when x"4042" => i2c_genericBus_3w.data <= dataBusIn(7 downto 0);
						when x"4044" => 
							i2c_genericBus_3w.direction <= dataBusIn(0);
							i2c_genericBus_3w.sendStartBeforeData <= dataBusIn(1);
							i2c_genericBus_3w.sendStopAfterData <= dataBusIn(2);
							i2c_genericBus_3w.waitForAckAfterData <= dataBusIn(3);
							i2c_genericBus_3w.sendAckAfterData <= dataBusIn(4);
						when x"4046" => i2c_genericBus_3w.startTransfer <= dataBusIn(0); -- autoreset
						when x"4048" => i2c_genericBus_reset <= '1'; -- autoreset
						when others => null;
					end case;
				
					case (controlBus.address(15 downto 0) and not(subAddressMask)) is
						when x"4052" => i2c_genericBus_4w.data <= dataBusIn(7 downto 0);
						when x"4054" => 
							i2c_genericBus_4w.direction <= dataBusIn(0);
							i2c_genericBus_4w.sendStartBeforeData <= dataBusIn(1);
							i2c_genericBus_4w.sendStopAfterData <= dataBusIn(2);
							i2c_genericBus_4w.waitForAckAfterData <= dataBusIn(3);
							i2c_genericBus_4w.sendAckAfterData <= dataBusIn(4);
						when x"4056" => i2c_genericBus_4w.startTransfer <= dataBusIn(0); -- autoreset
						when x"4058" => i2c_genericBus_reset <= '1'; -- autoreset
						when others => null;
					end case;
					
					case (controlBus.address(15 downto 0) and not(subAddressMask)) is
						when x"4062" => i2c_genericBus_5w.data <= dataBusIn(7 downto 0);
						when x"4064" => 
							i2c_genericBus_5w.direction <= dataBusIn(0);
							i2c_genericBus_5w.sendStartBeforeData <= dataBusIn(1);
							i2c_genericBus_5w.sendStopAfterData <= dataBusIn(2);
							i2c_genericBus_5w.waitForAckAfterData <= dataBusIn(3);
							i2c_genericBus_5w.sendAckAfterData <= dataBusIn(4);
						when x"4066" => i2c_genericBus_5w.startTransfer <= dataBusIn(0); -- autoreset
						when x"4068" => i2c_genericBus_reset <= '1'; -- autoreset
						when others => null;
					end case;
					
					case (controlBus.address(15 downto 0) and not(subAddressMask)) is
						when x"4100" => eventFifoSystem_0w.miscSlotA(0) <= dataBusIn;
						when x"4102" => eventFifoSystem_0w.miscSlotA(1) <= dataBusIn;
						when x"4104" => eventFifoSystem_0w.miscSlotA(2) <= dataBusIn;
						when x"4106" => eventFifoSystem_0w.miscSlotA(3) <= dataBusIn;
						when x"4108" => eventFifoSystem_0w.miscSlotA(4) <= dataBusIn;
						when x"410a" => eventFifoSystem_0w.miscSlotA(5) <= dataBusIn;
						when x"410c" => eventFifoSystem_0w.miscSlotA(6) <= dataBusIn;
						when x"410e" => eventFifoSystem_0w.miscSlotA(7) <= dataBusIn;
						when x"4110" => eventFifoSystem_0w.miscSlotB(0) <= dataBusIn;
						when x"4112" => eventFifoSystem_0w.miscSlotB(1) <= dataBusIn;
						when x"4114" => eventFifoSystem_0w.miscSlotB(2) <= dataBusIn;
						when x"4116" => eventFifoSystem_0w.miscSlotB(3) <= dataBusIn;
						when x"4118" => eventFifoSystem_0w.miscSlotB(4) <= dataBusIn;
						when x"411a" => eventFifoSystem_0w.miscSlotB(5) <= dataBusIn;
						when x"411c" => eventFifoSystem_0w.miscSlotB(6) <= dataBusIn;
						when x"411e" => eventFifoSystem_0w.miscSlotB(7) <= dataBusIn;
						when others => null;
					end case;

					case (controlBus.address(15 downto 0) and not(subAddressMask)) is
						when x"4080" => ledFlasher_0w.doSingleShot <= dataBusIn(1 downto 0); -- autoreset
						when x"4082" => ledFlasher_0w.enableGenerator <= dataBusIn(1 downto 0);
						when x"4084" => ledFlasher_0w.useNegativePolarity <= dataBusIn(1 downto 0);
						when x"4086" => ledFlasher_0w.pulseWidth0 <= dataBusIn(7 downto 0);
						when x"4088" => ledFlasher_0w.pulseWidth1 <= dataBusIn(7 downto 0);
						when x"408a" => ledFlasher_0w.generatorPeriod0(31 downto 16) <= dataBusIn(15 downto 0);
						when x"408c" => ledFlasher_0w.generatorPeriod0(15 downto 0) <= dataBusIn(15 downto 0);
						when x"408e" => ledFlasher_0w.generatorPeriod1(31 downto 16) <= dataBusIn(15 downto 0);
						when x"4090" => ledFlasher_0w.generatorPeriod1(15 downto 0) <= dataBusIn(15 downto 0);
						when others => null;
					end case;
					
					case (controlBus.address(15 downto 0) and not(subAddressMask)) is
						when x"40a0" => houseKeeping_0w.enablePcbLeds <= dataBusIn(0);
						when x"40a2" => houseKeeping_0w.enablePcbLedGreen <= dataBusIn(0);
						when x"40a4" => houseKeeping_0w.enablePcbLedRed <= dataBusIn(0);
						when x"40a6" => houseKeeping_0w.enableJ24TestPins <= dataBusIn(0);
						when others => null;
					end case;

					case (controlBus.address(15 downto 0) and not(subAddressMask)) is
						when x"100a" => clockConfig_debug_0w.drs4RefClockPeriod <= dataBusIn(7 downto 0);
						when x"100c" => triggerDataDelay_0w.numberOfDelayCycles <= dataBusIn; triggerDataDelay_0w.resetDelay <= '1'; -- autoreset
						when x"100e" => triggerDataDelay_1w.numberOfDelayCycles <= dataBusIn; triggerDataDelay_1w.resetDelay <= '1'; -- autoreset
						when others => null;
					end case;
					
					--case (controlBus.address(15 downto 0) and not(subAddressMask)) is
					--	when x"1020" => triggerTimeToRisingEdge_0w.timeout <= dataBusIn;
					--	when others => null;
					--end case;
					

					case (controlBus.address(15 downto 0) and not(subAddressMask)) is
						when x"1040" => pixelRateCounter_0w.resetCounter <= dataBusIn(7 downto 0); -- autoreset
						when x"1042" => pixelRateCounter_0w.rateCounterPeriod <= dataBusIn; -- autoreset
					--	when x"1044" => pixelRateCounter_0w.doublePulsePrevention <= dataBusIn(0);
						when x"1046" => triggerLogic_0w.gateTime <= dataBusIn(15 downto 0);
						when x"1048" => pixelRateCounter_0w.newDataReset <= dataBusIn(0); -- autoreset
						when others => null;
					end case;

					case (controlBus.address(15 downto 0) and not(subAddressMask)) is
						
						--when x"10a0" => drs4_0w.stoftTrigger <= '1'; -- autoreset
						when x"10a4" => drs4_0w.resetStates <= '1'; -- autoreset
						when x"10a6" => numberOfSamplesToRead <= dataBusIn;
						when x"10a8" => drs4_0w.sampleMode <= dataBusIn(3 downto 0);
						when x"10aa" => drs4_0w.readoutMode <= dataBusIn(3 downto 0);
						when x"10ac" => drs4_0w.writeShiftRegister <= dataBusIn(7 downto 0);
						when others => null;
					end case;

					case (controlBus.address(15 downto 0) and not(subAddressMask)) is
						when x"10b0" => ltm9007_14_0w.testMode <= dataBusIn(3 downto 0);
							ltm9007_14_0w.init <= '1'; -- autoreset
						when x"10b2" => ltm9007_14_0w.testPattern <= dataBusIn(13 downto 0); 
						when x"10b4" => ltm9007_14_0w.bitslipStart <= '1'; -- autoreset 
						when x"10b6" => ltm9007_14_0w.bitslipPattern <= dataBusIn(6 downto 0); 
					
						when x"10e0" => ltm9007_14_0w.offsetCorrectionRamWrite <= dataBusIn(7 downto 0); -- autoreset 
						--when x"10e0" => ltm9007_14_0w.offsetCorrectionRamWrite <= dataBusIn(2 downto 0); 
						when x"10e2" => ltm9007_14_0w.offsetCorrectionRamAddress <= dataBusIn(9 downto 0); 
						when x"10e4" => ltm9007_14_0w.offsetCorrectionRamData <= dataBusIn(15 downto 0); 
						when x"10e6" => ltm9007_14_0w.baselineStart <= dataBusIn(9 downto 0); 
						when x"10e8" => ltm9007_14_0w.baselineEnd <= dataBusIn(9 downto 0); 
						when others => null;
					end case;
					
--					case (controlBus.address(15 downto 0) and not(subAddressMask)) is
--						when x"10f0" => iceTad_0w.powerOn <= dataBusIn(7 downto 0); 
--						when x"10f2" => panelPower_0w.init <= '1'; -- autoreset 
--						when x"10f4" => panelPower_0w.enable <= dataBusIn(0); 
--						when others => null;
--					end case;

					case (controlBus.address(15 downto 0) and not(subAddressMask)) is
						when x"1100" => eventFifoSystem_0w.packetConfig <= dataBusIn;
						when x"1102" => eventFifoSystem_0w.eventsPerIrq <= dataBusIn;
						when x"1104" => eventFifoSystem_0w.irqAtEventFifoWords <= dataBusIn;
						when x"1106" => eventFifoSystem_0w.enableIrq <= dataBusIn(0);
						when x"1108" => eventFifoSystem_0w.forceIrq <= dataBusIn(0); -- autoreset
						when x"110a" => eventFifoSystem_0w.clearEventCounter <= dataBusIn(0); -- autoreset
						when x"110c" => eventFifoSystem_0w.forceMiscData <= '1'; -- autoreset
						when x"112c" => debugReset <= '1'; -- autoreset
						when others => null;
					end case;

					case (controlBus.address(15 downto 0) and not(subAddressMask)) is
						when x"11d0" => triggerLogic_0w.triggerSerdesDelay <= dataBusIn(9 downto 0);
							triggerLogic_0w.triggerSerdesDelayInit <= '1'; --autoreset
							triggerDataDelay_1w.numberOfDelayCycles <= x"00" & dataBusIn(7 downto 0);
							triggerDataDelay_1w.resetDelay <= '1'; -- autoreset

						when x"11d2" => triggerLogic_0w.singleSoftTrigger <= '1'; --autoreset
						when x"11d4" => triggerLogic_0w.triggerMask <= dataBusIn(7 downto 0);
						when x"11d6" => triggerLogic_0w.singleSeq <= dataBusIn(0);
						when x"11d8" => triggerLogic_0w.triggerGeneratorEnabled <= dataBusIn(0);
						when x"11da" => triggerLogic_0w.triggerGeneratorPeriod(15 downto 0) <= unsigned(dataBusIn);
						when x"11dc" => triggerLogic_0w.triggerGeneratorPeriod(31 downto 16) <= unsigned(dataBusIn);
						--when x"11de" => triggerLogic_0w.resetCounter <= dataBusIn(0); -- autoreset
						--when x"11e0" => triggerLogic_0w.counterPeriod <= dataBusIn; -- autoreset
						--when x"11e8" => triggerLogic_0w.sameEventTime <= dataBusIn(11 downto 0);
						when x"11ea" => triggerLogic_0w.drs4TriggerDelay <= dataBusIn(8 downto 0);
							triggerLogic_0w.drs4TriggerDelayReset <= '1'; --autoreset
						when x"11ec" => triggerLogic_0w.drs4Decimator <= dataBusIn(15 downto 0);
						when others => null;
					end case;

--					case (controlBus.address(15 downto 0) and not(subAddressMask)) is
--						when x"1300" => iceTad_0w.rs485Data(0) <= dataBusIn(7 downto 0); 
--						when x"1302" => iceTad_0w.rs485Data(1) <= dataBusIn(7 downto 0); 
--						when x"1304" => iceTad_0w.rs485Data(2) <= dataBusIn(7 downto 0); 
--						when x"1306" => iceTad_0w.rs485Data(3) <= dataBusIn(7 downto 0); 
--						when x"1308" => iceTad_0w.rs485Data(4) <= dataBusIn(7 downto 0); 
--						when x"130a" => iceTad_0w.rs485Data(5) <= dataBusIn(7 downto 0); 
--						when x"130c" => iceTad_0w.rs485Data(6) <= dataBusIn(7 downto 0); 
--						when x"130e" => iceTad_0w.rs485Data(7) <= dataBusIn(7 downto 0); 
--						when x"1310" => iceTad_0w.rs485TxStart <= dataBusIn(7 downto 0); -- autoreset
--						when x"1318" => iceTad_0w.rs485FifoClear <= dataBusIn(7 downto 0); -- autoreset
--						when x"131a" => iceTad_0w.rs485FifoRead <= dataBusIn(7 downto 0); -- autoreset
--						when x"131c" => iceTad_0w.softTxEnable <= dataBusIn(7 downto 0); 
--						when x"131e" => iceTad_0w.softTxMask <= dataBusIn(7 downto 0); 
--						when others => null;
--					end case;
						
--					case (controlBus.address(15 downto 0) and not(subAddressMask)) is
--						when x"1400" => whiteRabbitTiming_0w.newDataLatchedReset <= '1'; -- autoreset
--						when x"1420" => whiteRabbitTiming_0w.counterPeriod <= dataBusIn;
--						when others => null;
--					end case;
					case (controlBus.address(15 downto 0) and not(subAddressMask)) is
						when x"d000" => commDebug_0w.tx_baud_div <= dataBusIn(15 downto 0);
						when x"d002" => commDebug_0w.dU_1mV <= dataBusIn(15 downto 0);
						when x"d004" => commDebug_0w.com_adc_thr <= dataBusIn(15 downto 0);
						--when x"d008" => commDebug_0w.dac_incDacValue <= dataBusIn(11 downto 0);
						when x"d010" => commDebug_0w.dac_valueIdle <= dataBusIn(11 downto 0);
						when x"d012" => commDebug_0w.dac_valueLow <= dataBusIn(11 downto 0);
						when x"d014" => commDebug_0w.dac_valueHigh <= dataBusIn(11 downto 0);
						when x"d016" => commDebug_0w.dac_time1 <= dataBusIn(15 downto 0);
						when x"d018" => commDebug_0w.dac_time2 <= dataBusIn(15 downto 0);
						when x"d01a" => commDebug_0w.dac_time3 <= dataBusIn(15 downto 0);
						when x"d01c" => commDebug_0w.dac_clkTime <= dataBusIn(15 downto 0);
						when x"d01e" => commDebug_0w.com_thr_adj <= dataBusIn(2 downto 0);
						when x"d020" => commDebug_0w.adc_deadTime <= dataBusIn(11 downto 0);
						when x"d022" => commDebug_0w.adc_syncTimeout <= dataBusIn(15 downto 0);
						when x"d024" => commDebug_0w.adc_baselineAveragingTime <= dataBusIn(15 downto 0);
						when x"d026" => commDebug_0w.jumper <= dataBusIn(15 downto 0);
						when x"d028" => commDebug_0w.adc_threshold_p <= dataBusIn(15 downto 0);
						when x"d02a" => commDebug_0w.adc_threshold_n <= dataBusIn(15 downto 0);
						when x"d02c" => commDebug_0w.fifo_avrFactor <= dataBusIn(3 downto 0);
						when x"d02e" => commDebug_0w.uartDebugLoop0Enable <= dataBusIn(0);
							commDebug_0w.uartDebugLoop1Enable <= dataBusIn(1);
						when x"d030" => commDebug_0w.adc_debug <= dataBusIn(15 downto 0);
						when others => null;
					end case;

				elsif ((controlBus.readStrobe = '1') and (controlBus.writeStrobe = '0') and (chipSelectInternal = '1')) then	
					case (controlBus.address(15 downto 0) and not(subAddressMask)) is
						when x"0000" => readDataBuffer <= x"00"&registerA;
						when x"0002" => readDataBuffer <= registerB;
						
						when x"0100" => readDataBuffer <= eventFifoSystem_0r.dmaBuffer; eventFifoSystem_0w.nextWord <= '1'; -- autoreset
						--when x"0102" => eventFifoSystem_0w.reset;
						when x"0104" => readDataBuffer <= eventFifoSystem_0r.eventFifoWordsDmaAligned;
						when x"0106" => readDataBuffer <= eventFifoSystem_0r.eventFifoWordsPerSlice;
						when x"0108" => readDataBuffer <= x"000" & "000" & eventFifoSystem_0r.irqStall;
						when x"010a" => readDataBuffer <= eventFifoSystem_0r.deviceId;
						
--						when x"0200" => readDataBuffer <= gpsTiming_0r.counterPeriod;
--						when x"0202" => readDataBuffer <= x"000" & "000" & gpsTiming_0r.newDataLatched;
--						when x"0204" => readDataBuffer <= gpsTiming_0r.differenceGpsToLocalClock;
--						when x"0206" => readDataBuffer <= gpsTiming_0r.week;
--						when x"0208" => readDataBuffer <= gpsTiming_0r.quantizationError(31 downto 16); -- sync!
--						when x"020a" => readDataBuffer <= gpsTiming_0r.quantizationError(15 downto 0);
--						when x"020c" => readDataBuffer <= gpsTiming_0r.timeOfWeekMilliSecond(31 downto 16); -- sync!
--						when x"020e" => readDataBuffer <= gpsTiming_0r.timeOfWeekMilliSecond(15 downto 0);
--						--when x"020" => readDataBuffer <= gpsTiming_0r.timeOfWeekSubMilliSecond(31 downto 16); -- sync!
--						--when x"020" => readDataBuffer <= gpsTiming_0r.timeOfWeekSubMilliSecond(15 downto 0);
						
--						when x"0300" => readDataBuffer <=  x"000" & "000" & tmp05_0r.busy; 
--						when x"0302" => readDataBuffer <= tmp05_0r.tl; tmp05_0r_thLatched <= tmp05_0r.th; 
--						when x"0304" => readDataBuffer <= tmp05_0r_thLatched;
--						when x"0306" => readDataBuffer <= tmp05_0r.debugCounter(15 downto 0);
--						when x"0308" => readDataBuffer <= x"00" & tmp05_0r.debugCounter(23 downto 16);
						
--						when x"0310" => readDataBuffer <= x"0" & ad56x1_0r.valueChip0;
--						when x"0312" => readDataBuffer <= x"0" & ad56x1_0r.valueChip1;
--						when x"0314" => readDataBuffer <= x"000" & "000" & ad56x1_0r.dacBusy;
					
						--when x"0400" => readDataBuffer <= x"000" & dac1_uvLogger_0r.debug;
						when x"0402" => readDataBuffer <= x"00" & dac1_uvLogger_0r.valuesChangedA;
						when x"0404" => readDataBuffer <= x"00" & dac1_uvLogger_0r.valuesChangedB;
						when x"0410" => readDataBuffer <= x"0" & dac1_uvLogger_0r.channelA(0);
						when x"0412" => readDataBuffer <= x"0" & dac1_uvLogger_0r.channelA(1);
						when x"0414" => readDataBuffer <= x"0" & dac1_uvLogger_0r.channelA(2);
						when x"0416" => readDataBuffer <= x"0" & dac1_uvLogger_0r.channelA(3);
						when x"0418" => readDataBuffer <= x"0" & dac1_uvLogger_0r.channelA(4);
						when x"041a" => readDataBuffer <= x"0" & dac1_uvLogger_0r.channelA(5);
						when x"041c" => readDataBuffer <= x"0" & dac1_uvLogger_0r.channelA(6);
						when x"041e" => readDataBuffer <= x"0" & dac1_uvLogger_0r.channelA(7);
						when x"0420" => readDataBuffer <= x"0" & dac1_uvLogger_0r.channelB(0);
						when x"0422" => readDataBuffer <= x"0" & dac1_uvLogger_0r.channelB(1);
						when x"0424" => readDataBuffer <= x"0" & dac1_uvLogger_0r.channelB(2);
						when x"0426" => readDataBuffer <= x"0" & dac1_uvLogger_0r.channelB(3);
						when x"0428" => readDataBuffer <= x"0" & dac1_uvLogger_0r.channelB(4);
						when x"042a" => readDataBuffer <= x"0" & dac1_uvLogger_0r.channelB(5);
						when x"042c" => readDataBuffer <= x"0" & dac1_uvLogger_0r.channelB(6);
						when x"042e" => readDataBuffer <= x"0" & dac1_uvLogger_0r.channelB(7);
						
--						when x"4000" => readDataBuffer <= x"000" & "000" & tmp10x_uvLogger_0r.busy;
--						when x"4002" => readDataBuffer <= tmp10x_uvLogger_0r.temperature;

						when x"4010" => readDataBuffer <= x"00" & i2c_genericBus_0r.data;
						when x"4016" => readDataBuffer <= x"000" & "000" & i2c_genericBus_0r.busy;
						when x"4020" => readDataBuffer <= x"00" & i2c_genericBus_1r.data;
						when x"4026" => readDataBuffer <= x"000" & "000" & i2c_genericBus_1r.busy;
						when x"4030" => readDataBuffer <= x"00" & i2c_genericBus_2r.data;
						when x"4036" => readDataBuffer <= x"000" & "000" & i2c_genericBus_2r.busy;
						when x"4040" => readDataBuffer <= x"00" & i2c_genericBus_3r.data;
						when x"4046" => readDataBuffer <= x"000" & "000" & i2c_genericBus_3r.busy;
						when x"4050" => readDataBuffer <= x"00" & i2c_genericBus_4r.data;
						when x"4056" => readDataBuffer <= x"000" & "000" & i2c_genericBus_4r.busy;
						when x"4060" => readDataBuffer <= x"00" & i2c_genericBus_5r.data;
						when x"4066" => readDataBuffer <= x"000" & "000" & i2c_genericBus_5r.busy;
						
						when x"4082" => readDataBuffer <= x"000" & "00" & ledFlasher_0r.enableGenerator;
						when x"4084" => readDataBuffer <= x"000" & "00" & ledFlasher_0r.useNegativePolarity;
						when x"4086" => readDataBuffer <= x"00" & ledFlasher_0r.pulseWidth0;
						when x"4088" => readDataBuffer <= x"00" & ledFlasher_0r.pulseWidth1;
						when x"408a" => readDataBuffer <= ledFlasher_0r.generatorPeriod0(31 downto 16);
						when x"408c" => readDataBuffer <= ledFlasher_0r.generatorPeriod0(15 downto 0);
						when x"408e" => readDataBuffer <= ledFlasher_0r.generatorPeriod1(31 downto 16);
						when x"4090" => readDataBuffer <= ledFlasher_0r.generatorPeriod1(15 downto 0);
						
						when x"40a0" => readDataBuffer <= x"000" & "000" & houseKeeping_0r.enablePcbLeds;
						when x"40a2" => readDataBuffer <= x"000" & "000" & houseKeeping_0r.enablePcbLedGreen;
						when x"40a4" => readDataBuffer <= x"000" & "000" & houseKeeping_0r.enablePcbLedRed;
						when x"40a6" => readDataBuffer <= x"000" & "000" & houseKeeping_0r.enableJ24TestPins;
						

--						when x"0402" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChangedChip0;
--						when x"0404" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChangedChip1;
--						when x"0406" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChangedChip2;
--						when x"0408" => readDataBuffer <= x"000" & "000" & dac088s085_x3_0r.dacBusy;
--						when x"0410" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip0(0);
--						when x"0412" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip0(1);
--						when x"0414" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip0(2);
--						when x"0416" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip0(3);
--						when x"0418" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip0(4);
--						when x"041a" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip0(5);
--						when x"041c" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip0(6);
--						when x"041e" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip0(7);
--						when x"0420" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip1(0);
--						when x"0422" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip1(1);
--						when x"0424" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip1(2);
--						when x"0426" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip1(3);
--						when x"0428" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip1(4);
--						when x"042a" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip1(5);
--						when x"042c" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip1(6);
--						when x"042e" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip1(7);
--						when x"0430" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip2(0);
--						when x"0432" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip2(1);
--						when x"0434" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip2(2);
--						when x"0436" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip2(3);
--						when x"0438" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip2(4);
--						when x"043a" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip2(5);
--						when x"043c" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip2(6);
--						when x"043e" => readDataBuffer <= x"00" & dac088s085_x3_0r.valuesChip2(7);

						when x"100c" => readDataBuffer <= triggerDataDelay_0r.numberOfDelayCycles;
						when x"100e" => readDataBuffer <= triggerDataDelay_1r.numberOfDelayCycles;
						
						when x"1100" => readDataBuffer <= eventFifoSystem_0r.packetConfig;
						when x"1102" => readDataBuffer <= eventFifoSystem_0r.eventsPerIrq;
						when x"1104" => readDataBuffer <= eventFifoSystem_0r.irqAtEventFifoWords;
						when x"1106" => readDataBuffer <= x"000" & "000" & eventFifoSystem_0r.enableIrq;
						when x"110c" => readDataBuffer <= x"000" & "000" & eventFifoSystem_0r.irqStall;
						when x"110e" => readDataBuffer <= eventFifoSystem_0r.eventFifoErrorCounter;
						when x"1110" => readDataBuffer <= eventFifoSystem_0r.eventRateCounter;
						when x"1112" => readDataBuffer <= eventFifoSystem_0r.eventLostRateCounter;
						
						when x"1010" => readDataBuffer <= triggerTimeToRisingEdge_0r.channel(0);
						when x"1012" => readDataBuffer <= triggerTimeToRisingEdge_0r.channel(1);
						when x"1014" => readDataBuffer <= triggerTimeToRisingEdge_0r.channel(2);
						when x"1016" => readDataBuffer <= triggerTimeToRisingEdge_0r.channel(3);
						when x"1018" => readDataBuffer <= triggerTimeToRisingEdge_0r.channel(4);
						when x"101a" => readDataBuffer <= triggerTimeToRisingEdge_0r.channel(5);
						when x"101c" => readDataBuffer <= triggerTimeToRisingEdge_0r.channel(6);
						when x"101e" => readDataBuffer <= triggerTimeToRisingEdge_0r.channel(7);
						--when x"1020" => readDataBuffer <= triggerTimeToRisingEdge_0r.timeout;
						
						--when x"0020" => readDataBuffer <= eventFifoSystem_0r.dmaBuffer; eventFifoSystem_0w.nextWord <= '1'; -- autoreset
						--when x"0022" => readDataBuffer <= eventFifoSystem_0r.eventFifoWordsDma32(15 downto 0); -- is not a real 32 bit value!!! and has to be locked
						--when x"0024" => readDataBuffer <= eventFifoSystem_0r.eventFifoWordsDma32(31 downto 16);
						--when x"0026" => readDataBuffer <= eventFifoSystem_0r.eventFifoWordsDma;
						--	eventFifoWordsDmaSlice_latched <= eventFifoSystem_0r.eventFifoWordsDmaSlice;
						--when x"0028" => readDataBuffer <= x"000" & eventFifoWordsDmaSlice_latched;
						--when x"0024" => readDataBuffer <= eventFifoSystem_0r.eventFifoWordsDmaAligned;
						--when x"0026" => readDataBuffer <= eventFifoSystem_0r.eventFifoWordsPerSlice;
						
						when x"1126" => readDataBuffer <= eventFifoSystem_0r.eventFifoFullCounter;
						when x"1128" => readDataBuffer <= eventFifoSystem_0r.eventFifoOverflowCounter;
						when x"112a" => readDataBuffer <= eventFifoSystem_0r.eventFifoUnderflowCounter;
						when x"112c" => readDataBuffer <= eventFifoSystem_0r.eventFifoWords;
						when x"112e" => readDataBuffer <= eventFifoSystem_0r.eventFifoFlags;						
						
						when x"1030" => readDataBuffer <= pixelRateCounter_0r.rateAllEdgesLatched(0);
						when x"1032" => readDataBuffer <= pixelRateCounter_0r.rateAllEdgesLatched(1);
						when x"1034" => readDataBuffer <= pixelRateCounter_0r.rateAllEdgesLatched(2);
						when x"1036" => readDataBuffer <= pixelRateCounter_0r.rateAllEdgesLatched(3);
						when x"1038" => readDataBuffer <= pixelRateCounter_0r.rateAllEdgesLatched(4);
						when x"103a" => readDataBuffer <= pixelRateCounter_0r.rateAllEdgesLatched(5);
						when x"103c" => readDataBuffer <= pixelRateCounter_0r.rateAllEdgesLatched(6);
						when x"103e" => readDataBuffer <= pixelRateCounter_0r.rateAllEdgesLatched(7);
						
						when x"1140" => readDataBuffer <= pixelRateCounter_0r.rateFirstHitsDuringGateLatched(0);
						when x"1142" => readDataBuffer <= pixelRateCounter_0r.rateFirstHitsDuringGateLatched(1);
						when x"1144" => readDataBuffer <= pixelRateCounter_0r.rateFirstHitsDuringGateLatched(2);
						when x"1146" => readDataBuffer <= pixelRateCounter_0r.rateFirstHitsDuringGateLatched(3);
						when x"1148" => readDataBuffer <= pixelRateCounter_0r.rateFirstHitsDuringGateLatched(4);
						when x"114a" => readDataBuffer <= pixelRateCounter_0r.rateFirstHitsDuringGateLatched(5);
						when x"114c" => readDataBuffer <= pixelRateCounter_0r.rateFirstHitsDuringGateLatched(6);
						when x"114e" => readDataBuffer <= pixelRateCounter_0r.rateFirstHitsDuringGateLatched(7);
						when x"1150" => readDataBuffer <= pixelRateCounter_0r.rateAdditionalHitsDuringGateLatched(0);
						when x"1152" => readDataBuffer <= pixelRateCounter_0r.rateAdditionalHitsDuringGateLatched(1);
						when x"1154" => readDataBuffer <= pixelRateCounter_0r.rateAdditionalHitsDuringGateLatched(2);
						when x"1156" => readDataBuffer <= pixelRateCounter_0r.rateAdditionalHitsDuringGateLatched(3);
						when x"1158" => readDataBuffer <= pixelRateCounter_0r.rateAdditionalHitsDuringGateLatched(4);
						when x"115a" => readDataBuffer <= pixelRateCounter_0r.rateAdditionalHitsDuringGateLatched(5);
						when x"115c" => readDataBuffer <= pixelRateCounter_0r.rateAdditionalHitsDuringGateLatched(6);
						when x"115e" => readDataBuffer <= pixelRateCounter_0r.rateAdditionalHitsDuringGateLatched(7);
						--when x"1160" => readDataBuffer <= pixelRateCounter_0r.pixelCounterDebugLatched(0);
						--when x"1162" => readDataBuffer <= pixelRateCounter_0r.pixelCounterDebugLatched(1);
						--when x"1164" => readDataBuffer <= pixelRateCounter_0r.pixelCounterDebugLatched(2);
						--when x"1166" => readDataBuffer <= pixelRateCounter_0r.pixelCounterDebugLatched(3);
						--when x"1168" => readDataBuffer <= pixelRateCounter_0r.pixelCounterDebugLatched(4);
						--when x"116a" => readDataBuffer <= pixelRateCounter_0r.pixelCounterDebugLatched(5);
						--when x"116c" => readDataBuffer <= pixelRateCounter_0r.pixelCounterDebugLatched(6);
						--when x"116e" => readDataBuffer <= pixelRateCounter_0r.pixelCounterDebugLatched(7);
						
						when x"1042" => readDataBuffer <= pixelRateCounter_0r.rateCounterPeriod;
						--when x"1044" => readDataBuffer <= x"000" & "000" & pixelRateCounter_0r.doublePulsePrevention;
						when x"1046" => readDataBuffer <= triggerLogic_0r.gateTime;
						when x"1048" => readDataBuffer <= x"000" & "000" & pixelRateCounter_0r.newData;
						
						when x"10a2" => readDataBuffer <= x"0" & "00" & drs4_0r.regionOfInterest;
						when x"10a6" => readDataBuffer <= drs4_0r.numberOfSamplesToRead;
						when x"10a8" => readDataBuffer <= x"000" & drs4_0r.sampleMode;
						when x"10aa" => readDataBuffer <= x"000" & drs4_0r.readoutMode;
						when x"10ac" => readDataBuffer <= x"00" & drs4_0r.writeShiftRegister;
						when x"10ae" => readDataBuffer <= x"00" & drs4_0r.cascadingDataDebug;
						
						when x"10b0" => readDataBuffer <= x"000" & ltm9007_14_0r.testMode;
						when x"10b2" => readDataBuffer <= "00" & ltm9007_14_0r.testPattern;
						when x"10b4" => readDataBuffer <= x"000" & "00" & ltm9007_14_0r.bitslipFailed;
						when x"10b6" => readDataBuffer <= x"00" & "0" & ltm9007_14_0r.bitslipPattern;
						--when x"10c0" => readDataBuffer <= "00" & ltm9007_14_0r.fifoA(13+0*14 downto 0+0*14);
						--when x"10c2" => readDataBuffer <= "00" & ltm9007_14_0r.fifoB(13+0*14 downto 0+0*14);
						--when x"10c4" => readDataBuffer <= "00" & ltm9007_14_0r.fifoA(13+1*14 downto 0+1*14);
						--when x"10c6" => readDataBuffer <= "00" & ltm9007_14_0r.fifoB(13+1*14 downto 0+1*14);
						--when x"10c8" => readDataBuffer <= "00" & ltm9007_14_0r.fifoA(13+2*14 downto 0+2*14);
						--when x"10ca" => readDataBuffer <= "00" & ltm9007_14_0r.fifoB(13+2*14 downto 0+2*14);
						--when x"10cc" => readDataBuffer <= "00" & ltm9007_14_0r.fifoA(13+3*14 downto 0+3*14);
						--when x"10ce" => readDataBuffer <= "00" & ltm9007_14_0r.fifoB(13+3*14 downto 0+3*14);
						
						when x"11d0" => readDataBuffer <= x"0" & "00" & triggerLogic_0r.triggerSerdesDelay;
						when x"11d4" => readDataBuffer <= x"00" & triggerLogic_0r.triggerMask;
						when x"11d6" => readDataBuffer <= x"000" & "000" &  triggerLogic_0r.singleSeq;
						when x"11d8" => readDataBuffer <= x"000" & "000" &  triggerLogic_0r.triggerGeneratorEnabled;
						when x"11da" => readDataBuffer <= std_logic_vector(triggerLogic_0r.triggerGeneratorPeriod(15 downto 0));
						when x"11dc" => readDataBuffer <= std_logic_vector(triggerLogic_0r.triggerGeneratorPeriod(31 downto 16));
						--when x"11e0" => readDataBuffer <= triggerLogic_0r.counterPeriod;
						--when x"11e2" => readDataBuffer <= triggerLogic_0r.rate;
						--when x"11e4" => readDataBuffer <= triggerLogic_0r.rateLatched;
						--when x"11e6" => readDataBuffer <= triggerLogic_0r.rateDeadTimeLatched;
						--when x"11e8" => readDataBuffer <= x"0" & triggerLogic_0r.sameEventTime;
						when x"11ea" => readDataBuffer <= x"0" & "000" & triggerLogic_0r.drs4TriggerDelay;
						when x"11ec" => readDataBuffer <= triggerLogic_0r.drs4Decimator;

						when x"10e0" => readDataBuffer <= x"00" & ltm9007_14_0r.offsetCorrectionRamWrite;
						when x"10e2" => readDataBuffer <= "000000" & ltm9007_14_0r.offsetCorrectionRamAddress;
						--when x"10e4" => readDataBuffer <= x"00" & actualOffsetCorrectionRamValue;
						when x"10e4" => readDataBuffer <= ltm9007_14_0r.offsetCorrectionRamData(0); -- ## and 1..7 ?!
						when x"10e6" => readDataBuffer <= "000000" & ltm9007_14_0r.baselineStart;
						when x"10e8" => readDataBuffer <= "000000" & ltm9007_14_0r.baselineEnd;
						
--						when x"10f0" => readDataBuffer <= x"00" & iceTad_0r.powerOn;
--						when x"1300" => readDataBuffer <= x"00" & iceTad_0r.rs485FifoData(0);
--						when x"1302" => readDataBuffer <= x"00" & iceTad_0r.rs485FifoData(1);
--						when x"1304" => readDataBuffer <= x"00" & iceTad_0r.rs485FifoData(2);
--						when x"1306" => readDataBuffer <= x"00" & iceTad_0r.rs485FifoData(3);
--						when x"1308" => readDataBuffer <= x"00" & iceTad_0r.rs485FifoData(4);
--						when x"130a" => readDataBuffer <= x"00" & iceTad_0r.rs485FifoData(5);
--						when x"130c" => readDataBuffer <= x"00" & iceTad_0r.rs485FifoData(6);
--						when x"130e" => readDataBuffer <= x"00" & iceTad_0r.rs485FifoData(7);
--						when x"1310" => readDataBuffer <= x"00" & iceTad_0r.rs485TxBusy;
--						when x"1312" => readDataBuffer <= x"00" & iceTad_0r.rs485RxBusy;
--						when x"1314" => readDataBuffer <= x"00" & iceTad_0r.rs485FifoFull;
--						when x"1316" => readDataBuffer <= x"00" & iceTad_0r.rs485FifoEmpty;
--						when x"131c" => readDataBuffer <= x"00" & iceTad_0r.softTxEnable;
--						when x"131e" => readDataBuffer <= x"00" & iceTad_0r.softTxMask;
--						when x"1320" => readDataBuffer <= x"00" & iceTad_0r.rs485FifoWords(0); 
--						when x"1322" => readDataBuffer <= x"00" & iceTad_0r.rs485FifoWords(1);
--						when x"1324" => readDataBuffer <= x"00" & iceTad_0r.rs485FifoWords(2);
--						when x"1326" => readDataBuffer <= x"00" & iceTad_0r.rs485FifoWords(3);
--						when x"1328" => readDataBuffer <= x"00" & iceTad_0r.rs485FifoWords(4);
--						when x"132a" => readDataBuffer <= x"00" & iceTad_0r.rs485FifoWords(5);
--						when x"132c" => readDataBuffer <= x"00" & iceTad_0r.rs485FifoWords(6);
--						when x"132e" => readDataBuffer <= x"00" & iceTad_0r.rs485FifoWords(7);
						
--						when x"1400" => readDataBuffer <= x"000" & "000" & whiteRabbitTiming_0r.newDataLatched;
--							whiteRabbitTiming_0r_irigDataLatched <= whiteRabbitTiming_0r.irigDataLatched;
--							whiteRabbitTiming_0r_irigBinaryYearsLatched <= whiteRabbitTiming_0r.irigBinaryYearsLatched;
--							whiteRabbitTiming_0r_irigBinaryDaysLatched <= whiteRabbitTiming_0r.irigBinaryDaysLatched;
--							whiteRabbitTiming_0r_irigBinarySecondsLatched <= whiteRabbitTiming_0r.irigBinarySecondsLatched;
--						when x"1402" => readDataBuffer <= "0" & whiteRabbitTiming_0r_irigDataLatched(15 downto 13)
--															& whiteRabbitTiming_0r_irigDataLatched(11 downto 8) -- min
--															& "0" & whiteRabbitTiming_0r_irigDataLatched(7 downto 5)
--															& whiteRabbitTiming_0r_irigDataLatched(3 downto 0); -- sec
--						when x"1404" => readDataBuffer <= x"00" & "00" & whiteRabbitTiming_0r_irigDataLatched(23 downto 22)
--															& whiteRabbitTiming_0r_irigDataLatched(20 downto 17); -- hour
--						when x"1406" => readDataBuffer <= x"0" & "00" &  whiteRabbitTiming_0r_irigDataLatched(36 downto 35)
--															& whiteRabbitTiming_0r_irigDataLatched(34 downto 31)
--															& whiteRabbitTiming_0r_irigDataLatched(29 downto 26); -- day
--						when x"1408" => readDataBuffer <= x"00" & whiteRabbitTiming_0r_irigDataLatched(52 downto 49)
--															& whiteRabbitTiming_0r_irigDataLatched(47 downto 44); --year
--						when x"140a" => readDataBuffer <= whiteRabbitTiming_0r_irigBinarySecondsLatched(15 downto 0); -- binary sec of day
--						--when x"040a" => readDataBuffer <= whiteRabbitTiming_0r_irigBinarySecondsLatched(16); -- binary sec of day
--						when x"140c" => readDataBuffer <= whiteRabbitTiming_0r_irigBinarySecondsLatched(16) & x"0" & "00" & whiteRabbitTiming_0r_irigBinaryDaysLatched; 
--						when x"140e" => readDataBuffer <= x"00" & "0" & whiteRabbitTiming_0r_irigBinaryYearsLatched; 
--						
--						when x"1410" => readDataBuffer <= whiteRabbitTiming_0r_irigDataLatched(15 downto 0); 
--						when x"1412" => readDataBuffer <= whiteRabbitTiming_0r_irigDataLatched(31 downto 16);
--						when x"1414" => readDataBuffer <= whiteRabbitTiming_0r_irigDataLatched(47 downto 32);
--						when x"1416" => readDataBuffer <= whiteRabbitTiming_0r_irigDataLatched(63 downto 48);
--						when x"1418" => readDataBuffer <= whiteRabbitTiming_0r_irigDataLatched(79 downto 64);
--						when x"141a" => readDataBuffer <= "0000000" & whiteRabbitTiming_0r_irigDataLatched(88 downto 80);
--						when x"141c" => readDataBuffer <= x"00" & whiteRabbitTiming_0r.bitCounter;
--						when x"141e" => readDataBuffer <= whiteRabbitTiming_0r.errorCounter;
--						when x"1420" => readDataBuffer <= whiteRabbitTiming_0r.counterPeriod;
						
						when x"f000" => readDataBuffer <= x"000" & "000" & ltm9007_14_0r.fifoEmptyA;
						when x"f002" => readDataBuffer <= x"000" & "000" & ltm9007_14_0r.fifoValidA;
						when x"f004" => readDataBuffer <= x"00" & ltm9007_14_0r.fifoWordsA;
						--when x"f006" => readDataBuffer <= x"00" & ltm9007_14_0r.fifoWordsA2; -- sync?!
						
						--when x"f0d0" => readDataBuffer <= x"00" & triggerLogic_0r.trigger.triggerSerdesDelayed;
						--when x"f0d2" => readDataBuffer <= x"00" & triggerLogic_0r.trigger.triggerSerdesNotDelayed;
						--when x"f0d4" => readDataBuffer <= x"000" & "000" & triggerLogic_0r.trigger.triggerDelayed;
						--when x"f0d6" => readDataBuffer <= x"000" & "000" & triggerLogic_0r.trigger.triggerNotDelayed;
						
						when x"d000" => readDataBuffer <= x"0666"; --commDebug_0r.tx_baud_div;
						when x"d002" => readDataBuffer <= x"0666"; --commDebug_0r.dU_1mV;
						when x"d004" => readDataBuffer <= x"0666"; --commDebug_0r.com_adc_thr;
					
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
