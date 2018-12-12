-------------------------------------------------------
-- Design Name : rx_ctrl_8b10b 
-- File Name   : rx_ctrl_8b10b.vhd
-- Function    : controlling the 8b10b reception
-- Coder       : K.-H. Sulanke, DESY
-- Date        : 2018-10-30
-- Revision    : 02
-------------------------------------------------------
-- 

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
        rx_fifo_din            :out std_logic_vector (7 downto 0); -- shared by both Rx_fifos
		  rx_ena_8b10b           :in  std_logic   -- did not work
       );
end entity;

architecture rx_ctrl_8b10b_arch of rx_ctrl_8b10b is

  type arb_state_type is (SEL_A, SEL_B);
	signal arb_state: arb_state_type := SEL_A;
 	 
	type state_type is (RX_IDLE, RX_STF, RX_DATA, RX_FWR, RX_EOF);
	signal state: state_type := RX_IDLE;
  
  signal stf_comma     : std_logic_vector (7 downto 0); 
  signal eof_comma     : std_logic_vector (7 downto 0); 
  signal rx_fifo_wr_en : std_logic;
 
 begin

  rx_arbiter_sm: process (com_clk)
    begin
     if (rising_edge(com_clk)) then
      if com_reset = '1' then
       arb_state     <= SEL_A;
      else--if rx_ena_8b10b = '1' then
 	   arb_sm: case (arb_state) is
     
      when SEL_A =>
       if (dec_8b10b_ko = '1') and (dec_8b10b_valid ='1') and (dec_8b10b_out = STF_COMMA_b) then
         arb_state <= SEL_B;
       end if;
 
      when SEL_B =>
        if (dec_8b10b_ko = '1') and (dec_8b10b_valid ='1') and (dec_8b10b_out = STF_COMMA_a) then
         arb_state <= SEL_A;
       end if;

      end case arb_sm;
    end if; --  com_reset = '1'
   end if; -- rising_edge(com_clk))
  end process rx_arbiter_sm; 


    stf_comma       <= STF_COMMA_a when (arb_state = SEL_A) else
                       STF_COMMA_b when (arb_state = SEL_B) else X"00";
    eof_comma       <= EOF_COMMA_a when (arb_state = SEL_A) else 
                       EOF_COMMA_b when (arb_state = SEL_B) else X"00";


   rx_sm: process (com_clk)
	   begin
	  sync: if (rising_edge(com_clk)) then
	    
		 --rx_fifo_wr_en  <= '0';  -- to get a single pulse of one clock period
         
     reset_if: if (com_reset = '1') then
            state         <= RX_IDLE;
				
          else--if rx_ena_8b10b = '1' then
			  			  		
--		sm_ena : if (dec_8b10b_valid ='1') then
    
			sm: case (state) is
         when RX_IDLE =>
            rx_fifo_wr_en <= '0';
			      if (dec_8b10b_ko = '1') and (dec_8b10b_valid ='1') and (dec_8b10b_out = stf_comma) then
			       state          <= RX_STF;
            end if;  
 
         when RX_STF =>
            if     (dec_8b10b_ko = '1') and (dec_8b10b_valid ='1') and (dec_8b10b_out = eof_comma) then
			       state         <= RX_IDLE;
            elsif  (dec_8b10b_ko = '0') and (dec_8b10b_valid ='1') then
             rx_fifo_wr_en <= '1';
			       state         <= RX_FWR;
            end if;
            
         when RX_FWR =>
             rx_fifo_wr_en <= '0';
			       state         <= RX_DATA;

         when RX_DATA =>
            if     (dec_8b10b_ko = '1') and (dec_8b10b_valid ='1')  and (dec_8b10b_out = eof_comma) then
			       state         <= RX_EOF;
            elsif  (dec_8b10b_ko = '1') and (dec_8b10b_valid ='1')  and (dec_8b10b_out = stf_comma) then
			       state         <= RX_STF;
            elsif  (dec_8b10b_ko = '0') and (dec_8b10b_valid ='1') then
             rx_fifo_wr_en <= '1';
			       state         <= RX_FWR;             
            end if;              

         when RX_EOF =>
            if     (dec_8b10b_ko = '1') and (dec_8b10b_valid ='1') and (dec_8b10b_out = eof_comma) then
			       state         <= RX_IDLE;
            elsif  (dec_8b10b_ko = '1') and (dec_8b10b_valid ='1')  and (dec_8b10b_out = stf_comma) then
			       state         <= RX_STF; 
            end if;

 
        end case sm;
--    end if sm_ena;
   end if reset_if;
  end if sync;
 end process rx_sm;

    rx_fifo_din     <= dec_8b10b_out;
    rx_fifo_wr_en_a <= '1' when (arb_state = SEL_A) and (rx_fifo_wr_en = '1') and (rx_fifo_almost_full_a = '0') else '0';
    rx_fifo_wr_en_b <= '1' when (arb_state = SEL_B) and (rx_fifo_wr_en = '1') and (rx_fifo_almost_full_b = '0') else '0';
    
 
end architecture rx_ctrl_8b10b_arch;
