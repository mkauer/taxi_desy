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

entity registerInterfacePolarstern is
	generic 
	(
		subAddress : std_logic_vector(15 downto 0) := x"0000";
		subAddressMask : std_logic_vector(15 downto 0) := x"FF00";
		moduleEnabled : integer := 1
	);
	port
	(
		addressAndControlBus : in std_logic_vector(31 downto 0);
		dataBusIn : in std_logic_vector(15 downto 0);
		dataBusOut : out std_logic_vector(15 downto 0);

		triggerTimeToEdge_0r : in triggerTimeToEdge_registerRead_t;
		triggerTimeToEdge_0w : out triggerTimeToEdge_registerWrite_t;
	--	triggerTimeToRisingEdge_0r : in triggerTimeToRisingEdge_registerRead_t;
	--	triggerTimeToRisingEdge_0w : out triggerTimeToRisingEdge_registerWrite_t;
	--	triggerTimeToRisingEdge_1r : in triggerTimeToRisingEdge_registerRead_t;
	--	triggerTimeToRisingEdge_1w : out triggerTimeToRisingEdge_registerWrite_t;
		eventFifoSystem_0r : in eventFifoSystem_registerRead_t;
		eventFifoSystem_0w : out eventFifoSystem_registerWrite_t;
		triggerDataDelay_0r : in triggerDataDelay_registerRead_t;
		triggerDataDelay_0w : out triggerDataDelay_registerWrite_t;
		pixelRateCounter_0r : in pixelRateCounter_registerRead_t;
		pixelRateCounter_0w : out pixelRateCounter_registerWrite_t;
		pixelRateCounter_1r : in pixelRateCounter_registerRead_t;
		pixelRateCounter_1w : out pixelRateCounter_registerWrite_t;
		dac088s085_x3_0r : in dac088s085_x3_registerRead_t;
		dac088s085_x3_0w : out dac088s085_x3_registerWrite_t;
		gpsTiming_0r : in gpsTiming_registerRead_t;
		gpsTiming_0w : out gpsTiming_registerWrite_t;
		ad56x1_0r : in ad56x1_registerRead_t;
		ad56x1_0w : out ad56x1_registerWrite_t;
		drs4_0r : in drs4_registerRead_t;
		drs4_0w : out drs4_registerWrite_t
	);
end registerInterfacePolarstern;

architecture behavior of registerInterfacePolarstern is

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
	
begin

g0: if moduleEnabled /= 0 generate
	controlBus <= smc_vectorToBus(addressAndControlBus);
	chipSelectInternal <= '1' when ((controlBus.chipSelect = '1') and ((controlBus.address(15 downto 0) and subAddressMask) = subAddress)) else '0';
--	dataBusWrite <= '1' when ((chipSelectInternal = '1') and (controlBus.read = '1')) else '0';
	dataBusOut <= readDataBuffer;	
	
	triggerTimeToEdge_0w.clock <= controlBus.clock;
	triggerTimeToEdge_0w.reset <= controlBus.reset;
	--triggerTimeToRisingEdge_0w.clock <= controlBus.clock;
	--triggerTimeToRisingEdge_0w.reset <= controlBus.reset;
	--triggerTimeToRisingEdge_1w.clock <= controlBus.clock;
	--triggerTimeToRisingEdge_1w.reset <= controlBus.reset;
	eventFifoSystem_0w.clock <= controlBus.clock;
	eventFifoSystem_0w.reset <= controlBus.reset or debugReset;
	eventFifoSystem_0w.eventFifoClear <= eventFifoClear;
	triggerDataDelay_0w.clock <= controlBus.clock;
	triggerDataDelay_0w.reset <= controlBus.reset;
	pixelRateCounter_0w.clock <= controlBus.clock;
	pixelRateCounter_0w.reset <= controlBus.reset;
	pixelRateCounter_1w.clock <= controlBus.clock;
	pixelRateCounter_1w.reset <= controlBus.reset;
	dac088s085_x3_0w.clock <= controlBus.clock;
	dac088s085_x3_0w.reset <= controlBus.reset;
	gpsTiming_0w.clock <= controlBus.clock;
	gpsTiming_0w.reset <= controlBus.reset;
	ad56x1_0w.clock <= controlBus.clock;
	ad56x1_0w.reset <= controlBus.reset;
	drs4_0w.clock <= controlBus.clock;
	drs4_0w.reset <= controlBus.reset;
	
	dac088s085_x3_0w.valuesChangedChip0 <= valuesChangedChip0Temp;
	dac088s085_x3_0w.valuesChangedChip1 <= valuesChangedChip1Temp;
	dac088s085_x3_0w.valuesChangedChip2 <= valuesChangedChip2Temp;
	
	P0:process (controlBus.clock)
	begin
		if rising_edge(controlBus.clock) then
			eventFifoSystem_0w.nextWord <= '0'; -- autoreset
			triggerDataDelay_0w.resetDelay <= '0'; -- autoreset
			pixelRateCounter_0w.resetCounter <= (others=>'0'); -- autoreset
			pixelRateCounter_1w.resetCounter <= (others=>'0'); -- autoreset
			debugReset <= '0'; -- autoreset
			eventFifoClear <= '0'; -- autoreset
			dac088s085_x3_0w.init <= '0'; -- autoreset
			--ad56x1_0w.init <= '0'; -- autoreset
			ad56x1_0w.valueChangedChip0 <= '0'; -- autoreset
			ad56x1_0w.valueChangedChip1 <= '0'; -- autoreset
			drs4_0w.stoftTrigger <= '0'; -- autoreset
			drs4_0w.resetStates <= '0'; -- autoreset
			if (controlBus.reset = '1') then
				registerA <= (others => '0');
				registerb <= (others => '0');
				triggerDataDelay_0w.numberOfDelayCycles <= x"0004";
				triggerDataDelay_0w.resetDelay <= '1';
				valuesChangedChip0Temp <= x"00";
				valuesChangedChip1Temp <= x"00";
				valuesChangedChip2Temp <= x"00";
				ad56x1_0w.valueChip0 <= x"800";
				ad56x1_0w.valueChip1 <= x"800";
				--ad56x1_0w.init <= '1';
				ad56x1_0w.valueChangedChip0 <= '1'; -- autoreset
				ad56x1_0w.valueChangedChip1 <= '1'; -- autoreset
				eventFifoSystem_0w.packetConfig <= x"000f";
				eventFifoSystem_0w.registerSamplesToRead <= x"0001";
			else
				valuesChangedChip0Temp <= valuesChangedChip0Temp and not(dac088s085_x3_0r.valuesChangedChip0Reset); -- ## move to module.....
				valuesChangedChip1Temp <= valuesChangedChip1Temp and not(dac088s085_x3_0r.valuesChangedChip1Reset);
				valuesChangedChip2Temp <= valuesChangedChip2Temp and not(dac088s085_x3_0r.valuesChangedChip2Reset);
				
				if ((controlBus.writeStrobe = '1') and (controlBus.readStrobe = '0') and (chipSelectInternal = '1')) then
					case (controlBus.address(15 downto 0) and not(subAddressMask)) is
						when x"0000" => registerA <= dataBusIn(7 downto 0);
						when x"0002" => registerB <= dataBusIn;
						
						when x"0004" => eventFifoSystem_0w.packetConfig <= dataBusIn;
						when x"0008" => eventFifoSystem_0w.registerSamplesToRead <= dataBusIn;
											
						when x"0022" => eventFifoClear <= '1'; -- autoreset
						when x"002c" => debugReset <= '1'; -- autoreset
						when x"002e" => triggerDataDelay_0w.numberOfDelayCycles <= dataBusIn; triggerDataDelay_0w.resetDelay <= '1'; -- autoreset
					
						when x"0130" => pixelRateCounter_0w.resetCounter <= dataBusIn; -- autoreset
						when x"0140" => pixelRateCounter_1w.resetCounter <= dataBusIn; -- autoreset
						
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
						
						when x"00a0" => drs4_0w.stoftTrigger <= '1'; -- autoreset
						when x"00a4" => drs4_0w.resetStates <= '1'; -- autoreset
						
						when others => null;
					end case;
				elsif ((controlBus.readStrobe = '1') and (controlBus.writeStrobe = '0') and (chipSelectInternal = '1')) then	
					case (controlBus.address(15 downto 0) and not(subAddressMask)) is
						when x"0000" => readDataBuffer <= x"00"&registerA;
						when x"0002" => readDataBuffer <= registerB;
						
						when x"0004" => readDataBuffer <= eventFifoSystem_0r.packetConfig;
						when x"0006" => readDataBuffer <= eventFifoSystem_0r.eventFifoErrorCounter;						
						when x"0008" => readDataBuffer <= eventFifoSystem_0r.registerSamplesToRead;						
						
						when x"0100" => readDataBuffer <= triggerTimeToEdge_0r.timeToRisingEdge(0);
						when x"0102" => readDataBuffer <= triggerTimeToEdge_0r.timeToRisingEdge(1);
						when x"0104" => readDataBuffer <= triggerTimeToEdge_0r.timeToRisingEdge(2);
						when x"0106" => readDataBuffer <= triggerTimeToEdge_0r.timeToRisingEdge(3);
						when x"0108" => readDataBuffer <= triggerTimeToEdge_0r.timeToRisingEdge(4);
						when x"010a" => readDataBuffer <= triggerTimeToEdge_0r.timeToRisingEdge(5);
						when x"010c" => readDataBuffer <= triggerTimeToEdge_0r.timeToRisingEdge(6);
						when x"010e" => readDataBuffer <= triggerTimeToEdge_0r.timeToRisingEdge(7);
						when x"0110" => readDataBuffer <= triggerTimeToEdge_0r.timeToRisingEdge(8);
						when x"0112" => readDataBuffer <= triggerTimeToEdge_0r.timeToRisingEdge(9);
						when x"0114" => readDataBuffer <= triggerTimeToEdge_0r.timeToRisingEdge(10);
						when x"0116" => readDataBuffer <= triggerTimeToEdge_0r.timeToRisingEdge(11);
						when x"0118" => readDataBuffer <= triggerTimeToEdge_0r.timeToRisingEdge(12);
						when x"011a" => readDataBuffer <= triggerTimeToEdge_0r.timeToRisingEdge(13);
						when x"011c" => readDataBuffer <= triggerTimeToEdge_0r.timeToRisingEdge(14);
						when x"011e" => readDataBuffer <= triggerTimeToEdge_0r.timeToRisingEdge(15);
						
						when x"0140" => readDataBuffer <= triggerTimeToEdge_0r.timeToFallingEdge(0);
						when x"0142" => readDataBuffer <= triggerTimeToEdge_0r.timeToFallingEdge(1);
						when x"0144" => readDataBuffer <= triggerTimeToEdge_0r.timeToFallingEdge(2);
						when x"0146" => readDataBuffer <= triggerTimeToEdge_0r.timeToFallingEdge(3);
						when x"0148" => readDataBuffer <= triggerTimeToEdge_0r.timeToFallingEdge(4);
						when x"014a" => readDataBuffer <= triggerTimeToEdge_0r.timeToFallingEdge(5);
						when x"014c" => readDataBuffer <= triggerTimeToEdge_0r.timeToFallingEdge(6);
						when x"014e" => readDataBuffer <= triggerTimeToEdge_0r.timeToFallingEdge(7);
						when x"0150" => readDataBuffer <= triggerTimeToEdge_0r.timeToFallingEdge(8);
						when x"0152" => readDataBuffer <= triggerTimeToEdge_0r.timeToFallingEdge(9);
						when x"0154" => readDataBuffer <= triggerTimeToEdge_0r.timeToFallingEdge(10);
						when x"0156" => readDataBuffer <= triggerTimeToEdge_0r.timeToFallingEdge(11);
						when x"0158" => readDataBuffer <= triggerTimeToEdge_0r.timeToFallingEdge(12);
						when x"015a" => readDataBuffer <= triggerTimeToEdge_0r.timeToFallingEdge(13);
						when x"015c" => readDataBuffer <= triggerTimeToEdge_0r.timeToFallingEdge(14);
						when x"015e" => readDataBuffer <= triggerTimeToEdge_0r.timeToFallingEdge(15);

				--		when x"0100" => readDataBuffer <= triggerTimeToRisingEdge_0r.ch0;
				--		when x"0102" => readDataBuffer <= triggerTimeToRisingEdge_0r.ch1;
				--		when x"0104" => readDataBuffer <= triggerTimeToRisingEdge_0r.ch2;
				--		when x"0106" => readDataBuffer <= triggerTimeToRisingEdge_0r.ch3;
				--		when x"0108" => readDataBuffer <= triggerTimeToRisingEdge_0r.ch4;
				--		when x"010a" => readDataBuffer <= triggerTimeToRisingEdge_0r.ch5;
				--		when x"010c" => readDataBuffer <= triggerTimeToRisingEdge_0r.ch6;
				--		when x"010e" => readDataBuffer <= triggerTimeToRisingEdge_0r.ch7;
						
				--		when x"0110" => readDataBuffer <= triggerTimeToRisingEdge_1r.ch0;
				--		when x"0112" => readDataBuffer <= triggerTimeToRisingEdge_1r.ch1;
				--		when x"0114" => readDataBuffer <= triggerTimeToRisingEdge_1r.ch2;
				--		when x"0116" => readDataBuffer <= triggerTimeToRisingEdge_1r.ch3;
				--		when x"0118" => readDataBuffer <= triggerTimeToRisingEdge_1r.ch4;
				--		when x"011a" => readDataBuffer <= triggerTimeToRisingEdge_1r.ch5;
				--		when x"011c" => readDataBuffer <= triggerTimeToRisingEdge_1r.ch6;
				--		when x"011e" => readDataBuffer <= triggerTimeToRisingEdge_1r.ch7;
						
						when x"0020" => readDataBuffer <= eventFifoSystem_0r.dmaBuffer; eventFifoSystem_0w.nextWord <= '1'; -- autoreset
						when x"0022" => readDataBuffer <= eventFifoSystem_0r.eventFifoWordsDma;
						when x"0024" => readDataBuffer <= eventFifoSystem_0r.eventFifoFullCounter;
						when x"0026" => readDataBuffer <= eventFifoSystem_0r.eventFifoOverflowCounter;
						when x"0028" => readDataBuffer <= eventFifoSystem_0r.eventFifoUnderflowCounter;
						when x"002a" => readDataBuffer <= eventFifoSystem_0r.eventFifoWords;
						when x"002c" => readDataBuffer <= eventFifoSystem_0r.eventFifoFlags;						
						
						when x"002e" => readDataBuffer <= triggerDataDelay_0r.numberOfDelayCycles;
						
						when x"0180" => readDataBuffer <= pixelRateCounter_0r.ch0;
						when x"0182" => readDataBuffer <= pixelRateCounter_0r.ch1;
						when x"0184" => readDataBuffer <= pixelRateCounter_0r.ch2;
						when x"0186" => readDataBuffer <= pixelRateCounter_0r.ch3;
						when x"0188" => readDataBuffer <= pixelRateCounter_0r.ch4;
						when x"018a" => readDataBuffer <= pixelRateCounter_0r.ch5;
						when x"018c" => readDataBuffer <= pixelRateCounter_0r.ch6;
						when x"018e" => readDataBuffer <= pixelRateCounter_0r.ch7;
						
						when x"0190" => readDataBuffer <= pixelRateCounter_1r.ch0;
						when x"0192" => readDataBuffer <= pixelRateCounter_1r.ch1;
						when x"0194" => readDataBuffer <= pixelRateCounter_1r.ch2;
						when x"0196" => readDataBuffer <= pixelRateCounter_1r.ch3;
						when x"0198" => readDataBuffer <= pixelRateCounter_1r.ch4;
						when x"019a" => readDataBuffer <= pixelRateCounter_1r.ch5;
						when x"019c" => readDataBuffer <= pixelRateCounter_1r.ch6;
						when x"019e" => readDataBuffer <= pixelRateCounter_1r.ch7;
						
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
						
--						when others  => readDataBuffer <= (others => '0');
						when others  => readDataBuffer <= x"dead";
					end case;
				end if;
			end if;
		end if;
	end process P0;
	
	
end generate g0;
end behavior;
