-------------------------------------------------------
-- Design Name : rx_ctrl_8b10b 
-- File Name   : rx_ctrl_8b10b.vhd
-- Function    : controlling the 8b10b reception
-- Coder       : K.-H. Sulanke, DESY
-- Date        : 2018-10-18
-------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;

entity rx_ctrl_8b10b is
   port(
        com_reset              :in  std_logic;   -- communication com_reset
        com_clk                :in  std_logic;   -- communication clock
        dec_8b10b_out          :in  std_logic_vector (7 downto 0); --
        dec_8b10b_valid        :in  std_logic;   --
        dec_8b10b_ko           :in  std_logic;   -- decoder output is comma
        STF_COMMA_a            :in  std_logic_vector (7 downto 0); -- start of frame comma
        EOF_COMMA_a            :in  std_logic_vector (7 downto 0);  -- end of frame comma        
        rx_fifo_almost_full_a  :in  std_logic;
        rx_fifo_wr_en_a        :out std_logic;   -- pulse of one clock length
        STF_COMMA_b            :in  std_logic_vector (7 downto 0); -- start of frame comma
        EOF_COMMA_b            :in  std_logic_vector (7 downto 0);  -- end of frame comma
        rx_fifo_almost_full_b  :in  std_logic;
        rx_fifo_wr_en_b        :out std_logic;   -- pulse of one clock length
        rx_fifo_din            :out std_logic_vector (7 downto 0) -- shared by both Rx_fifos
       );
end entity;

architecture rx_ctrl_8b10b_arch of rx_ctrl_8b10b is
 	 
	type state_type is (RX_IDLE, RX_STF_A, RX_DATA_A, RX_STF_B, RX_DATA_B);
	signal state: state_type := RX_IDLE;
 
 begin

   rx_sm: process (com_clk)
	   begin
	  sync: if (rising_edge(com_clk)) then
	    
		   rx_fifo_wr_en_a  <= '0';  -- to get a single pulse of one clock period
		   rx_fifo_wr_en_b  <= '0';  -- to get a single pulse of one clock period
 
       rx_fifo_din <= dec_8b10b_out; -- one clock delay
        
     reset_if: if (com_reset = '1') then
            state         <= RX_IDLE;
          else
			  			  		
		sm_ena : if (dec_8b10b_valid ='1') then
    
			sm: case (state) is
         when RX_IDLE =>
            rx_fifo_wr_en_a <= '0';
            rx_fifo_wr_en_b <= '0';
			      if (dec_8b10b_ko = '1') and (dec_8b10b_out = STF_COMMA_a) then
			       state          <= RX_STF_A;
            end if;  
            if (dec_8b10b_ko = '1') and (dec_8b10b_out = STF_COMMA_b) then
			       state          <= RX_STF_B;
            end if;

         when RX_STF_A =>
            rx_fifo_wr_en_a <= '0';
            rx_fifo_wr_en_b <= '0';
            if     (dec_8b10b_ko = '1') and (dec_8b10b_out = EOF_COMMA_a) then
			       state         <= RX_IDLE;
            elsif  (dec_8b10b_ko = '1') and (dec_8b10b_out = EOF_COMMA_b) then
			       state         <= RX_IDLE; 
            elsif  (dec_8b10b_ko = '1') and (dec_8b10b_out = STF_COMMA_b) then
			       state         <= RX_STF_B;              
            elsif  (dec_8b10b_ko = '0') then
			       state         <= RX_DATA_A;
            end if;
 
         when RX_STF_B =>
            rx_fifo_wr_en_a <= '0';
            rx_fifo_wr_en_b <= '0';
            if     (dec_8b10b_ko = '1') and (dec_8b10b_out = EOF_COMMA_a) then
			       state         <= RX_IDLE;
            elsif  (dec_8b10b_ko = '1') and (dec_8b10b_out = EOF_COMMA_b) then
			       state         <= RX_IDLE; 
            elsif  (dec_8b10b_ko = '1') and (dec_8b10b_out = STF_COMMA_a) then
			       state         <= RX_STF_a;              
            elsif  (dec_8b10b_ko = '0') then
			       state         <= RX_DATA_B;
            end if;
 
         when RX_DATA_A =>
            if rx_fifo_almost_full_a = '0' then
             rx_fifo_wr_en_a <= '1';
            else
             rx_fifo_wr_en_a <= '0';            
            end if;
            if     (dec_8b10b_ko = '1') and (dec_8b10b_out = EOF_COMMA_a) then
			       state         <= RX_IDLE;
            elsif  (dec_8b10b_ko = '1') and (dec_8b10b_out = EOF_COMMA_b) then
			       state         <= RX_IDLE; 
            elsif  (dec_8b10b_ko = '1') and (dec_8b10b_out = STF_COMMA_b) then
			       state         <= RX_STF_B; 
            end if;              

         when RX_DATA_B =>
            if rx_fifo_almost_full_b = '0' then
             rx_fifo_wr_en_b <= '1';
            else
             rx_fifo_wr_en_b <= '0';            
            end if;
            if     (dec_8b10b_ko = '1') and (dec_8b10b_out = EOF_COMMA_a) then
			       state         <= RX_IDLE;
            elsif  (dec_8b10b_ko = '1') and (dec_8b10b_out = EOF_COMMA_b) then
			       state         <= RX_IDLE; 
            elsif  (dec_8b10b_ko = '1') and (dec_8b10b_out = STF_COMMA_a) then
			       state         <= RX_STF_A; 
            end if;   
 
        end case sm;
    end if sm_ena;
   end if reset_if;
  end if sync;
 end process rx_sm;
 
end architecture rx_ctrl_8b10b_arch;
