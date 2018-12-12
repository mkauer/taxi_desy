-------------------------------------------------------
-- Design Name : tx_ctrl_8b10b 
-- File Name   : tx_ctrl_8b10b.vhd
-- Function    : controlling the 8b10b transmition
-- Coder       : K.-H. Sulanke, DESY
-- Date        : 2018-11-20
-- Revision    : 02
-------------------------------------------------------
-- 

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;

entity tx_ctrl_8b10b is
   port(
        com_reset       : in  std_logic;   -- communication com_reset
        com_clk         : in  std_logic;   -- communication clock
        tx_fifo_empty_a : in  std_logic;
        tx_fifo_rd_en_a : out std_logic;   -- pulse of one clock length
        tx_fifo_dout_a  : in  std_logic_vector (7 downto 0);
        tx_fifo_empty_b : in  std_logic;
        tx_fifo_rd_en_b : out std_logic;   -- pulse of one clock length
        tx_fifo_dout_b  : in  std_logic_vector (7 downto 0);       
        STF_COMMA_a     : in  std_logic_vector (7 downto 0); -- start of frame comma
        EOF_COMMA_a     : in  std_logic_vector (7 downto 0); -- end of frame comma
        STF_COMMA_b     : in  std_logic_vector (7 downto 0); -- start of frame comma
        EOF_COMMA_b     : in  std_logic_vector (7 downto 0); -- end of frame comma
        enc_8b10b_reset : out std_logic;  -- 
        enc_8b10b_ena   : out std_logic;  --
        enc_8b10b_in    : out std_logic_vector (7 downto 0); --
        enc_comma_stb   : out std_logic;  -- encoder input is a comma operator
        tx_run_8b10b    : out std_logic;  -- start 8b10 transmitter         
        tx_ack_8b10b    : in  std_logic;  -- one clock length ready pulse
        tx_done_8b10b   : in  std_logic   -- 
       );
end entity;

architecture tx_ctrl_8b10b_arch of tx_ctrl_8b10b is

  constant FRAME_LENGTH    : natural :=    2; -- amount of STFs and EOFs per packet
  constant MAX_PACKET_SIZE : natural := 1024; -- max. amount of data bytes per packet
  
  constant D21_5       : std_logic_vector := X"B5"; -- 8b10b character D21.5, encoding is B"1010101010"
                                                    -- to balance the cable, before sending data
  
  signal tx_cnt        : integer range 0 to MAX_PACKET_SIZE;
 	signal tx_fifo_dout  : std_logic_vector (7 downto 0); 
  signal stf_comma     : std_logic_vector (7 downto 0); 
  signal eof_comma     : std_logic_vector (7 downto 0); 
  
  signal tx_fifo_empty : std_logic;
  signal tx_fifo_rd_en : std_logic;
  signal wait_ct       : std_logic;
  
  type arb_state_type is (SEL_A, SEL_B);
	signal arb_state: arb_state_type := SEL_A;
  
	type state_type is (TX_IDLE, TX_D21_5, TX_STF, TX_FRD, TX_DATA, TX_EOF, TX_DONE);
	signal state: state_type := TX_IDLE;
 
 begin
 
   tx_arbiter_sm: process (com_clk)
    begin
     if (rising_edge(com_clk)) then
      if com_reset = '1' then
       arb_state     <= SEL_A;
      else
      
-- 	arb_sm_ena : if (tx_ena ='1') then
	   arb_sm: case (arb_state) is
     
      when SEL_A =>
       if ((tx_fifo_empty_a = '1') and (tx_fifo_empty_b = '0')) or ((state = TX_DONE) and (tx_fifo_empty_b = '0')) then
        arb_state <= SEL_B;
       end if;
 
      when SEL_B =>
       if ((tx_fifo_empty_b = '1') and (tx_fifo_empty_a = '0')) or ((state = TX_DONE) and (tx_fifo_empty_a = '0')) then
         arb_state <= SEL_A;
       end if;

      end case arb_sm;
  -- end if arb_sm_ena;
    end if; --  com_reset = '1'
   end if; -- rising_edge(com_clk))
  end process tx_arbiter_sm; 
   

       tx_fifo_rd_en_a <= '1' when (arb_state = SEL_A) and (tx_fifo_rd_en = '1') else '0';
       tx_fifo_rd_en_b <= '1' when (arb_state = SEL_B) and (tx_fifo_rd_en = '1') else '0';
       tx_fifo_empty   <= '0' when ((arb_state = SEL_A) and tx_fifo_empty_a = '0') or
                                   ((arb_state = SEL_B) and tx_fifo_empty_b = '0') else '1';
       stf_comma       <= STF_COMMA_a when (arb_state = SEL_A) else
                          STF_COMMA_b when (arb_state = SEL_B) else X"00";
       eof_comma       <= EOF_COMMA_a when (arb_state = SEL_A) else 
                          EOF_COMMA_b when (arb_state = SEL_B) else X"00";
                          
       tx_fifo_dout    <= tx_fifo_dout_a when (arb_state = SEL_A) else                 
                          tx_fifo_dout_b when (arb_state = SEL_B) else X"00";
                          
   tx_sm: process (com_clk)
	   begin
	  sync: if (rising_edge(com_clk)) then
	           
     reset_if: if (com_reset = '1') then
            state           <= TX_IDLE;
            enc_8b10b_ena <= '0';
            tx_run_8b10b    <= '0';
            enc_8b10b_in    <= X"00";
            enc_comma_stb   <= '0';
            enc_8b10b_reset <= '1';
            tx_fifo_rd_en   <= '0';
            wait_ct         <= '0';
         else
			  			  		
--		sm_ena : if (tx_ena ='1') then
			sm: case (state) is
         when TX_IDLE =>
            tx_run_8b10b  <= '0';
            enc_8b10b_reset <= '0';
            enc_8b10b_ena <= '0'; 
            enc_8b10b_in  <= X"00";
            enc_comma_stb <= '0'; 
            tx_cnt        <= 0; 
            tx_fifo_rd_en <= '0';
            wait_ct       <= '0';
			      if (tx_fifo_empty ='0') then
             enc_8b10b_reset  <= '0';
             enc_8b10b_in     <= D21_5;            
             enc_8b10b_ena    <= '1';
             wait_ct          <= '1';
            end if;
            if wait_ct = '1' then   -- to get a longer enc_8b10b_ena
              wait_ct <= '0';
			        state   <= TX_D21_5;
            end if;  
 
         when TX_D21_5 =>
            enc_8b10b_ena   <= '0';
            tx_run_8b10b    <= '1';
            if tx_done_8b10b = '1' then 
             enc_8b10b_in    <= stf_comma;            
             enc_8b10b_ena   <= '1';
             enc_comma_stb   <= '1';              
 			       wait_ct         <= '1';
            end if;
            if wait_ct = '1' then   -- to get a longer enc_8b10b_ena
              wait_ct <= '0';
			        state   <= TX_STF;
            end if;  
            
 
         when TX_STF =>
            enc_8b10b_ena   <= '0';
            enc_comma_stb   <= '0';
            if tx_done_8b10b = '1' then             
             if tx_cnt < (FRAME_LENGTH -1) then
              tx_cnt       <= tx_cnt +1;
             else
              tx_cnt        <= 0;
              enc_8b10b_in  <= tx_fifo_dout;
              enc_8b10b_ena <= '1';
 			        wait_ct       <= '1';
             end if; 
            end if;             
            if wait_ct = '1' then   -- to get a longer enc_8b10b_ena
              wait_ct      <= '0';
 			        state        <= TX_DATA; -- fifo with first word fall thru
            end if;
             
         when TX_FRD =>
              tx_fifo_rd_en <= '0';
 			        state         <= TX_DATA;
            
         when TX_DATA =>
              enc_8b10b_ena <= '0';                       
              if tx_ack_8b10b = '1' then
               if tx_cnt < MAX_PACKET_SIZE and tx_fifo_empty = '0' then
                tx_cnt        <= tx_cnt +1;
                tx_fifo_rd_en <= '1';
                state         <= TX_FRD;
               else
                enc_8b10b_in  <= eof_comma;            
                enc_8b10b_ena <= '1';            
                enc_comma_stb <= '1';
 			          wait_ct       <= '1';
               end if; 
              end if;             
             if wait_ct = '1' then   -- to get a longer enc_8b10b_ena
              wait_ct      <= '0';                
 			        state        <= TX_EOF;                            
             end if; 

         when TX_EOF =>   
              enc_8b10b_ena  <= '0';
              enc_comma_stb  <= '0';
              if tx_ack_8b10b = '1' then
               tx_run_8b10b  <= '0';
               if tx_cnt < (FRAME_LENGTH -1) then
                tx_cnt      <= tx_cnt +1;
               else
                tx_cnt      <= 0;
 	 			        state       <= TX_DONE;
               end if;
              end if;

         when TX_DONE =>
              if     (tx_done_8b10b = '1') and (tx_fifo_empty ='1') then  -- wait for 8b10b transmitter readyness
 	 			        state       <= TX_IDLE;
              elsif  (tx_done_8b10b = '1') and (tx_fifo_empty ='0') then
 			         state        <= TX_D21_5; 
              end if;
 
        end case sm;
--    end if sm_ena;
   end if reset_if;
  end if sync;
 end process tx_sm;

end architecture tx_ctrl_8b10b_arch;
