-------------------------------------------------------
-- Design Name : receiver_8b10b_waba 
-- File Name   : receiver_8b10b_waba.vhd
-- Function    : Simple 8b10b receiver with 10 fold oversampling
--               and "with automatic baudrate adjustment" (waba)
-- Coder       : K.-H. Sulanke, DESY
-- Date        : 2018-11-06
-------------------------------------------------------
-- comm. ADC clock is 60 Mhz
-- max. expected datarate is 6 Mbit/s
-- receiver with 10 fold oversampling
-- "with automatic baudrate adjustment" did not work, when using the ADC waveform
-- => to small bit length detected


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_bit.all;
use ieee.std_logic_arith.all;


entity receiver_8b10b_waba is
  port(
    reset           : in  std_logic;
    clk             : in  std_logic;
    --rx_ena          : in  std_logic;        -- single clock length pulse from baudrate generator
    dec_8b10b_reset : out std_logic;
    rx_in           : in  std_logic;        -- serial data on the line
    rx_data_out     : out std_logic_vector (9 downto 0);  -- parallel out
    rx_data_valid   : out std_logic;        -- single clock length pulse
    dec_8b10b_valid : out std_logic;         -- delayed by one clock rx_data_valid to deal with the decoder latency
    rx_lh_nd           : out std_logic;        -- for debugging only
    rx_hl_nd           : out std_logic;        --
    rx_syncd_nd        : out std_logic;        --
    rx_data_stb        : out std_logic;       --
    bit_length_ct_ena_nd  : out std_logic       --
    );
end entity;

architecture receiver_8b10b_waba_arch of receiver_8b10b_waba is

  constant K28_0P  : std_logic_vector (9 downto 0):= B"1101_000011"; -- STF_COMMA_a
  constant K28_0M  : std_logic_vector (9 downto 0):= B"0010_111100"; 
  constant K28_2P  : std_logic_vector (9 downto 0):= B"0101_000011"; -- EOF_COMMA_a
  constant K28_2M  : std_logic_vector (9 downto 0):= B"1010_111100"; 
  constant K28_4P  : std_logic_vector (9 downto 0):= B"1011_000011"; -- STF_COMMA_b
  constant K28_4M  : std_logic_vector (9 downto 0):= B"0100_111100";
  constant K28_6P  : std_logic_vector (9 downto 0):= B"1001_000011"; -- EOF_COMMA_b
  constant K28_6M  : std_logic_vector (9 downto 0):= B"0110_111100";

  constant CLOCK_PERIOD      : natural :=     16; --  16.7 ns at   60 MHz
  constant MAX_BIT_LENGTH    : natural := 50_000; --  50.000 ns at 20 Kbit/s
  constant MIN_BIT_LENGTH    : natural :=    166; -- 166.7 ns at 6 Mbit/s
  constant MAX_POSSIBLE      : std_logic_vector := CONV_STD_LOGIC_VECTOR(MAX_BIT_LENGTH / CLOCK_PERIOD,     12); -- max. possible bitlength at 6 Kbit/s
  constant MIN_POSSIBLE      : std_logic_vector := CONV_STD_LOGIC_VECTOR(MIN_BIT_LENGTH / CLOCK_PERIOD - 4, 12); -- min. possible bitlength at 6 Mbit/s  
  constant MAX_PACKET_SIZE   : natural := 1024; -- max. amount of data bytes per packet 
  constant NO_EDGES_TIME_OUT : natural := 6;    -- 8b10b encoding, level change after max. 5 bits required
  constant NO_COMMA_TIME_OUT : natural := (MAX_PACKET_SIZE + 4) * 10;

  signal rx_in1           : std_logic := '0';
  signal rx_in2           : std_logic := '0';
  signal rx_lh            : std_logic := '0';
  signal rx_hl            : std_logic := '0';
  signal bit_length_ct_ena : std_logic := '0';
  
  signal bit_length_ct    : std_logic_vector (11 downto 0):= (others=>'0');
  signal bit_length_prev  : std_logic_vector (11 downto 0):= (others=>'0');
  signal bit_length       : std_logic_vector (11 downto 0):= (others=>'0');
  signal stb_samples      : std_logic_vector (11 downto 0):= (others=>'0');

  signal rx_in_reg        : std_logic_vector( 9 downto 0):= B"00" & X"00";
  signal sample_cnt       : std_logic_vector(11 downto 0):= (others=>'0');
  signal bit_cnt          : std_logic_vector( 3 downto 0):= (others=>'0');
  signal no_edge_ct       : natural range 0 to NO_EDGES_TIME_OUT := 0;
  signal no_comma_ct      : natural range 0 to NO_COMMA_TIME_OUT := 0;
  signal rx_data_valid_nd : std_logic := '0';
  
  signal comma            : std_logic_vector (9 downto 0);
  signal comma_valid      : std_logic := '0';
  signal eof_rcvd         : std_logic := '0';
  signal rx_syncd         : std_logic := '0';
  --signal rx_data_stb      : std_logic := '0';  -- debugging

 begin
  -- purpose: receive 8b10b data
   
  get_edges : process (reset,clk)
   begin
    if (rising_edge(clk)) then
      rx_lh   <= '0'; -- to get single pulses
      rx_hl   <= '0';
      if (reset = '1') then  
       rx_in1  <= '0';
       rx_in2  <= '0';
      else       
       rx_in1 <= rx_in;   -- synchronize asynchronous input signal
       rx_in2 <= rx_in1;
       if rx_in = '1' and rx_in1 = '1' and rx_in2 = '0' then
         rx_lh <= '1';
       end if;          
       if rx_in = '0' and rx_in1 = '0' and rx_in2 = '1' then
         rx_hl <= '1';
       end if;
      end if; -- (reset = '1') 
     end if; -- (rising_edge(clk))
   end process get_edges;

  get_sample_stb : process (reset,clk)
   begin
    if (rising_edge(clk)) then
      if (reset = '1') then  
       bit_length_ct     <= (others=>'0');
       bit_length_ct_ena <= '0';
      else
       if  (rx_hl = '1' or rx_lh = '1') and (bit_length_ct_ena = '0') then -- wait for the very first edge
        bit_length_prev   <= MAX_POSSIBLE;
        bit_length_ct_ena <= '1';
       end if;
        if bit_length_ct_ena = '1' then
         if  (rx_hl = '1') or (rx_lh = '1') then
          if (bit_length_ct < bit_length_prev) and (bit_length_ct > MIN_POSSIBLE) then
           bit_length_prev <= bit_length_ct;
           bit_length      <= bit_length_ct;
           stb_samples     <= '0' & bit_length_ct(11 downto 1);
          end if; --bit_length_ct < bit_length_prev
          bit_length_ct   <= (others=>'0');          
         elsif bit_length_ct < MAX_POSSIBLE then
          bit_length_ct   <= bit_length_ct + '1';
         end if; -- (rx_hl = '1' or rx_lh = '1')
        end if; -- bit_length_ct_ena = '1' 
       end if; -- if (reset = '1')
      end if; -- if (rising_edge(clk))
     end process  get_sample_stb;       
   

    comma_valid <= '1' when 
       (rx_in_reg = K28_0M) or (rx_in_reg = K28_0P) or
       (rx_in_reg = K28_2M) or (rx_in_reg = K28_2P) or 
       (rx_in_reg = K28_4M) or (rx_in_reg = K28_4P) or 
       (rx_in_reg = K28_6M) or (rx_in_reg = K28_6P)   
     else '0';
     
    eof_rcvd <= '1' when 
       (rx_in_reg = K28_2M) or (rx_in_reg = K28_2P) or 
       (rx_in_reg = K28_6M) or (rx_in_reg = K28_6P)
     else '0';

  sync_loss_gen: process (clk)  -- comma_valid should be included
  begin
    if (rising_edge(clk)) then
       dec_8b10b_reset <= '0';
       if (reset = '1') then
        no_comma_ct <= 0;
        no_edge_ct  <= 0;
        rx_syncd    <= '0';
       else
         if rx_lh = '1' or rx_hl = '1' then 
           no_edge_ct <= 0;
         elsif (sample_cnt = stb_samples) then       
           no_edge_ct <= no_edge_ct + 1;
         end if; --rx_lh = '1' or rx_hl = '1'
         if (sample_cnt = stb_samples) then
          if comma_valid = '1' then 
           no_comma_ct <=  0;
           rx_syncd    <= '1'; 
          else        
           no_comma_ct <= no_comma_ct + 1;
          end if; --comma_valid = '1'
          if (eof_rcvd = '1') or (no_edge_ct = NO_EDGES_TIME_OUT) or (no_comma_ct = NO_COMMA_TIME_OUT) then
           rx_syncd    <= '0'; 
           no_comma_ct <=  0;
           no_edge_ct  <=  0;
           dec_8b10b_reset <= '1';
          end if;
         end if; --(sample_cnt = stb_samples)
       end if; --(reset = '1')  
     end if;  --(rising_edge(clk))
    end process sync_loss_gen; 
 
  rx_strobes : process (clk)
  begin
    if (rising_edge(clk)) then
      rx_data_valid_nd <= '0';              -- to get a single clock length pulse
      dec_8b10b_valid  <= rx_data_valid_nd; -- one clock delay, to wait on the 8b10b decoder
      rx_data_stb      <= '0';
      if (reset = '1') then
        sample_cnt   <= (others=>'0');
        bit_cnt      <= X"0";
        rx_in_reg    <= B"00" & X"00";
        rx_data_out  <= K28_6M;--B"00" & X"00"; --K28_0P;
      else 
--      elsif (rx_ena = '1') then
       if rx_lh = '1' or rx_hl = '1' or sample_cnt = bit_length then
        sample_cnt <= (others=>'0');
       else
        sample_cnt <= sample_cnt + '1';
       end if;
       
       if (sample_cnt = stb_samples) then
        rx_data_stb  <= '1';
        rx_in_reg(9) <= rx_in2;
        rx_in_reg(8 downto 0) <= rx_in_reg(9 downto 1);
        if (rx_syncd = '1') then
         if (bit_cnt /= X"9")  then
          bit_cnt               <= bit_cnt + '1';
         else
          bit_cnt               <= X"0";
          rx_data_out           <= rx_in_reg;
          rx_data_valid_nd      <= '1';
          rx_in_reg(8 downto 0) <= B"0" & X"00"; -- fixes some impurity at other place
         end if;
        else
          bit_cnt  <= X"0";
        end if;  --(rx_syncd = '1')
       end if; -- (sample_cnt = stb_samples) 
        
      end if; -- (reset = '1') 
    end if; --(rising_edge(clk))
  end process rx_strobes;
  
  rx_data_valid   <= rx_data_valid_nd;
  --dec_8b10b_reset <= not rx_syncd; 
  rx_lh_nd        <= rx_lh;
  rx_hl_nd        <= rx_hl;
  rx_syncd_nd     <= rx_syncd;        --
 -- rx_data_stb        : out std_logic;       --
  bit_length_ct_ena_nd <= bit_length_ct_ena;       
  
end architecture receiver_8b10b_waba_arch;
