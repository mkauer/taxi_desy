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
		pixelRateCounter0_w : out pixelRateCounter_registerWrite_t
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
	
	P0:process (controlBus.clock)
	begin
		if rising_edge(controlBus.clock) then
			eventFifoSystem0_w.nextWord <= '0'; -- autoreset
			triggerDataDelay0_w.resetDelay <= '0'; -- autoreset
			pixelRateCounter0_w.resetCounter <= (others=>'0'); -- autoreset
			debugReset <= '0'; -- autoreset
			eventFifoClear <= '0'; -- autoreset
			if (controlBus.reset = '1') then
				registerA <= (others => '0');
				registerb <= (others => '0');
				triggerDataDelay0_w.numberOfDelayCycles <= x"0004";
				triggerDataDelay0_w.resetDelay <= '1';
			else			
				if ((controlBus.writeStrobe = '1') and (controlBus.readStrobe = '0') and (chipSelectInternal = '1')) then
					case (controlBus.address(15 downto 0) and not(subAddressMask)) is
						when x"0000" => registerA <= dataBusIn(7 downto 0);
						when x"0002" => registerB <= dataBusIn;
						
						when x"0004" => eventFifoSystem0_w.packetConfig <= dataBusIn;
						
						when x"0022" => eventFifoClear <= '1'; -- autoreset
						when x"002c" => debugReset <= '1'; -- autoreset
						when x"002e" => triggerDataDelay0_w.numberOfDelayCycles <= dataBusIn; triggerDataDelay0_w.resetDelay <= '1'; -- autoreset
					
						when x"0030" => pixelRateCounter0_w.resetCounter <= dataBusIn; -- autoreset
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
						
						
--						when others  => readDataBuffer <= (others => '0');
						when others  => readDataBuffer <= x"dead";
					end case;
				end if;
			end if;
		end if;
	end process P0;
	
	
end generate g0;
end behavior;
