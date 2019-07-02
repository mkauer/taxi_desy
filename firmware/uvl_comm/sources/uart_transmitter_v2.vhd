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
use ieee.numeric_std.all;

entity uart_transmitter_v2 is
	port(
		reset          :in  std_logic;
		clk            :in  std_logic;
		
		txOut          :out std_logic;  -- serial data out

		dataIn : in std_logic_vector (7 downto 0);
		fifoRead : out std_logic;
		fifoEmpty : in std_logic;

		baudRateDivisor : in unsigned(15 downto 0)
	);
end entity;

architecture uart_transmitter_arch of uart_transmitter_v2 is

	signal tx_reg : std_logic_vector (9 downto 0);
	signal tx_cnt : natural range 0 to 9;

	type state_type is (SEND_IDLE, SEND_DATA);
	signal sendState : state_type;
	
	type stateFifo_t is (s0,s1,s2,s3);
	signal fifoState : stateFifo_t;
	
	signal tx_data_in : std_logic_vector(7 downto 0);
	signal tx_data_valid : std_logic;

	signal tx_ena : std_logic;
	signal newData : std_logic;
	signal dataBuffer : std_logic_vector(7 downto 0);
	--constant BAUD_RATE    : natural :=  115_200; --3_000_000; -- 256_000, 2_000_000
	--constant TX_BAUD_DIV  : natural := (59_375_000 / BAUD_RATE) -1; 
begin

	-- purpose: send data 1_8_1_nP

	process (clk)
		--variable clock_count : integer range 0 to TX_BAUD_DIV := 0;
		variable clock_count : unsigned(15 downto 0);
	begin
		if(rising_edge(clk)) then
			if(reset = '1') then
				clock_count := (others=>'0');
				tx_ena <= '0';
			elsif(clock_count = baudRateDivisor) then
				tx_ena <= '1';
				clock_count := (others=>'0');
			else
				tx_ena <= '0';      
				clock_count := clock_count +1;
			end if; 
		end if;
	end process;

	--newData <= not(fifoEmpty);

	process(clk)
	begin
		if(rising_edge(clk)) then
			fifoRead <= '0'; -- autoreset
			if(reset = '1') then
				sendState <= SEND_IDLE;
				fifoState <= s0;
				tx_reg(0) <= '1';
				newData <= '0';
				dataBuffer <= dataIn;
			else
				case fifoState is
					when s0 =>
						if(fifoEmpty = '0') then
							fifoRead <= '1'; -- autoreset
							fifoState <= s1;
						end if;

					when s1 =>
						fifoState <= s2;
					
					when s2 =>
						fifoState <= s3;
						newData <= '1';
						dataBuffer <= dataIn;
					
					when s3 =>
						if(newData = '0') then
							fifoState <= s0;
						end if;
				end case;
				
				if(tx_ena ='1') then
					case(sendState) is
						when SEND_IDLE =>
							tx_cnt <= 0;
							if (newData = '1') then
								newData <= '0';
								tx_reg <= '1' & dataBuffer & '0';
								sendState <= SEND_DATA;
							end if;

						when SEND_DATA =>
							tx_reg(8 downto 0) <= tx_reg(9 downto 1);
							--tx_reg(9)   <= '0';
							if(tx_cnt = 9) and (newData = '0') then
								tx_cnt <= 0;
								sendState <= SEND_IDLE;
							else
								tx_cnt <= tx_cnt + 1;
							end if;

					end case;
				end if;
			end if;
		end if;
	end process; 

	txOut <= tx_reg(0);

end architecture uart_transmitter_arch;
