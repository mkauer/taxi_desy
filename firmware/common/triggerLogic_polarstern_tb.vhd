library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

entity triggerLogic_polarstern_tb is
end entity triggerLogic_polarstern_tb;

architecture RTL of triggerLogic_polarstern_tb is
	
signal clk : std_logic;

signal triggerPixelIn : std_logic_vector(16*8-1 downto 0);
signal triggerOut : std_logic;
signal internalTiming : internalTiming_t;
signal triggerRateCounter : p_triggerRateCounter_t;
signal registerRead : p_triggerLogic_registerRead_t;
signal registerWrite : p_triggerLogic_registerWrite_t;
	
begin
	clock_driver : process
		constant period : time := 10 ns;
	begin
		clk <= '0';
		wait for period / 2;
		clk <= '1';
		wait for period / 2;
	end process clock_driver;
	
	dut : entity work.triggerLogic_polarstern
		port map(
			triggerPixelIn     => triggerPixelIn,
			triggerOut         => triggerOut,
			internalTiming     => internalTiming,
			triggerRateCounter => triggerRateCounter,
			registerRead       => registerRead,
			registerWrite      => registerWrite
		);
		
	registerWrite.clock <= clk;
	registerWrite.reset <= '0', '1' after 100 ns, '0' after 120 ns;
	
	timer_1ms : process is
	begin
		internalTiming.tick_ms <= '0';	
		internalTiming.realTimeCounter <= (others => '0'); -- not needed
		wait for 1 us; -- to accelerate simulation
		wait until rising_edge(registerWrite.clock);
		internalTiming.tick_ms <= '1';
		wait until rising_edge(registerWrite.clock);
		
		-- loops forever	
	end process;
		
	stimulus : process is
	begin
		registerWrite.resetAllCounter <= '0';
		registerWrite.mode <= x"0";
		registerWrite.resetCounter <= (others => '0');
		registerWrite.counterPeriod <= x"0001";
		triggerPixelIn <= (others => '0');
		
		wait for 200 ns;
		
		triggerPixelIn <= (others => '1');
		wait for 10 ns;

		triggerPixelIn <= (others => '0');
				
		wait;
	end process;
	
	

end architecture RTL;
