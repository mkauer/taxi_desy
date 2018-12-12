-------------------------------------------------------
-- Design Name : baudrate_generator_8b10b 
-- File Name   : baudrate_generator_8b10b.vhd
-- Function    : generate tx and rx enables from the system clock
--               with 10 fold oversampling
-- Coder       : K.-H. Sulanke, DESY
-- Date        : 2018-10-22
-------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity baudrate_generator_8b10b is
  port ( reset          : in  std_logic;
         clk            : in  std_logic;
         tx_ena         : out std_logic;
         rx_ena         : out std_logic
         );
end entity baudrate_generator_8b10b;

architecture baudrate_generator_8b10b_arch of baudrate_generator_8b10b is

  constant BAUD_RATE    : natural := 3000_000;--6_000_000;-- 256_000, 2_000_000
  constant RX_BAUD_DIV  : natural := (120_000_000 / BAUD_RATE / 10) -1 ; 
  constant TX_BAUD_DIV  : natural := (120_000_000 / BAUD_RATE) -1; 
  
begin
  
  make_rx_ena            : process (clk, reset)
    variable clock_count : integer range 0 to RX_BAUD_DIV := 0;
  begin
    if rising_edge(clk) then
      if reset = '1' then
        clock_count := 0;
        rx_ena <= '0';
      elsif clock_count = RX_BAUD_DIV then
        rx_ena <= '1';
        clock_count:= 0;
      else
        clock_count := clock_count +1;
        rx_ena <= '0';
      end if;
    end if; 
  end process make_rx_ena;

  make_tx_ena            : process (clk, reset)
    variable clock_count : integer range 0 to TX_BAUD_DIV  := 0;
  begin
    if rising_edge(clk) then
      if reset = '1' then
        clock_count := 0;
        tx_ena <= '0';
      elsif clock_count = TX_BAUD_DIV then
        tx_ena <= '1';
        clock_count := 0;
      else
        clock_count := clock_count +1;
        tx_ena <= '0';
      end if; 
    end if;
  end process make_tx_ena;

end architecture baudrate_generator_8b10b_arch;
