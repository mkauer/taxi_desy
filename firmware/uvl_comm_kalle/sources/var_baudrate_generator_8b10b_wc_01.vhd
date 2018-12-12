-----------------------------------------------------------------------------------
-- Design Name : var_baudrate_generator_8b10b 
-- File Name   : var_baudrate_generator_8b10b.vhd
-- Function    : generate tx enables from the system clock
--               with 10 fold oversampling, according to the baudrate_ctrl setting
-- Coder       : K.-H. Sulanke, DESY
-- Date        : 2018-11-28
------------------------------------------------------------------------------------
-- rx_ena added to deal with the low baud rate, required due to the winch cable loss
-- rx_ena used to set the  comms ADC clock rate -> ADC clock is rx_ena-frequency  / 2

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity var_baudrate_generator_8b10b is
  port ( reset          : in  std_logic;
         clk            : in  std_logic;
         baudrate_adj   : in std_logic_vector(3 downto 0);
         tx_ena         : out std_logic;
			rx_ena         : out std_logic
         );
end entity var_baudrate_generator_8b10b;

architecture var_baudrate_generator_8b10b_arch of var_baudrate_generator_8b10b is

  constant MAX_TX_BAUD_DIV : natural := 3_000;
  constant MAX_RX_BAUD_DIV : natural := 300;
  
  signal tx_baud_div : natural range 0 to 3_000;
  signal rx_baud_div : natural range 0 to 300;
  
  signal tx_clock_count : natural range 0 to MAX_TX_BAUD_DIV;  
  signal rx_clock_count : natural range 0 to MAX_RX_BAUD_DIV;  
  
  begin

  --tx_baud_div <= (SYS_CLOCK / baudrate) -1;

  set_baudrate: process (clk)
   begin
   if rising_edge(clk) then
     if reset = '1' then
      tx_baud_div <= 600 - 1;  rx_baud_div <=    15 - 1; 
     else 
       if tx_clock_count = tx_baud_div then  -- for synchronized changing of the baudrate    
        case baudrate_adj is
         when X"0"   => tx_baud_div <=   3000 - 1; rx_baud_div <=    75 - 1; --   20_000 baud  150 - 1;
         when X"1"   => tx_baud_div <=   2000 - 1; rx_baud_div <=    50 - 1; --   30_000 baud  100 - 1;
         when X"2"   => tx_baud_div <=   1500 - 1; rx_baud_div <=    37 - 1; --   40_000 baud   75 - 1;
         when X"3"   => tx_baud_div <=   1200 - 1; rx_baud_div <=    30 - 1; --   50_000 baud   60 - 1;
         when X"4"   => tx_baud_div <=    600 - 1; rx_baud_div <=    15 - 1; --  100_000 baud   30 - 1;
         when X"5"   => tx_baud_div <=    400 - 1; rx_baud_div <=    10 - 1; --  150_000 baud   20 - 1;
         when X"6"   => tx_baud_div <=    300 - 1; rx_baud_div <=     7 - 1; --  200_000 baud   15 - 1;
         when X"7"   => tx_baud_div <=    200 - 1; rx_baud_div <=     5 - 1; --  300_000 baud   10 - 1;
         when X"8"   => tx_baud_div <=    120 - 1; rx_baud_div <=     3 - 1; --  500_000 baud    6 - 1;
         when X"9"   => tx_baud_div <=     60 - 1; rx_baud_div <=     2 - 1; -- 1000_000 baud    3 - 1;
                                                            
         when others => tx_baud_div <= 600 - 1;  rx_baud_div <=  15 - 1;              
        end case;
       end if; -- tx_ena = '1'
      end if; -- reset = '1' 
     end if; -- rising_edge(clk)   
   end process set_baudrate; 
        
  make_tx_ena: process (clk, reset)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        tx_clock_count <= 0;
        tx_ena         <= '0';
      elsif tx_clock_count = tx_baud_div then
        tx_ena         <= '1';
        tx_clock_count <= 0;
      else
        tx_clock_count <= tx_clock_count +1;
        tx_ena         <= '0';
      end if; 
    end if;
  end process make_tx_ena;

  make_rx_ena: process (clk, reset)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        rx_clock_count <= 0;
        rx_ena         <= '0';
      elsif rx_clock_count = rx_baud_div then
        rx_ena         <= '1';
        rx_clock_count <= 0;
      else
        rx_clock_count <= rx_clock_count +1;
        rx_ena         <= '0';
      end if; 
    end if;
  end process make_rx_ena;


end architecture var_baudrate_generator_8b10b_arch;
