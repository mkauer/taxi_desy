----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    20:41:43 03/08/2017 
-- Design Name: 
-- Module Name:    triggerTimeToRisingEdge - Behavioral 
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

entity triggerTimeToRisingEdge_v3 is
	generic 
	(
		numberOfChannels : integer := 8
	);
	port
	(
		triggerPixelIn : in std_logic_vector(8*numberOfChannels-1 downto 0);
		--trigger : in std_logic;
		trigger : in triggerLogic_t;
		registerRead : out triggerTimeToRisingEdge_registerRead_t;
		registerWrite : in triggerTimeToRisingEdge_registerWrite_t;
		triggerTiming : out triggerTiming_t
	);
end entity;

architecture behavioral of triggerTimeToRisingEdge_v3 is
	type state_t is (idle, sample, latch, prepare);
	signal state1 : state_t;
	type counter_t is array (0 to numberOfChannels-1) of unsigned(15 downto 0);
	signal pixelCounter : counter_t;
	signal pixelCounterLatched : counter_t;
	signal pixelCounterStop : std_logic_vector(numberOfChannels-1 downto 0);
	signal timeoutCounter : unsigned(15 downto 0);
	signal dataValid : std_logic;
	
	signal gate : std_logic;
	signal gate_old : std_logic;
	signal timeToRisingEdge : dataNumberOfChannelsX16Bit_t;
	signal noEdgeDetected : std_logic_vector(numberOfChannels-1 downto 0);
	signal newData : std_logic_vector(numberOfChannels-1 downto 0);
	signal newDataValid : std_logic_vector(numberOfChannels-1 downto 0);
	
begin
	
	gate <= trigger.flasherTriggerGate;
	triggerTiming.newDataValid <= newDataValid(0); -- ## same for all channels
	triggerTiming.newData <= newData(0); -- ## same for all channels
	registerRead.channel <= timeToRisingEdge;
	triggerTiming.channel <= timeToRisingEdge;

	g0: for i in 0 to numberOfChannels-1 generate
		x: entity work.timeToRisingEdge_v1 port map(registerWrite.clock, registerWrite.reset, triggerPixelIn(i*8+7 downto i*8), gate, timeToRisingEdge(i), noEdgeDetected(i), newData(i), newDataValid(i));
	end generate;

--	process(registerWrite.clock)
--	begin
--		if rising_edge(registerWrite.clock) then
--			triggerTiming.newData <= '0'; -- autoreset
--			if (registerWrite.reset = '1') then
--				null;
--			else
--				if(newData(0) = '1') then -- same for all channels	
--					registerRead.channel <= timeToRisingEdge;
--					triggerTiming.channel <= timeToRisingEdge;
--					triggerTiming.newData <= '1'; -- autoreset
--				end if;
--			end if;
--		end if;
--	end process;

end behavioral;
