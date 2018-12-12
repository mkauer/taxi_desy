-------------------------------------------------------
-- Design Name : uart_transmitter 
-- File Name   : uart_transmitter.vhd
-- Function    : Simple UART transmitter
-- Coder       : K.-H. Sulanke, DESY
-- Date        : 2016-08-11
-------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;

entity uart_transmitter is
   port(
        reset          :in  std_logic;
        clk            :in  std_logic;
        tx_data_valid  :in  std_logic; -- like tx_fifo_not_empty
        tx_data_in     :in  std_logic_vector (7 downto 0);
        tx_ena         :in  std_logic;
        tx_run_baudgen :out std_logic; -- run baudrate generator only if needed
        tx_busy        :out std_logic;
        tx_ack         :out std_logic; -- single clock pulse
		    tx_out         :out std_logic  -- serial data out
       );
end entity;

architecture uart_transmitter_arch of uart_transmitter is
 
  signal tx_reg         :std_logic_vector (7 downto 0);
--  signal tx_go          :std_logic;
  signal tx_cnt         :integer range 0 to 7;
 	 
	type state_type is (IDLE, SEND_START, SEND_DATA, SEND_STOP);
	signal state: state_type := IDLE;
 
 begin
 
  tx_baudgen : process (clk)
  begin
    if (rising_edge(clk)) then
      if (reset = '1') or (state=SEND_STOP and tx_data_valid='0' and tx_ena='1') then
        tx_run_baudgen <= '0';
      elsif  tx_data_valid = '1' then
        tx_run_baudgen <= '1';
      end if;
    end if;
  end process tx_baudgen;   

 -- purpose: send data 1_8_1_nP
 -- RS232 transceiver circuit uses internal inverters !!!
 -- signal tx_out is delayed by one tx_ena-cycle with respect to state !
 
   tx_sm: process (clk)
	   begin
	    sync: if (rising_edge(clk)) then
	    
	      --tx_run_baudgen <= tx_data_valid;  
		    tx_ack         <= '0';  -- to get a single pulse of clock period
	    
        reset_if : if (reset = '1') then
            state         <= IDLE;
            tx_busy       <= '0';
            tx_ack        <= '0';
            tx_out        <= '1';
        else
			  			  		
		sm_ena : if (tx_ena ='1') then
			sm: case (state) is
         when IDLE =>
            tx_busy       <= '0';
            tx_cnt        <=  0;
            tx_out        <= '1';
			      if (tx_data_valid   = '1') then
			       	tx_reg  <= tx_data_in;
			        tx_busy <= '1';
			        state   <= SEND_START;
            end if;
            
         when SEND_START =>
            tx_out      <= '0';           -- low active start bit
 			      state       <= SEND_DATA;

         when SEND_DATA =>
           
             tx_out      <= tx_reg(0);
             tx_reg(6 downto 0) <= tx_reg(7 downto 1);
             tx_reg(7)   <= '0';
             if (tx_cnt = 7) then
              state       <= SEND_STOP;
             else
              tx_cnt      <= tx_cnt +1;
             end if;
            
          when SEND_STOP =>
             tx_out      <= '1';        -- high active stop bit
             tx_busy     <= '0'; 
             tx_ack      <= '1';
 			       state       <= IDLE;
        end case sm;
    end if sm_ena;
   end if reset_if;
  end if sync;
 end process tx_sm;  
end architecture uart_transmitter_arch;
