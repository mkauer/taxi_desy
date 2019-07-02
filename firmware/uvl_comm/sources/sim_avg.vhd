--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   15:48:09 06/04/2019
-- Design Name:   
-- Module Name:   C:/Xilinx/projects/taxi/firmware/uvLogger/sim_avg.vhd
-- Project Name:  uvLogger
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: fifo_average_v1
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE ieee.numeric_std.ALL;
use work.types.all;
 
ENTITY sim_avg IS
END sim_avg;
 
ARCHITECTURE behavior OF sim_avg IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT fifo_average_v1
    PORT(
         reset : IN  std_logic;
         clk : IN  std_logic;
         dataIn : IN  std_logic_vector(15 downto 0);
         avgOut : OUT  std_logic_vector(15 downto 0);
         avgFactor : IN  std_logic_vector(3 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal reset : std_logic := '0';
   signal clk : std_logic := '0';
   signal dataIn : std_logic_vector(15 downto 0) := (others => '0');
   signal avgFactor : std_logic_vector(3 downto 0) := (others => '0');

 	--Outputs
   signal avgOut : std_logic_vector(15 downto 0);

   -- Clock period definitions
   --constant clk_period : time := 33.33 ns;
   constant clk_period : time := 10 ns;

   signal counter : integer;
   signal delta : integer;
   
   constant start : integer := 8200;
   constant inc : integer := 20;

   type adcSamples_t is array (0 to 1023) of std_logic_vector(15 downto 0);
   constant adcSamples : adcSamples_t := (
x"201D",x"201F",x"201E",x"201E",x"201E",x"201E",x"201E",x"201E",x"201E",x"201E",x"201E",x"201D",x"201D",x"201F",x"201F",x"2023",x"2022",x"2021",x"2021",x"2023",x"2023",x"2023",x"2023",x"2025",x"2024",x"2026",x"2026",x"2025",x"2025",x"2027",x"2027",x"2025",x"2025",x"2027",x"2027",x"2027",x"2027",x"2027",x"2027",x"2027",x"2027",x"202D",x"202D",x"202B",x"202B",x"2029",x"2028",x"2029",x"2029",x"202B",x"202A",x"202B",x"202B",x"202B",x"202A",x"202B",x"202B",x"202D",x"202C",x"202D",x"202D",x"202D",x"202D",x"202B",x"202A",x"202C",x"202C",x"202B",x"202B",x"202D",x"202C",x"202C",x"202C",x"202D",x"202D",x"202B",x"202B",x"202D",x"202C",x"202C",x"202C",x"202B",x"202B",x"202B",x"202A",x"202A",x"202A",x"202A",x"202A",x"202A",x"202A",x"202B",x"202B",x"2025",x"2025",x"2021",x"2021",x"2027",x"2026",x"2023",x"2023",x"2021",x"2021",x"2021",x"2021",x"2021",x"2020",x"2021",x"2021",x"201F",x"201E",x"201F",x"201F",x"201F",x"201F",x"201D",x"201D",x"201B",x"201B",x"201B",x"201B",x"201D",x"201C",x"201C",x"201C",x"201A",x"201A",x"201A",x"201A",x"201A",x"201A",x"2017",x"2017",x"2017",x"2017",x"2019",x"2018",x"2015",x"2015",x"2017",x"2016",x"2016",x"2016",x"2013",x"2013",x"2015",x"2015",x"2017",x"2016",x"2013",x"2013",x"2015",x"2015",x"2017",x"2016",x"2015",x"2015",x"2013",x"2013",x"2017",x"2017",x"2017",x"2017",x"2019",x"2018",x"2019",x"2019",x"2019",x"2019",x"201B",x"201B",x"201B",x"201A",x"201A",x"201A",x"201B",x"201B",x"201D",x"201C",x"201A",x"201A",x"201B",x"201B",x"201D",x"201C",x"201A",x"201A",x"201B",x"201B",x"201B",x"201A",x"201C",x"201C",x"201B",x"201B",x"201D",x"201C",x"201E",x"201E",x"201E",x"201E",x"201F",x"201F",x"2021",x"2020",x"2020",x"2020",x"2021",x"2021",x"2021",x"2021",x"2023",x"2023",x"2023",x"2023",x"2023",x"2023",x"2023",x"2023",x"2027",x"2026",x"2025",x"2025",x"2027",x"2026",x"2025",x"2025",x"2027",x"2026",x"2026",x"2026",x"202B",x"202B",x"2023",x"2023",x"2029",x"2029",x"2029",x"2028",x"2029",x"2029",x"202B",x"202A",x"2029",x"2029",x"202B",x"202B",x"202B",x"202B",x"202B",x"202A",x"202B",x"202B",x"2029",x"2029",x"202B",x"202A",x"202C",x"202C",x"202D",x"202D",x"202B",x"202A",x"202C",x"202C",x"202B",x"202B",x"202B",x"202B",x"2029",x"2029",x"202B",x"202A",x"202C",x"202C",x"202D",x"202D",x"202B",x"202B",x"202B",x"202B",x"2029",x"2028",x"2028",x"2028",x"2025",x"2025",x"2025",x"2024",x"2025",x"2025",x"2025",x"2024",x"2022",x"2022",x"2021",x"2021",x"201F",x"201F",x"2021",x"2020",x"2020",x"2020",x"201C",x"201C",x"201D",x"201D",x"201D",x"201D",x"201D",x"201C",x"201C",x"201C",x"201C",x"201C",x"201A",x"201A",x"2019",x"2019",x"201B",x"201A",x"2018",x"2018",x"2016",x"2016",x"2017",x"2017",x"2017",x"2017",x"2017",x"2017",x"2017",x"2016",x"2017",x"2017",x"2017",x"2017",x"2017",x"2016",x"2015",x"2015",x"2017",x"2016",x"2014",x"2014",x"2015",x"2015",x"2017",x"2016",x"2017",x"2017",x"2017",x"2016",x"2018",x"2018",x"2016",x"2016",x"2017",x"2017",x"2019",x"2018",x"201A",x"201A",x"201B",x"201B",x"201B",x"201B",x"201B",x"201A",x"201B",x"201B",x"2019",x"2018",x"201C",x"201C",x"201A",x"201A",x"201A",x"201A",x"201C",x"201C",x"201C",x"201C",x"201C",x"201C",x"201D",x"201D",x"201D",x"201C",x"201D",x"201D",x"201F",x"201F",x"2021",x"2021",x"2021",x"2020",x"2023",x"2023",x"2023",x"2023",x"2023",x"2023",x"2023",x"2022",x"2026",x"2026",x"2025",x"2025",x"2027",x"2026",x"2025",x"2025",x"2027",x"2026",x"2026",x"2026",x"2025",x"2025",x"2027",x"2027",x"201F",x"201F",x"201F",x"201F",x"202B",x"202A",x"2029",x"2029",x"2029",x"2028",x"202A",x"202A",x"202A",x"202A",x"202B",x"202B",x"202B",x"202B",x"202B",x"202A",x"202A",x"202A",x"202B",x"202B",x"2029",x"2029",x"202B",x"202B",x"2029",x"2029",x"202B",x"202B",x"202B",x"202B",x"202D",x"202C",x"202C",x"202C",x"202B",x"202B",x"202B",x"202B",x"202B",x"202A",x"202C",x"202C",x"202B",x"202B",x"2029",x"2028",x"2029",x"2029",x"2029",x"2028",x"202A",x"202A",x"2023",x"2023",x"2025",x"2025",x"2023",x"2023",x"2023",x"2022",x"2023",x"2023",x"2023",x"2022",x"2020",x"2020",x"2021",x"2021",x"201F",x"201E",x"201F",x"201F",x"201D",x"201C",x"201D",x"201D",x"201D",x"201D",x"201B",x"201B",x"201B",x"201A",x"201A",x"201A",x"201A",x"201A",x"2019",x"2019",x"2019",x"2019",x"2019",x"2019",x"2017",x"2017",x"2017",x"2016",x"2017",x"2017",x"2017",x"2016",x"2016",x"2016",x"2015",x"2015",x"2015",x"2015",x"2015",x"2015",x"2017",x"2016",x"2017",x"2017",x"2017",x"2016",x"2016",x"2016",x"2016",x"2016",x"2018",x"2018",x"2018",x"2018",x"2018",x"2018",x"201A",x"201A",x"201B",x"201B",x"201D",x"201C",x"201A",x"201A",x"2019",x"2019",x"201B",x"201A",x"201C",x"201C",x"201A",x"201A",x"201C",x"201C",x"201C",x"201C",x"201B",x"201B",x"201D",x"201C",x"201D",x"201D",x"201D",x"201D",x"201F",x"201F",x"201D",x"201C",x"201F",x"201F",x"2021",x"2020",x"2020",x"2020",x"2021",x"2021",x"2023",x"2022",x"2022",x"2022",x"2025",x"2025",x"2025",x"2025",x"2025",x"2025",x"2025",x"2024",x"2024",x"2024",x"2027",x"2027",x"2029",x"2028",x"2028",x"2028",x"2026",x"2026",x"2027",x"2027",x"202F",x"202F",x"202D",x"202C",x"2028",x"2028",x"202A",x"202A",x"202B",x"202B",x"202B",x"202B",x"2029",x"2029",x"2029",x"2029",x"202B",x"202B",x"202D",x"202C",x"202A",x"202A",x"202C",x"202C",x"202C",x"202C",x"202C",x"202C",x"202B",x"202B",x"202D",x"202D",x"202B",x"202A",x"202B",x"202B",x"202D",x"202C",x"202B",x"202B",x"202B",x"202A",x"202A",x"202A",x"202A",x"202A",x"2029",x"2029",x"2029",x"2029",x"2029",x"2028",x"2026",x"2026",x"2029",x"2029",x"2027",x"2026",x"2021",x"2021",x"2023",x"2023",x"2023",x"2023",x"2023",x"2022",x"2020",x"2020",x"2020",x"2020",x"201F",x"201F",x"201F",x"201E",x"201D",x"201D",x"201F",x"201E",x"201C",x"201C",x"201B",x"201B",x"201D",x"201C",x"201C",x"201C",x"2019",x"2019",x"2017",x"2017",x"2017",x"2017",x"2017",x"2017",x"2017",x"2017",x"2019",x"2018",x"2017",x"2017",x"2017",x"2017",x"2015",x"2015",x"2017",x"2016",x"2016",x"2016",x"2016",x"2016",x"2016",x"2016",x"2017",x"2017",x"2017",x"2016",x"2018",x"2018",x"2018",x"2018",x"2018",x"2018",x"2017",x"2017",x"2019",x"2018",x"2017",x"2017",x"201B",x"201B",x"201B",x"201B",x"201B",x"201B",x"201D",x"201C",x"201E",x"201E",x"201E",x"201E",x"201F",x"201F",x"201D",x"201C",x"201D",x"201D",x"201D",x"201D",x"201D",x"201D",x"201D",x"201D",x"201F",x"201E",x"201F",x"201F",x"201F",x"201E",x"2020",x"2020",x"201F",x"201F",x"2021",x"2021",x"2023",x"2023",x"2023",x"2022",x"2023",x"2023",x"2025",x"2024",x"2022",x"2022",x"2025",x"2025",x"2025",x"2024",x"2027",x"2027",x"2027",x"2027",x"2025",x"2025",x"2027",x"2026",x"2027",x"2027",x"2027",x"2027",x"2037",x"2036",x"2027",x"2027",x"2027",x"2027",x"202B",x"202A",x"202B",x"202B",x"202B",x"202B",x"202B",x"202B",x"202D",x"202C",x"202B",x"202B",x"202D",x"202C",x"202C",x"202C",x"202C",x"202C",x"202D",x"202D",x"202D",x"202D",x"202D",x"202C",x"202C",x"202C",x"202A",x"202A",x"202C",x"202C",x"202B",x"202B",x"202B",x"202A",x"202B",x"202B",x"202B",x"202B",x"2029",x"2029",x"202B",x"202A",x"2027",x"2027",x"202D",x"202D",x"2023",x"2023",x"202B",x"202B",x"2027",x"2027",x"2023",x"2023",x"2023",x"2023",x"2023",x"2022",x"2020",x"2020",x"2020",x"2020",x"2021",x"2021",x"2021",x"2020",x"201E",x"201E",x"201C",x"201C",x"201C",x"201C",x"201D",x"201D",x"201B",x"201B",x"201B",x"201A",x"2019",x"2019",x"201B",x"201A",x"2018",x"2018",x"2019",x"2019",x"2019",x"2018",x"2018",x"2018",x"2018",x"2018",x"2016",x"2016",x"2018",x"2018",x"2016",x"2016",x"2016",x"2016",x"2015",x"2015",x"2017",x"2016",x"2015",x"2015",x"2017",x"2017",x"2015",x"2014",x"2016",x"2016",x"2016",x"2016",x"2017",x"2017",x"2019",x"2018",x"2018",x"2018",x"2018",x"2018",x"201A",x"201A",x"201A",x"201A",x"201B",x"201B",x"201B",x"201B",x"201B",x"201A",x"201E",x"201E",x"201C",x"201C",x"201B",x"201B",x"201B",x"201B",x"201D",x"201D",x"201F",x"201F",x"201B",x"201B",x"201F",x"201E",x"201F",x"201F",x"201D",x"201D",x"201F",x"201E",x"2020",x"2020",x"2020",x"2020",x"2021",x"2021",x"2023",x"2023",x"2025",x"2024",x"2022",x"2022",x"2024",x"2024",x"2024",x"2024",x"2025",x"2025",x"2027",x"2027",x"2027",x"2026",x"2025",x"2025",x"2029",x"2028",x"2028",x"2028",x"2025",x"2025",x"2021",x"2021",x"2023",x"2023",x"2029",x"2029",x"202B",x"202B",x"202D",x"202D",x"202B",x"202A",x"2028",x"2028",x"2029",x"2029",x"202D",x"202C",x"2029",x"2029",x"202B",x"202B",x"202D",x"202C",x"202C",x"202C",x"202E",x"202E",x"202D",x"202D",x"202D"   
   );
   signal counter2 : integer range 0 to adcSamples'length-1;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: fifo_average_v1 PORT MAP (
          reset => reset,
          clk => clk,
          dataIn => dataIn,
          avgOut => avgOut,
          avgFactor => avgFactor
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;

	process(clk)
	begin
	if(rising_edge(clk)) then
		if(reset = '1') then
			counter <= start;
			delta <= 1;
		else
			counter <= counter + delta;
			if(counter >= start+inc-1) then
				delta <= -1;
			end if;
			if(counter <= start-(inc-1)) then
				delta <= 1;
			end if;

		end if;
	end if;
	end process;

	process(clk)
	begin
	if(rising_edge(clk)) then
		if(reset = '1') then
			counter2 <= 0;
		else
			counter2 <= counter2 + 1;
			if(counter2 >= adcSamples'length-1) then
				counter2 <= 0;	
			end if;
		end if;
	end if;
	end process;
	
	--dataIn <= i2v(counter,16);
	dataIn <= adcSamples(counter2);

   -- Stimulus process
   stim_proc: process
   begin
      -- hold reset state for 100 ns.
	   reset <= '1';
	   avgFactor <= x"4";
      wait for 30 ns;
	   reset <= '0';
      wait for clk_period*10;

      -- insert stimulus here

      wait;
   end process;

END;
