-------------------------------------------------------
-- Design Name : uart_transmitter 
-- File Name   : uart_transmitter.vhd
-- Function    : Simple UART transmitter
-- Coder       : K.-H. Sulanke, DESY
-- Date        : 2018-10-29
-------------------------------------------------------
-- one stop bit only

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
        tx_ack         :out std_logic; -- single clock pulse
		    tx_out         :out std_logic  -- serial data out
       );
end entity;

architecture uart_transmitter_arch of uart_transmitter is
 
  signal tx_reg         : std_logic_vector (9 downto 0);
  signal tx_cnt         : natural range 0 to 9;
 	 
	type state_type is (SEND_IDLE, SEND_DATA);
	signal state: state_type := SEND_IDLE;
 
 begin
 
 -- purpose: send data 1_8_1_nP
 -- RS232 transceiver circuit uses internal inverters !!!
  
   tx_sm: process (clk)
	   begin
	    sync: if (rising_edge(clk)) then

		    tx_ack         <= '0';  -- to get a single pulse of one clock period
	    
        reset_if : if (reset = '1') then
            state         <= SEND_IDLE;
            tx_reg(0)     <= '1';
            tx_ack        <= '0';
        else
			  			  		
		sm_ena : if (tx_ena ='1') then
			sm: case (state) is
         when SEND_IDLE =>
            tx_cnt        <=  0;
 			      if (tx_data_valid   = '1') then
			       	tx_reg  <= '1' & tx_data_in & '0';
			        state   <= SEND_DATA;
            end if;
 
         when SEND_DATA =>
         
             tx_reg(8 downto 0) <= tx_reg(9 downto 1);
             --tx_reg(9)   <= '0';
             if    (tx_cnt = 8) then 
              tx_ack    <= '1';
             end if; 
             if    (tx_cnt = 9) and tx_data_valid ='0' then
              tx_cnt    <=  0;
              state     <= SEND_IDLE;
             elsif (tx_cnt = 9) and tx_data_valid ='1' then
              tx_cnt    <=  0;
              tx_reg    <= '1' & tx_data_in & '0';
             else
              tx_cnt      <= tx_cnt +1;
             end if;
  
      end case sm;
    end if sm_ena;
   end if reset_if;
  end if sync;
 end process tx_sm; 
 
  tx_out      <= tx_reg(0);
 
end architecture uart_transmitter_arch;
