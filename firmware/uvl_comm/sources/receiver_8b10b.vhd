-------------------------------------------------------
-- Design Name : receiver_8b10b 
-- File Name   : receiver_8b10b.vhd
-- Function    : Simple 8b10b receiver with 10 fold oversampling
-- Coder       : K.-H. Sulanke, DESY
-- Date        : 2018-10-15
-------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_bit.all;

entity receiver_8b10b is
  port(
    reset           : in  std_logic;
    clk             : in  std_logic;
    rx_ena          : in  std_logic;        -- single clock length pulse from baudrate generator
    dec_8b10b_reset : out std_logic;
    rx_in           : in  std_logic;        -- serial data on the line
    rx_data_out     : out std_logic_vector (9 downto 0);  -- parallel out
    rx_data_valid   : out std_logic;        -- single clock length pulse
    dec_8b10b_valid : out std_logic         -- delayed by one clock rx_data_valid to deal with the decoder latency
    );
end entity;

architecture receiver_8b10b_arch of receiver_8b10b is

  constant K28_0P  : std_logic_vector (9 downto 0):= B"1101_000011";
  constant K28_0M  : std_logic_vector (9 downto 0):= B"0010_111100";
  constant K28_2P  : std_logic_vector (9 downto 0):= B"0101_000011";
  constant K28_2M  : std_logic_vector (9 downto 0):= B"1010_111100";
  constant K28_4P  : std_logic_vector (9 downto 0):= B"1011_000011";
  constant K28_4M  : std_logic_vector (9 downto 0):= B"0100_111100";
  constant K28_6P  : std_logic_vector (9 downto 0):= B"1001_000011";
  constant K28_6M  : std_logic_vector (9 downto 0):= B"0110_111100";
 
  constant MAX_PACKET_SIZE   : natural := 1024; -- max. amount of data bytes per packet 
  constant NO_EDGES_TIME_OUT : natural := 5;
  constant NO_COMMA_TIME_OUT : natural := (MAX_PACKET_SIZE + 4) * 10;
 
  signal rx_in1           : std_logic := '0';
  signal rx_in2           : std_logic := '0';
  signal rx_lh            : std_logic := '0';
  signal rx_hl            : std_logic := '0';
  signal rx_in_reg        : std_logic_vector (9 downto 0):= B"00" & X"00";
  --signal rx_reg           : std_logic_vector (9 downto 0):= B"00" & X"00";
  signal sample_cnt       : natural range 0 to 9 := 0;
  signal bit_cnt          : natural range 0 to 9 := 0;
  signal no_edge_ct       : natural range 0 to NO_EDGES_TIME_OUT := 0;
  signal no_comma_ct      : natural range 0 to NO_COMMA_TIME_OUT := 0;
  signal sync_loss        : std_logic := '0';
  signal rx_data_valid_nd : std_logic := '0';
  
  
  signal comma       : std_logic_vector (9 downto 0);
  signal comma_valid : std_logic := '0';
  signal rx_syncd    : std_logic := '0';

 begin
  -- purpose: receive 8b10b data
   
  get_edges : process (reset,clk)
   begin
    if (rising_edge(clk)) then
      if (reset = '1') then  
       rx_in1  <= '0';
       rx_in2  <= '0';
       rx_lh   <= '0';
       rx_hl   <= '0';
      else       
       rx_in1 <= rx_in;   -- synchronize asynchronous input signal
       rx_in2 <= rx_in1;
       if rx_in = '1' and rx_in1 = '1' and rx_in2 = '0' then
         rx_lh <= '1';
       end if;          
       if rx_in = '0' and rx_in1 = '0' and rx_in2 = '1' then
         rx_hl <= '1';
       end if;
       if rx_ena = '1' and rx_lh = '1' then
         rx_lh <= '0';
       end if;
       if rx_ena = '1' and rx_hl = '1' then       
         rx_hl <= '0';
       end if;
      end if; -- (reset = '1') 
     end if; -- (rising_edge(clk))
   end process get_edges;    

    comma_valid <= '1' when 
       (rx_in_reg = K28_0M) or (rx_in_reg = K28_0P) or
       (rx_in_reg = K28_2M) or (rx_in_reg = K28_2P) or 
       (rx_in_reg = K28_4M) or (rx_in_reg = K28_4P) or 
       (rx_in_reg = K28_6M) or (rx_in_reg = K28_6P)   
     else '0';

  rx_sync : process (clk)
  begin
    if (rising_edge(clk)) then
       if (reset = '1') or (sync_loss = '1') then
        rx_syncd <= '0';
       elsif comma_valid = '1' then -- wait for the very first comma operator
        rx_syncd <= '1'; 
       end if;
    end if; -- (rising_edge(clk))
  end process rx_sync;  
 
  sync_loss_gen: process (clk)  -- comma_valid should be included
  begin
    if (rising_edge(clk)) then
       sync_loss <= '0';   -- to get single pulses
       if (reset = '1') then
        no_comma_ct <= 0;
        no_edge_ct  <= 0;
        sync_loss   <= '0';
       elsif (rx_ena = '1') then 
        if  (sample_cnt = 9) then
         if rx_lh = '1' or rx_hl = '1' then 
          no_edge_ct <= 0;
         else        
          no_edge_ct <= no_edge_ct + 1;
         end if; --rx_lh = '1' or rx_hl = '1'
         if comma_valid = '1' then 
          no_comma_ct <= 0;
         else        
          no_comma_ct <= no_comma_ct + 1;
         end if; --comma_valid = '1'
         if (no_edge_ct = NO_EDGES_TIME_OUT) or (no_comma_ct = NO_COMMA_TIME_OUT) then
          sync_loss  <= '1';
          no_edge_ct <= 0;
         end if;
        end if; --(sample_cnt = 4)  
       end if; --(reset = '1')  
     end if;  --(rising_edge(clk))
    end process sync_loss_gen; 
 
  rx_strobes : process (clk)
  begin
    if (rising_edge(clk)) then
      rx_data_valid_nd <= '0'; -- to get a single clock length pulse
      dec_8b10b_valid  <= rx_data_valid_nd;
      if (reset = '1') then
        sample_cnt   <= 0;
        bit_cnt      <= 0;
        rx_in_reg    <= B"00" & X"00";
      elsif (rx_ena = '1') then
       if rx_lh = '1' or rx_hl = '1' or sample_cnt = 9 then
        sample_cnt <= 0;
       else
        sample_cnt <= sample_cnt + 1;
       end if;            
       if (sample_cnt = 4) then
        rx_in_reg(9) <= rx_in2;
        rx_in_reg(8 downto 0) <= rx_in_reg(9 downto 1); 
--        rx_reg(9) <= rx_in2;
--        rx_reg(8 downto 0) <= rx_reg(9 downto 1); 
        if (rx_syncd = '1') then 
         if (bit_cnt = 9) or (comma_valid = '1')  then
          bit_cnt            <= 0;
          rx_data_out        <= rx_in_reg;
          rx_data_valid_nd   <= '1';
--          rx_reg(8 downto 0) <= B"0" & X"00";
         else       
          bit_cnt  <= bit_cnt+1;
         end if; --(bit_cnt = 9) or (comma_valid = '1')
        else
         bit_cnt  <= 0;        
        end if; --(rx_syncd = '1') 
       end if; --(sample_cnt = 5)
      end if; -- (reset = '1') 
    end if; --(rising_edge(clk))
  end process rx_strobes;
  
  rx_data_valid   <= rx_data_valid_nd;
  dec_8b10b_reset <= not rx_syncd; 

end architecture receiver_8b10b_arch;
