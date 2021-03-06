----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    20:09:33 03/08/2017 
-- Design Name: 
-- Module Name:    triggerSystem - Behavioral 
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
use ieee.numeric_std.all;
use work.types.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity triggerLogic is
--generic(
--	numberOfChannels : integer := 8
--	);
port(
	--triggerPixelIn : in std_logic_vector(8*numberOfChannels-1 downto 0);
	triggerPixelIn : in triggerSerdes_t;
	triggerOut : out std_logic;
	triggerRateCounter : out triggerRateCounter_t;
	registerRead : out triggerLogic_registerRead_t;
	registerWrite : in triggerLogic_registerWrite_t
	);
end triggerLogic;

architecture Behavioral of triggerLogic is
	
	attribute keep : string; 

	signal triggerAB : std_logic_vector(1 downto 0) := "00";
	signal triggerABStretched : std_logic_vector(1 downto 0) := "00";
	--signal mode : std_logic_vector(3 downto 0) := x"0";

	type triggerPixelInSlow_t is array (0 to 1) of std_logic_vector(7 downto 0);
	signal triggerPixelInSlow : triggerPixelInSlow_t := (others=>(others=>'0'));
	signal triggerPixelInSlowStretched : triggerPixelInSlow_t := (others=>(others=>'0'));
	signal twoPerSectorTrigger : std_logic_vector(1 downto 0) := "00";
	signal bigOr : std_logic := '0';
	signal twoPerSectorTopOrButtom : std_logic := '0';
	signal twoPerSectorTopAndButtom : std_logic := '0';
	
	attribute keep of twoPerSectorTopOrButtom : signal is "true";
	attribute keep of bigOr : signal is "true";
	attribute keep of twoPerSectorTrigger : signal is "true";
	attribute keep of twoPerSectorTopAndButtom : signal is "true";
	attribute keep of triggerPixelInSlow : signal is "true";

	constant numberOfTriggerPath : integer := 3;
	signal triggerPath : std_logic_vector(numberOfTriggerPath-1 downto 0) := (others => '0');
	signal triggerPath_old : std_logic_vector(numberOfTriggerPath-1 downto 0) := (others => '0');
	type counter_t is array (0 to numberOfTriggerPath-1) of unsigned(15 downto 0);
	signal triggerPathCounter : counter_t := (others => (others => '0'));
	type counterSector_t is array (0 to 7) of unsigned(15 downto 0);
	signal triggerSectorCounter : counterSector_t := (others => (others => '0'));
	signal counter_ms : unsigned(15 downto 0) := (others => '0');
	signal counter_sec : unsigned(15 downto 0) := (others => '0');
	
begin

	registerRead.mode <= registerWrite.mode;
	
	triggerAB(0) <= '1' when (triggerPixelIn(0) /= (triggerPixelIn(0)'range => '0')) else '0';
	triggerAB(1) <= '1' when (triggerPixelIn(1) /= (triggerPixelIn(1)'range => '0')) else '0';

	g0: for i in 0 to 7 generate
		triggerPixelInSlow(0)(i) <= '1' when triggerPixelIn(0)(i*8+7 downto i*8) /= x"00" else '0'; -- ## odd way to do this.... will have problematic behavioral with fast pulses
		triggerPixelInSlow(1)(i) <= '1' when triggerPixelIn(1)(i*8+7 downto i*8) /= x"00" else '0'; -- ## odd way to do this.... will have problematic behavioral with fast pulses
	end generate;

	y1: entity work.pulseStretcher generic map (8) port map(registerWrite.clock, registerWrite.reset, triggerPixelInSlow(0), triggerPixelInSlowStretched(0));
	y2: entity work.pulseStretcher generic map (8) port map(registerWrite.clock, registerWrite.reset, triggerPixelInSlow(1), triggerPixelInSlowStretched(1));
	yr: entity work.pulseStretcher generic map (2) port map(registerWrite.clock, registerWrite.reset, triggerAB, triggerABStretched);

	g1: for i in 0 to 1 generate
		twoPerSectorTrigger(i) <= 
			'1' when std_match(triggerPixelInSlowStretched(i), "------11") else
			'1' when std_match(triggerPixelInSlowStretched(i), "----11--") else
			'1' when std_match(triggerPixelInSlowStretched(i), "--11----") else
			'1' when std_match(triggerPixelInSlowStretched(i), "11------") else
			'0';
	end generate;
	
	bigOr <= triggerABStretched(0) or triggerABStretched(1);

	twoPerSectorTopOrButtom <= twoPerSectorTrigger(0) or twoPerSectorTrigger(1);
	twoPerSectorTopAndButtom <= twoPerSectorTrigger(0) and twoPerSectorTrigger(1);

	with registerWrite.mode select 
		triggerOut <=
			bigOr when x"0",
			twoPerSectorTopOrButtom when x"1",
			twoPerSectorTopAndButtom when x"2",
			bigOr when others;


	-- rate counter
	P1:process (registerWrite.clock)
	begin
		if rising_edge(registerWrite.clock) then
			triggerRateCounter.newData <= '0'; -- autoreset
			if(registerWrite.reset = '1') then
				triggerPath <= (others => '0');
				triggerPath_old <= (others => '0');
				triggerPathCounter <= (others => (others => '0'));
				triggerSectorCounter <= (others => (others => '0'));
				counter_ms <= (others => '0');
				counter_sec <= (others => '0');
				registerRead.rateCounter<= (others => (others => '0'));
				registerRead.rateCounterLatched <= (others => (others => '0'));
				triggerRateCounter.rateCounterLatched <= (others => (others => '0'));
				triggerRateCounter.rateCounterSectorLatched <= (others => (others => '0'));
				registerRead.rateCounterSectorLatched <= (others => (others => '0'));
			else
				triggerPath(0) <= bigOr;
				triggerPath(1) <= twoPerSectorTopOrButtom;
				triggerPath(2) <= twoPerSectorTopAndButtom;

				triggerPath_old <= triggerPath;

				if(registerWrite.tick_ms = '1') then
					counter_ms <= counter_ms + 1;
				end if;
				if(counter_ms >= x"03e7") then
					counter_ms <= (others => '0');
					counter_sec <= counter_sec + 1;
				end if;
				
				for i in 0 to numberOfTriggerPath-1 loop
					if((triggerPath_old(i) = '0') and (triggerPath(i) = '1')) then
						triggerPathCounter(i) <= triggerPathCounter(i) + 1;
						if(triggerPathCounter(i) = x"ffff") then
							triggerPathCounter(i) <= x"ffff";
						end if;
					end if;
				
					if(registerWrite.resetCounter(i) = '1') then
						triggerPathCounter(i) <= (others => '0');
					end if;

				end loop;
			
				if(registerWrite.counterPeriod = x"0000") then
					for i in 0 to numberOfTriggerPath-1 loop
						registerRead.rateCounter(i) <= std_logic_vector(triggerPathCounter(i));
						registerRead.rateCounterLatched(i) <= std_logic_vector(triggerPathCounter(i));
						triggerRateCounter.rateCounterLatched(i) <= std_logic_vector(triggerPathCounter(i));
					end loop;
					for i in 0 to 7 loop
						triggerRateCounter.rateCounterSectorLatched(i) <= std_logic_vector(triggerSectorCounter(i));
						registerRead.rateCounterSectorLatched(i) <= std_logic_vector(triggerSectorCounter(i));
					end loop;
				elsif(counter_sec >= unsigned(registerWrite.counterPeriod)) then
					counter_sec <= (others => '0');
					triggerPathCounter <= (others => (others => '0'));
					triggerSectorCounter <= (others => (others => '0'));
					for i in 0 to numberOfTriggerPath-1 loop
						registerRead.rateCounter(i) <= std_logic_vector(triggerPathCounter(i));
						registerRead.rateCounterLatched(i) <= std_logic_vector(triggerPathCounter(i));
						triggerRateCounter.rateCounterLatched(i) <= std_logic_vector(triggerPathCounter(i));
					end loop;
					for i in 0 to 7 loop
						triggerRateCounter.rateCounterSectorLatched(i) <= std_logic_vector(triggerSectorCounter(i));
						registerRead.rateCounterSectorLatched(i) <= std_logic_vector(triggerSectorCounter(i));
					end loop;
					triggerRateCounter.newData <= '1'; -- autoreset
				end if;
				
				if(std_match(triggerPixelInSlowStretched(0), "------11")) then
					triggerSectorCounter(0) <= triggerSectorCounter(0) + 1;
				end if;
				if(std_match(triggerPixelInSlowStretched(0), "----11--")) then
					triggerSectorCounter(1) <= triggerSectorCounter(1) + 1;
				end if;
				if(std_match(triggerPixelInSlowStretched(0), "--11----")) then
					triggerSectorCounter(2) <= triggerSectorCounter(2) + 1;
				end if;
				if(std_match(triggerPixelInSlowStretched(0), "11------")) then
					triggerSectorCounter(3) <= triggerSectorCounter(3) + 1;
				end if;
				if(std_match(triggerPixelInSlowStretched(1), "------11")) then
					triggerSectorCounter(4) <= triggerSectorCounter(4) + 1;
				end if;
				if(std_match(triggerPixelInSlowStretched(1), "----11--")) then
					triggerSectorCounter(5) <= triggerSectorCounter(5) + 1;
				end if;
				if(std_match(triggerPixelInSlowStretched(1), "--11----")) then
					triggerSectorCounter(6) <= triggerSectorCounter(6) + 1;
				end if;
				if(std_match(triggerPixelInSlowStretched(1), "11------")) then
					triggerSectorCounter(7) <= triggerSectorCounter(7) + 1;
				end if;


			end if;
		end if;
	end process P1;

end Behavioral;

