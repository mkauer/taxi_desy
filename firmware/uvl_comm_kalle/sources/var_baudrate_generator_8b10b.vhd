-----------------------------------------------------------------------------------
-- Design Name : var_baudrate_generator_8b10b 
-- File Name   : var_baudrate_generator_8b10b.vhd
-- Function    : according to the baudrate_adj setting
--               generates from the system clock (60 MHz) tx_ena  and rx_ena
--               with 10 fold oversampling of the bipolar pulses, used to encode the 8b10b
--               signal edges. The latter pulse length is half (!) of the 8b10b bit length.
--
-- Coder       : K.-H. Sulanke, DESY
-- Date        : 2018-11-29
-- Revision    : 02
------------------------------------------------------------------------------------
-- rx_ena is used to set the comms ADC clock rate -> ADC clock is rx_ena-frequency  / 2
-- set in a way, that it gives 10 samples for the bipolar waveform always

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

  constant MAX_TX_BAUD_DIV : natural := 3_200;
  constant MAX_RX_BAUD_DIV : natural := 80;
  
  signal tx_baud_div : natural range 0 to MAX_TX_BAUD_DIV;
  signal rx_baud_div : natural range 0 to MAX_RX_BAUD_DIV;
  
  signal tx_clock_count : natural range 0 to MAX_TX_BAUD_DIV;  
  signal rx_clock_count : natural range 0 to MAX_RX_BAUD_DIV;  
  
  begin

  --tx_baud_div <= (SYS_CLOCK / baudrate) -1;

  set_baudrate: process (clk)
   begin
   if rising_edge(clk) then
     if reset = '1' then
      tx_baud_div <= 400 - 1; rx_baud_div <= 10 - 1; --  150_000 baud
     else 
       if tx_clock_count = tx_baud_div then  -- for synchronized changing of the baudrate    
        case baudrate_adj is
         when X"0"   => tx_baud_div <=   2400 - 1; rx_baud_div <=    60 - 1; --   25_000 baud
         when X"1"   => tx_baud_div <=   1200 - 1; rx_baud_div <=    30 - 1; --   50_000 baud
         when X"2"   => tx_baud_div <=    600 - 1; rx_baud_div <=    15 - 1; --  100_000 baud
         when X"3"   => tx_baud_div <=    480 - 1; rx_baud_div <=    12 - 1; --  125_000 baud
         when X"4"   => tx_baud_div <=    400 - 1; rx_baud_div <=    10 - 1; --  150_000 baud
         when X"5"   => tx_baud_div <=    240 - 1; rx_baud_div <=     6 - 1; --  250_000 baud
         when X"6"   => tx_baud_div <=    160 - 1; rx_baud_div <=     4 - 1; --  375_000 baud
         when X"7"   => tx_baud_div <=    120 - 1; rx_baud_div <=     3 - 1; --  500_000 baud
			
         when others => tx_baud_div <=    400 - 1; rx_baud_div <=    10 - 1; --  150_000 baud       
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
