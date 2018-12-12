-----------------------------------------------------------------------------------
-- Design Name : var_baudrate_generator_8b10b 
-- File Name   : var_baudrate_generator_8b10b.vhd
-- Function    : generate tx enables from the system clock
--               with 10 fold oversampling, according to the baudrate_ctrl setting
-- Coder       : K.-H. Sulanke, DESY
-- Date        : 2018-11-06
------------------------------------------------------------------------------------
-- was functional

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity var_baudrate_generator_8b10b is
  port ( reset          : in  std_logic;
         clk            : in  std_logic;
         baudrate_adj   : in std_logic_vector(3 downto 0);
         tx_ena         : out std_logic
         );
end entity var_baudrate_generator_8b10b;

architecture var_baudrate_generator_8b10b_arch of var_baudrate_generator_8b10b is

--constant COM_CLOCK : natural := 60_000_000;
  signal tx_baud_div : natural range 0 to 3_000;
  signal clock_count : natural range 0 to 3_000;  
  
begin

  --tx_baud_div <= (SYS_CLOCK / baudrate) -1;

  set_baudrate: process (clk)
   begin
   if rising_edge(clk) then
     if reset = '1' then
      tx_baud_div    <=  10 - 1;
     else 
       if clock_count = tx_baud_div then  -- for synchronized changing of the baudrate    
        case baudrate_adj is
         when X"0"   => tx_baud_div <=   3000 - 1; --   20_000 baud
         when X"1"   => tx_baud_div <=   2000 - 1; --   30_000 baud
         when X"2"   => tx_baud_div <=   1500 - 1; --   40_000 baud 
         when X"3"   => tx_baud_div <=   1200 - 1; --   50_000 baud
         when X"4"   => tx_baud_div <=    600 - 1; --  100_000 baud
         when X"5"   => tx_baud_div <=    400 - 1; --  150_000 baud
         when X"6"   => tx_baud_div <=    300 - 1; --  200_000 baud
         when X"7"   => tx_baud_div <=    200 - 1; --  300_000 baud
         when X"8"   => tx_baud_div <=    120 - 1; --  500_000 baud
         when X"9"   => tx_baud_div <=     60 - 1; -- 1000_000 baud
         when X"a"   => tx_baud_div <=     40 - 1; -- 1500_000 baud
         when X"b"   => tx_baud_div <=     30 - 1; -- 2000_000 baud
         when X"c"   => tx_baud_div <=     20 - 1; -- 3000_000 baud
         when X"d"   => tx_baud_div <=     15 - 1; -- 4000_000 baud
         when X"e"   => tx_baud_div <=     12 - 1; -- 5000_000 baud
         when X"f"   => tx_baud_div <=     10 - 1; -- 6000_000 baud
                                                               
         when others => tx_baud_div <= 10 - 1;                
        end case;
       end if; -- tx_ena = '1'
      end if; -- reset = '1' 
     end if; -- rising_edge(clk)   
   end process set_baudrate; 
        
  make_tx_ena: process (clk, reset)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        clock_count <= 0;
        tx_ena      <= '0';
      elsif clock_count = tx_baud_div then
        tx_ena      <= '1';
        clock_count <= 0;
      else
        clock_count <= clock_count +1;
        tx_ena      <= '0';
      end if; 
    end if;
  end process make_tx_ena;

end architecture var_baudrate_generator_8b10b_arch;
