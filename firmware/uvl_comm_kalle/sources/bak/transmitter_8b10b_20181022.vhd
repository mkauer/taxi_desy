-------------------------------------------------------
-- Design Name : transmitter_8b10b 
-- File Name   : transmitter_8b10b.vhd
-- Function    : Simple 8b10b transmitter
-- Coder       : K.-H. Sulanke, DESY
-- Date        : 2018-10-22
-------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;

entity transmitter_8b10b is
   port(
        com_reset        :in  std_logic;
        com_clk          :in  std_logic;
        tx_run_8b10b     :in  std_logic; -- like tx_fifo_not_empty
        tx_data_in_8b10b :in  std_logic_vector (9 downto 0);
        tx_ena_8b10b     :in  std_logic; -- from baudrate generator
        enc_ena_8b10b    :out std_logic; -- single clock pulse
        tx_fifo_rd       :out std_logic; -- single clock pulse
        tx_done_8b10b    :out std_logic; -- single clock pulse
		    tx_out_8b10b     :out std_logic  -- serial data out
       );
end entity;

architecture transmitter_8b10b_arch of transmitter_8b10b is
 
  signal tx_reg              : std_logic_vector (9 downto 0);
  signal tx_cnt              : natural range 0 to 9;
 	 
	type state_type is (IDLE,  SEND_DATA);
	signal state: state_type := IDLE;
 
 begin
 
 -- signal tx_out_8b10b is delayed by one tx_ena_8b10b-cycle with respect to state !
 
   tx_sm: process (com_clk)
	   begin
	    sync: if (rising_edge(com_clk)) then 
		    tx_done_8b10b    <= '0';  -- to get a single pulse of one clock period
	      tx_fifo_rd       <= '0';
        enc_ena_8b10b    <= '0';
        
        com_reset_if : if (com_reset = '1') then
        
           state         <= IDLE;
           enc_ena_8b10b <= '1';
         else
         
		sm_ena : if (tx_ena_8b10b ='1') then
			sm: case (state) is
         when IDLE =>
            enc_ena_8b10b <= '1';
            tx_cnt        <=  0;
 			      if (tx_run_8b10b = '1') then
			       	tx_reg      <= tx_data_in_8b10b;
			        state       <= SEND_DATA;
            end if;
 
         when SEND_DATA =>
           
             tx_reg(8 downto 0) <= tx_reg(9 downto 1);
             tx_reg(9)       <= '0';
             if (tx_cnt = 5) then
              tx_done_8b10b  <= '1';
             end if;
             if (tx_cnt = 7) then
              tx_fifo_rd    <= '1';
             end if;             
             if (tx_cnt = 8) then
              enc_ena_8b10b  <= '1';
             end if;            
             if (tx_cnt = 9) then
--            tx_done_8b10b  <= '1';
              tx_cnt         <= 0;
              if (tx_run_8b10b = '0') then
               state        <= IDLE;
              else
               tx_reg       <= tx_data_in_8b10b;              
              end if;
             else              
              tx_cnt        <= tx_cnt +1;
             end if; --(tx_cnt = 9) 
        end case sm;
     end if sm_ena;
    end if com_reset_if;
   end if sync;
  end process tx_sm; 
  
  tx_out_8b10b <= '0' when state=IDLE else tx_reg(0);
  
 end architecture transmitter_8b10b_arch;
