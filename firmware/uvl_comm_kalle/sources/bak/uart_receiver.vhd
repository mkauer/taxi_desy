-------------------------------------------------------
-- Design Name : uart_receiver 
-- File Name   : uart_receiver.vhd
-- Function    : Simple UART receiver with 10 fold oversampling
-- Coder       : K.-H. Sulanke, DESY
-- Date        : 2018-10-12
-------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_bit.all;

entity uart_receiver is
  port(
    reset          : in  std_logic;
    clk            : in  std_logic;
    rx_ena         : in  std_logic;        -- single clock length pulse from baudrate generator
    rx_in          : in  std_logic;        -- serial data on the line
    rx_run_baudgen : out std_logic;        -- run baudrate generator if needed only
    rx_data_out    : out std_logic_vector (7 downto 0);  -- parallel out
    rx_data_valid  : out std_logic         -- single clock length pulse
    );
end entity;

architecture uart_receiver_arch of uart_receiver is

  signal rx_in1     : std_logic             := '0';
  signal rx_in2     : std_logic             := '0';
  signal rx_reg     : std_logic_vector (7 downto 0):= X"00";
  signal sample_cnt : integer range 0 to  9 := 0;
  signal bit_cnt    : integer range 0 to 10 := 0;

  type state_type is (IDLE, REC_START, REC_DATA, REC_STOP);
  signal state : state_type := IDLE;

begin
  -- purpose: receive data 1_8_1_nP
  -- RS232 transceiver circuit uses internal inverters !!!


  rx_baudgen : process (clk)
  begin
    if (rising_edge(clk)) then
      if (reset = '1') or
        (rx_ena='1' and sample_cnt=5 and bit_cnt=10) then
        rx_run_baudgen <= '0';
      elsif  rx_in2 = '0' then
        rx_run_baudgen <= '1';
      end if;
    end if;
  end process rx_baudgen;   
        
  rx_counter : process (clk)
  begin
    if (rising_edge(clk)) then
      if (reset = '1' or state = IDLE) then
        sample_cnt   <= 0;
        bit_cnt      <= 0;
      elsif (rx_ena = '1') then
        if (sample_cnt = 5) then
          if (bit_cnt /= 10) then
            bit_cnt  <= bit_cnt+1;
          else
            bit_cnt  <= 0; 
          end if;
        end if;
        if (sample_cnt = 9) then
          sample_cnt <= 0;
        else
          sample_cnt <= sample_cnt + 1;
        end if;
      end if;
    end if;
  end process rx_counter;

  rx_sm  : process (clk)
  begin
    sync : if (rising_edge(clk)) then

      rx_in1 <= rx_in;                  -- synchronize asynchronous input signal
      rx_in2 <= rx_in1;
      
      rx_data_valid <= '0';           -- to get a single pulse of one clock period
     
    reset_if:  
      if (reset = '1') then
        state         <= IDLE;
      else 
        
      sm_ena : if (rx_ena = '1') then
        sm   : case (state) is
          when IDLE =>
            --rx_data_out <= X"00";
            if (rx_in2 = '0') then
              state    <= REC_START;
            end if;

          when REC_START =>
            if (sample_cnt = 5) then
              state <= REC_DATA;
            end if;

          when REC_DATA =>
            if (sample_cnt = 5) then
              if (bit_cnt = 9) then
                rx_data_out        <= rx_reg;
                state              <= REC_STOP;
              else
                rx_reg(7)          <= rx_in2;
                rx_reg(6 downto 0) <= rx_reg(7 downto 1);
              end if;
            end if;

          when REC_STOP =>
            if (sample_cnt = 5) then
              rx_data_valid <= '1';
              state         <= IDLE;
            end if;

        end case sm;
      end if sm_ena;
     end if reset_if;
    end if sync;
  end process rx_sm;
end architecture uart_receiver_arch;
