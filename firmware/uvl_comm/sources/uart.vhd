-------------------------------------------------------
-- Design Name : uart
-- File Name   : uart.vhd
-- Function    : Simple UART
-- Coder       : K.-H. Sulanke, DESY
-- Date        : 2018-10-22  
-------------------------------------------------------
-- last change : signals tx_run_baudgen, rx_run_baudgen, tx_busy removed

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

--library altera_mf;
--use altera_mf.all;

entity uart is
  port(
    reset          : in std_logic;
    clk            : in std_logic;

    tx_data_valid  : in  std_logic;
    tx_data_in     : in  std_logic_vector (7 downto 0);
    tx_busy        : out std_logic;
    tx_ack         : out std_logic;
    tx_out         : out std_logic;

    rx_in          : in  std_logic;
    rx_data_out    : out std_logic_vector (7 downto 0);
    rx_data_valid  : out std_logic
     );
end entity;

architecture uart_arch of uart is

  component uart_baudrate_generator
    port(
      reset          : in  std_logic;
      clk            : in  std_logic;
      tx_ena         : out std_logic;
      rx_ena         : out std_logic
      );
  end component uart_baudrate_generator;

  component uart_transmitter
    port(
      reset          : in  std_logic;
      clk            : in  std_logic;
      tx_data_valid  : in  std_logic;
      tx_data_in     : in  std_logic_vector (7 downto 0);
      tx_ena         : in  std_logic;
      tx_ack         : out std_logic;
      tx_out         : out std_logic
      );
  end component uart_transmitter;

  component uart_receiver
    port
      (
      reset          : in  std_logic;
      clk            : in  std_logic;
      rx_ena         : in  std_logic;
      rx_in          : in  std_logic;
      rx_data_out    : out std_logic_vector (7 downto 0);
      rx_data_valid  : out std_logic
      );
  end component uart_receiver;

  signal rx_ena         : std_logic                     := 'U';
  signal tx_ena         : std_logic                     := 'U';

begin

  -- purpose: send / receive data 1_8_1_nP
  -- RS232 transceiver circuit uses internal inverters !!!

  baud : uart_baudrate_generator port map
    (
      reset          => reset,
      clk            => clk,
      tx_ena         => tx_ena,
      rx_ena         => rx_ena
      );

  xmit : uart_transmitter port map
    (
      reset          => reset,
      clk            => clk,
      tx_data_valid  => tx_data_valid,
      tx_data_in     => tx_data_in,
      tx_ena         => tx_ena,
      tx_ack         => tx_ack,
      tx_out         => tx_out
      );

  rec : uart_receiver port map
    (
      reset          => reset,
      clk            => clk,
      rx_ena         => rx_ena,
      rx_in          => rx_in,
      rx_data_out    => rx_data_out,
      rx_data_valid  => rx_data_valid
      );

end architecture uart_arch;
