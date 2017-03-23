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

entity testRam_test is
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

		triggerTimeToRisingEdge0_r : in triggerTimeToRisingEdge_registerRead_t;
		triggerTimeToRisingEdge0_w : out triggerTimeToRisingEdge_registerWrite_t;
		eventFifoSystem0_r : in eventFifoSystem_registerRead_t;
		eventFifoSystem0_w : out eventFifoSystem_registerWrite_t;
		triggerDataDelay0_r : in triggerDataDelay_registerRead_t;
		triggerDataDelay0_w : out triggerDataDelay_registerWrite_t;
		pixelRateCounter0_r : in pixelRateCounter_registerRead_t;
		pixelRateCounter0_w : out pixelRateCounter_registerWrite_t;
		dac088s085_x3_r : in dac088s085_x3_registerRead_t;
		dac088s085_x3_w : out dac088s085_x3_registerWrite_t;
		gpsTiming0_r : in gpsTiming_registerRead_t;
		gpsTiming0_w : out gpsTiming_registerWrite_t
	);
end testRam_test;

architecture behavior of testRam_test is

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
	
	triggerTimeToRisingEdge0_w.clock <= controlBus.clock;
	triggerTimeToRisingEdge0_w.reset <= controlBus.reset;
	eventFifoSystem0_w.clock <= controlBus.clock;
	eventFifoSystem0_w.reset <= controlBus.reset or debugReset;
	eventFifoSystem0_w.eventFifoClear <= eventFifoClear;
	triggerDataDelay0_w.clock <= controlBus.clock;
	triggerDataDelay0_w.reset <= controlBus.reset;
	pixelRateCounter0_w.clock <= controlBus.clock;
	pixelRateCounter0_w.reset <= controlBus.reset;
	dac088s085_x3_w.clock <= controlBus.clock;
	dac088s085_x3_w.reset <= controlBus.reset;
	gpsTiming0_w.clock <= controlBus.clock;
	gpsTiming0_w.reset <= controlBus.reset;
	
	dac088s085_x3_w.valuesChangedChip0 <= valuesChangedChip0Temp;
	dac088s085_x3_w.valuesChangedChip1 <= valuesChangedChip1Temp;
	dac088s085_x3_w.valuesChangedChip2 <= valuesChangedChip2Temp;
	
	P0:process (controlBus.clock)
	begin
		if rising_edge(controlBus.clock) then
			eventFifoSystem0_w.nextWord <= '0'; -- autoreset
			triggerDataDelay0_w.resetDelay <= '0'; -- autoreset
			pixelRateCounter0_w.resetCounter <= (others=>'0'); -- autoreset
			debugReset <= '0'; -- autoreset
			eventFifoClear <= '0'; -- autoreset
			dac088s085_x3_w.init <= '0'; -- autoreset
			if (controlBus.reset = '1') then
				registerA <= (others => '0');
				registerb <= (others => '0');
				triggerDataDelay0_w.numberOfDelayCycles <= x"0004";
				triggerDataDelay0_w.resetDelay <= '1';
				valuesChangedChip0Temp <= x"00";
				valuesChangedChip1Temp <= x"00";
				valuesChangedChip2Temp <= x"00";
			else
				valuesChangedChip0Temp <= valuesChangedChip0Temp and not(dac088s085_x3_r.valuesChangedChip0Reset); -- ## move to module.....
				valuesChangedChip1Temp <= valuesChangedChip1Temp and not(dac088s085_x3_r.valuesChangedChip1Reset);
				valuesChangedChip2Temp <= valuesChangedChip2Temp and not(dac088s085_x3_r.valuesChangedChip2Reset);
				
				if ((controlBus.writeStrobe = '1') and (controlBus.readStrobe = '0') and (chipSelectInternal = '1')) then
					case (controlBus.address(15 downto 0) and not(subAddressMask)) is
						when x"0000" => registerA <= dataBusIn(7 downto 0);
						when x"0002" => registerB <= dataBusIn;
						
						when x"0004" => eventFifoSystem0_w.packetConfig <= dataBusIn;
						
						when x"0022" => eventFifoClear <= '1'; -- autoreset
						when x"002c" => debugReset <= '1'; -- autoreset
						when x"002e" => triggerDataDelay0_w.numberOfDelayCycles <= dataBusIn; triggerDataDelay0_w.resetDelay <= '1'; -- autoreset
					
						when x"0030" => pixelRateCounter0_w.resetCounter <= dataBusIn; -- autoreset
						
						when x"0048" => dac088s085_x3_w.init <= '1'; -- autoreset
						when x"004a" => valuesChangedChip0Temp <= dataBusIn(7 downto 0);
						when x"004c" => valuesChangedChip1Temp <= dataBusIn(7 downto 0);
						when x"004e" => valuesChangedChip2Temp <= dataBusIn(7 downto 0);
						when x"0050" => dac088s085_x3_w.valuesChip0(0) <= dataBusIn(7 downto 0); valuesChangedChip0Temp(0) <= '1';
						when x"0052" => dac088s085_x3_w.valuesChip0(1) <= dataBusIn(7 downto 0); valuesChangedChip0Temp(1) <= '1';
						when x"0054" => dac088s085_x3_w.valuesChip0(2) <= dataBusIn(7 downto 0); valuesChangedChip0Temp(2) <= '1';
						when x"0056" => dac088s085_x3_w.valuesChip0(3) <= dataBusIn(7 downto 0); valuesChangedChip0Temp(3) <= '1';
						when x"0058" => dac088s085_x3_w.valuesChip0(4) <= dataBusIn(7 downto 0); valuesChangedChip0Temp(4) <= '1';
						when x"005a" => dac088s085_x3_w.valuesChip0(5) <= dataBusIn(7 downto 0); valuesChangedChip0Temp(5) <= '1';
						when x"005c" => dac088s085_x3_w.valuesChip0(6) <= dataBusIn(7 downto 0); valuesChangedChip0Temp(6) <= '1';
						when x"005e" => dac088s085_x3_w.valuesChip0(7) <= dataBusIn(7 downto 0); valuesChangedChip0Temp(7) <= '1';
						when x"0060" => dac088s085_x3_w.valuesChip1(0) <= dataBusIn(7 downto 0); valuesChangedChip1Temp(0) <= '1';
						when x"0062" => dac088s085_x3_w.valuesChip1(1) <= dataBusIn(7 downto 0); valuesChangedChip1Temp(1) <= '1';
						when x"0064" => dac088s085_x3_w.valuesChip1(2) <= dataBusIn(7 downto 0); valuesChangedChip1Temp(2) <= '1';
						when x"0066" => dac088s085_x3_w.valuesChip1(3) <= dataBusIn(7 downto 0); valuesChangedChip1Temp(3) <= '1';
						when x"0068" => dac088s085_x3_w.valuesChip1(4) <= dataBusIn(7 downto 0); valuesChangedChip1Temp(4) <= '1';
						when x"006a" => dac088s085_x3_w.valuesChip1(5) <= dataBusIn(7 downto 0); valuesChangedChip1Temp(5) <= '1';
						when x"006c" => dac088s085_x3_w.valuesChip1(6) <= dataBusIn(7 downto 0); valuesChangedChip1Temp(6) <= '1';
						when x"006e" => dac088s085_x3_w.valuesChip1(7) <= dataBusIn(7 downto 0); valuesChangedChip1Temp(7) <= '1';
						when x"0070" => dac088s085_x3_w.valuesChip2(0) <= dataBusIn(7 downto 0); valuesChangedChip2Temp(0) <= '1';
						when x"0072" => dac088s085_x3_w.valuesChip2(1) <= dataBusIn(7 downto 0); valuesChangedChip2Temp(1) <= '1';
						when x"0074" => dac088s085_x3_w.valuesChip2(2) <= dataBusIn(7 downto 0); valuesChangedChip2Temp(2) <= '1';
						when x"0076" => dac088s085_x3_w.valuesChip2(3) <= dataBusIn(7 downto 0); valuesChangedChip2Temp(3) <= '1';
						when x"0078" => dac088s085_x3_w.valuesChip2(4) <= dataBusIn(7 downto 0); valuesChangedChip2Temp(4) <= '1';
						when x"007a" => dac088s085_x3_w.valuesChip2(5) <= dataBusIn(7 downto 0); valuesChangedChip2Temp(5) <= '1';
						when x"007c" => dac088s085_x3_w.valuesChip2(6) <= dataBusIn(7 downto 0); valuesChangedChip2Temp(6) <= '1';
						when x"007e" => dac088s085_x3_w.valuesChip2(7) <= dataBusIn(7 downto 0); valuesChangedChip2Temp(7) <= '1';
						
						when others => null;
					end case;
				elsif ((controlBus.readStrobe = '1') and (controlBus.writeStrobe = '0') and (chipSelectInternal = '1')) then	
					case (controlBus.address(15 downto 0) and not(subAddressMask)) is
						when x"0000" => readDataBuffer <= x"00"&registerA;
						when x"0002" => readDataBuffer <= registerB;
						
						when x"0004" => readDataBuffer <= eventFifoSystem0_r.packetConfig;
						when x"0006" => readDataBuffer <= eventFifoSystem0_r.eventFifoErrorCounter;						
						
						when x"0010" => readDataBuffer <= triggerTimeToRisingEdge0_r.ch0;
						when x"0012" => readDataBuffer <= triggerTimeToRisingEdge0_r.ch1;
						when x"0014" => readDataBuffer <= triggerTimeToRisingEdge0_r.ch2;
						when x"0016" => readDataBuffer <= triggerTimeToRisingEdge0_r.ch3;
						when x"0018" => readDataBuffer <= triggerTimeToRisingEdge0_r.ch4;
						when x"001a" => readDataBuffer <= triggerTimeToRisingEdge0_r.ch5;
						when x"001c" => readDataBuffer <= triggerTimeToRisingEdge0_r.ch6;
						when x"001e" => readDataBuffer <= triggerTimeToRisingEdge0_r.ch7;
						
						when x"0020" => readDataBuffer <= eventFifoSystem0_r.dmaBuffer; eventFifoSystem0_w.nextWord <= '1'; -- autoreset
						when x"0022" => readDataBuffer <= eventFifoSystem0_r.eventFifoWordsDma;
						when x"0024" => readDataBuffer <= eventFifoSystem0_r.eventFifoFullCounter;
						when x"0026" => readDataBuffer <= eventFifoSystem0_r.eventFifoOverflowCounter;
						when x"0028" => readDataBuffer <= eventFifoSystem0_r.eventFifoUnderflowCounter;
						when x"002a" => readDataBuffer <= eventFifoSystem0_r.eventFifoWords;
						when x"002c" => readDataBuffer <= eventFifoSystem0_r.eventFifoFlags;						
						
						when x"002e" => readDataBuffer <= triggerDataDelay0_r.numberOfDelayCycles;
						
						when x"0030" => readDataBuffer <= pixelRateCounter0_r.ch0;
						when x"0032" => readDataBuffer <= pixelRateCounter0_r.ch1;
						when x"0034" => readDataBuffer <= pixelRateCounter0_r.ch2;
						when x"0036" => readDataBuffer <= pixelRateCounter0_r.ch3;
						when x"0038" => readDataBuffer <= pixelRateCounter0_r.ch4;
						when x"003a" => readDataBuffer <= pixelRateCounter0_r.ch5;
						when x"003c" => readDataBuffer <= pixelRateCounter0_r.ch6;
						when x"003e" => readDataBuffer <= pixelRateCounter0_r.ch7;
						
						when x"0048" => readDataBuffer <= x"000" & "000" & dac088s085_x3_r.dacBusy;
						when x"004a" => readDataBuffer <= x"00" & valuesChangedChip0Temp;
						when x"004c" => readDataBuffer <= x"00" & valuesChangedChip1Temp;
						when x"004e" => readDataBuffer <= x"00" & valuesChangedChip2Temp;
						
						when x"0050" => readDataBuffer <= x"00" & dac088s085_x3_r.valuesChip0(0);
						when x"0052" => readDataBuffer <= x"00" & dac088s085_x3_r.valuesChip0(1);
						when x"0054" => readDataBuffer <= x"00" & dac088s085_x3_r.valuesChip0(2);
						when x"0056" => readDataBuffer <= x"00" & dac088s085_x3_r.valuesChip0(3);
						when x"0058" => readDataBuffer <= x"00" & dac088s085_x3_r.valuesChip0(4);
						when x"005a" => readDataBuffer <= x"00" & dac088s085_x3_r.valuesChip0(5);
						when x"005c" => readDataBuffer <= x"00" & dac088s085_x3_r.valuesChip0(6);
						when x"005e" => readDataBuffer <= x"00" & dac088s085_x3_r.valuesChip0(7);
						when x"0060" => readDataBuffer <= x"00" & dac088s085_x3_r.valuesChip1(0);
						when x"0062" => readDataBuffer <= x"00" & dac088s085_x3_r.valuesChip1(1);
						when x"0064" => readDataBuffer <= x"00" & dac088s085_x3_r.valuesChip1(2);
						when x"0066" => readDataBuffer <= x"00" & dac088s085_x3_r.valuesChip1(3);
						when x"0068" => readDataBuffer <= x"00" & dac088s085_x3_r.valuesChip1(4);
						when x"006a" => readDataBuffer <= x"00" & dac088s085_x3_r.valuesChip1(5);
						when x"006c" => readDataBuffer <= x"00" & dac088s085_x3_r.valuesChip1(6);
						when x"006e" => readDataBuffer <= x"00" & dac088s085_x3_r.valuesChip1(7);
						when x"0070" => readDataBuffer <= x"00" & dac088s085_x3_r.valuesChip2(0);
						when x"0072" => readDataBuffer <= x"00" & dac088s085_x3_r.valuesChip2(1);
						when x"0074" => readDataBuffer <= x"00" & dac088s085_x3_r.valuesChip2(2);
						when x"0076" => readDataBuffer <= x"00" & dac088s085_x3_r.valuesChip2(3);
						when x"0078" => readDataBuffer <= x"00" & dac088s085_x3_r.valuesChip2(4);
						when x"007a" => readDataBuffer <= x"00" & dac088s085_x3_r.valuesChip2(5);
						when x"007c" => readDataBuffer <= x"00" & dac088s085_x3_r.valuesChip2(6);
						when x"007e" => readDataBuffer <= x"00" & dac088s085_x3_r.valuesChip2(7);
						
						when x"0080" => readDataBuffer <= gpsTiming0_r.week;
						when x"0082" => readDataBuffer <= gpsTiming0_r.quantizationError(31 downto 16);
						when x"0084" => readDataBuffer <= gpsTiming0_r.quantizationError(15 downto 0);
						when x"0086" => readDataBuffer <= gpsTiming0_r.timeOfWeekMilliSecond(31 downto 16);
						when x"0088" => readDataBuffer <= gpsTiming0_r.timeOfWeekMilliSecond(15 downto 0);
						when x"008a" => readDataBuffer <= gpsTiming0_r.timeOfWeekSubMilliSecond(31 downto 16);
						when x"008c" => readDataBuffer <= gpsTiming0_r.timeOfWeekSubMilliSecond(15 downto 0);
						when x"008e" => readDataBuffer <= gpsTiming0_r.differenceGpsToLocalClock;
						
--						when others  => readDataBuffer <= (others => '0');
						when others  => readDataBuffer <= x"dead";
					end case;
				end if;
			end if;
		end if;
	end process P0;
	
	
end generate g0;
end behavior;
