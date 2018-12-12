-----------------------------------------------------------------------------------
-- Design Name : var_baudrate_generator_8b10b 
-- File Name   : var_baudrate_generator_8b10b.vhd
-- Function    : generate tx enables from the system clock
--               with 10 fold oversampling, according to the baudrate_ctrl setting
-- Coder       : K.-H. Sulanke, DESY
-- Date        : 2018-11-06
------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
--use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.types.all;

entity var_baudrate_generator_8b10b is
	port ( reset          : in  std_logic;
		   clk            : in  std_logic;
		   --baudrate_adj   : in std_logic_vector(3 downto 0);
		   tx_ena         : out std_logic;
		--commDebug_0r : out commDebug_registerRead_t;
		commDebug_0w : in commDebug_registerWrite_t
	   );
end entity var_baudrate_generator_8b10b;

architecture var_baudrate_generator_8b10b_arch of var_baudrate_generator_8b10b is

	signal tx_baud_div_TPTHRU_TIG : unsigned(15 downto 0); --natural range 0 to 3_000;
	signal tx_baud_div_1 : unsigned(15 downto 0); --natural range 0 to 3_000;
	signal tx_baud_div_2 : unsigned(15 downto 0); --natural range 0 to 3_000;
	signal tx_baud_div : unsigned(15 downto 0); --natural range 0 to 3_000;
	signal clock_count : unsigned(15 downto 0); --natural range 0 to 3_000;  

begin

  --tx_baud_div <= (SYS_CLOCK / baudrate) -1;
	p0: process(clk)
	begin
		if(rising_edge(clk)) then
			tx_baud_div_2 <= tx_baud_div_1; 
			tx_baud_div_1 <= tx_baud_div_TPTHRU_TIG; 
			tx_baud_div_TPTHRU_TIG <= unsigned(commDebug_0w.tx_baud_div);
		end if;
	end process p0;


--	set_baudrate: process (clk)
--	begin
--		if rising_edge(clk) then
--			if reset = '1' then
--				tx_baud_div <= to_unsigned(300-1,tx_baud_div'length);
--			else 
--				if clock_count = tx_baud_div then      
--					case baudrate_adj is
--						when X"0"   => tx_baud_div <= to_unsigned(  3000 - 1,tx_baud_div'length); --   20_000 baud
--						when X"1"   => tx_baud_div <= to_unsigned(  2000 - 1,tx_baud_div'length); --   30_000 baud
--						when X"2"   => tx_baud_div <= to_unsigned(  1500 - 1,tx_baud_div'length); --   40_000 baud 
--						when X"3"   => tx_baud_div <= to_unsigned(  1200 - 1,tx_baud_div'length); --   50_000 baud
--						when X"4"   => tx_baud_div <= to_unsigned(   600 - 1,tx_baud_div'length); --  100_000 baud
--						when X"5"   => tx_baud_div <= to_unsigned(   400 - 1,tx_baud_div'length); --  150_000 baud
--						when X"6"   => tx_baud_div <= to_unsigned(   300 - 1,tx_baud_div'length); --  200_000 baud
--						when X"7"   => tx_baud_div <= to_unsigned(   200 - 1,tx_baud_div'length); --  300_000 baud
--						when X"8"   => tx_baud_div <= to_unsigned(   120 - 1,tx_baud_div'length); --  500_000 baud
--						when X"9"   => tx_baud_div <= to_unsigned(    60 - 1,tx_baud_div'length); -- 1000_000 baud
--						when X"a"   => tx_baud_div <= to_unsigned(    40 - 1,tx_baud_div'length); -- 1500_000 baud
--						when X"b"   => tx_baud_div <= to_unsigned(    30 - 1,tx_baud_div'length); -- 2000_000 baud
--						when X"c"   => tx_baud_div <= to_unsigned(    20 - 1,tx_baud_div'length); -- 3000_000 baud
--						when X"d"   => tx_baud_div <= to_unsigned(    15 - 1,tx_baud_div'length); -- 4000_000 baud
--						when X"e"   => tx_baud_div <= to_unsigned(    12 - 1,tx_baud_div'length); -- 5000_000 baud
--						when X"f"   => tx_baud_div <= to_unsigned(    10 - 1,tx_baud_div'length); -- 6000_000 baud
--						when others => tx_baud_div <= to_unsigned(   300 - 1,tx_baud_div'length);                
--					end case;
--				end if; -- tx_ena = '1'
--			end if; -- reset = '1' 
--		end if; -- rising_edge(clk)   
--	end process set_baudrate; 

	make_tx_ena: process(clk)
	begin
		if(rising_edge(clk)) then
			if(reset = '1') then
				clock_count <= (others=>'0');
				tx_ena <= '0';
			elsif(clock_count >= tx_baud_div_2) then
				tx_ena <= '1';
				clock_count <= (others=>'0');
			else
				clock_count <= clock_count + 1;
				tx_ena <= '0';
			end if; 
		end if;
	end process make_tx_ena;

end architecture var_baudrate_generator_8b10b_arch;
