-----------------------------------------------------------------------------------
-- Design Name : var_baudrate_generator_8b10b 
-- File Name   : var_baudrate_generator_8b10b.vhd
-- Function    : generate tx enables from the system clock
--               with 10 fold oversampling, according to the baudrate_ctrl setting
-- Coder       : K.-H. Sulanke, DESY
-- Date        : 2018-11-02
------------------------------------------------------------------------------------
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

    constant SYS_CLOCK  : natural := 120_000_000;

  --constant BAUD_RATE    : natural := 3000_000;--6_000_000;-- 256_000, 2_000_000
  --constant RX_BAUD_DIV  : natural := (120_000_000 / BAUD_RATE / 10) -1 ; 
  --constant TX_BAUD_DIV  : natural := (120_000_000 / BAUD_RATE) -1; 
  
  --constant MIN_BAUDRATE   : natural := 50_000;
  
  --signal baudrate    : natural range 0 to 120_000_000 := 50_000;  -- init needed for simulation !!!  
  signal tx_baud_div : natural range 0 to 120_000_000;
  signal clock_count : natural range 0 to 120_000_000;  
  
begin

  --tx_baud_div <= (SYS_CLOCK / baudrate) -1;

  set_baudrate: process (clk)
   begin
   if rising_edge(clk) then
     if reset = '1' then
      tx_baud_div    <=  20_000 - 1;
     else 
       if clock_count = tx_baud_div then      
        case baudrate_adj is
         when X"0"   => tx_baud_div <= 20_000 - 1; --    6_000 baud
         when X"1"   => tx_baud_div <= 10_000 - 1; --   12_000 baud
         when X"2"   => tx_baud_div <=  4_800 - 1; --   25_000 baud
         when X"3"   => tx_baud_div <=  2_400 - 1; --   50_000 baud
         when X"4"   => tx_baud_div <=  1_200 - 1; --  100_000
         when X"5"   => tx_baud_div <=    480 - 1; --  250_000
         when X"6"   => tx_baud_div <=    240 - 1; --  500_000
         when X"7"   => tx_baud_div <=    160 - 1; --  750_000
         when X"8"   => tx_baud_div <=    120 - 1; -- 1000_000
         when X"9"   => tx_baud_div <=     80 - 1; -- 1500_000
         when X"a"   => tx_baud_div <=     60 - 1; -- 2000_000 
         when X"b"   => tx_baud_div <=     48 - 1; -- 2500_000 
         when X"c"   => tx_baud_div <=     40 - 1; -- 3000_000
         when X"d"   => tx_baud_div <=     30 - 1; -- 4000_000
         when X"e"   => tx_baud_div <=     24 - 1; -- 5000_000
         when X"f"   => tx_baud_div <=     20 - 1; -- 6000_000
         
         when others => tx_baud_div <= 20_000 - 1;
        end case;
       end if; -- tx_ena = '1'
      end if; -- reset = '1' 
     end if; -- rising_edge(clk)   
   end process set_baudrate; 
        
        
  make_tx_ena            : process (clk, reset)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        clock_count <= 0;
        tx_ena <= '0';
      elsif clock_count = tx_baud_div then
        tx_ena <= '1';
        clock_count <= 0;
      else
        clock_count <= clock_count +1;
        tx_ena <= '0';
      end if; 
    end if;
  end process make_tx_ena;

end architecture var_baudrate_generator_8b10b_arch;
