-------------------------------------------------------
-- Design Name : uart_receiver 
-- File Name   : uart_receiver.vhd
-- Function    : Simple UART receiver with 10 fold oversampling
-- Coder       : K.-H. Sulanke, DESY
-- Date        : 2018-10-29
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
    rx_data_out    : out std_logic_vector (7 downto 0);  -- parallel out
    rx_data_valid  : out std_logic         -- single clock length pulse
    );
end entity;

architecture uart_receiver_arch of uart_receiver is

  signal rx_in1     : std_logic             := '0';
  signal rx_in2     : std_logic             := '0';
  signal rx_reg     : std_logic_vector (9 downto 0):= B"00" & X"00";
  signal sample_cnt : integer range 0 to 9 := 0; -- tenfold oversampling used here
  signal bit_cnt    : integer range 0 to 9 := 0; -- 1_8_1_nP

  type state_type is (REC_IDLE, REC_BITS);
  signal state : state_type := REC_IDLE;

begin
  -- purpose: receive data 1_8_1_nP
  -- RS232 transceiver circuit uses internal inverters !!!
       
  rx_counter : process (clk)
  begin
    if (rising_edge(clk)) then
      if (reset = '1') or (state = REC_IDLE) then
        sample_cnt   <= 0;
        bit_cnt      <= 0;
      elsif (rx_ena = '1') then
        if (sample_cnt = 4) then
          if (bit_cnt /= 9) then
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
         state        <= REC_IDLE;
      else 
        
      sm_ena : if (rx_ena = '1') then
        sm   : case (state) is
          when REC_IDLE =>
            if (rx_in2 = '0') then
               state    <= REC_BITS;
            end if;

          when REC_BITS =>
            if (sample_cnt = 4) then
              rx_reg(9)          <= rx_in2;
              rx_reg(8 downto 0) <= rx_reg(9 downto 1);
              if (bit_cnt = 9) then
                rx_data_out       <= rx_reg(9 downto 2);
                rx_data_valid     <= '1';
                state             <= REC_IDLE;
              end if;
            end if;  

        end case sm;
      end if sm_ena;
     end if reset_if;
    end if sync;
  end process rx_sm;
end architecture uart_receiver_arch;
