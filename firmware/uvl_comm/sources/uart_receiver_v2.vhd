-------------------------------------------------------
-- Design Name : uart_receiver 
-- File Name   : uart_receiver.vhd
-- Function    : Simple UART receiver with 10 fold oversampling
-- Coder       : K.-H. Sulanke, DESY
-- Date        : 2018-10-29
-------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_receiver_v2 is
	generic(
		SYSTEM_FREQUENCY_HZ : natural := 60_000_000;
		BAUD_RATE : natural := 115200;
		OVERSAMPLING_FACTOR : natural := 10;
		SAMPLING_POINT : natural := 4
	);
	port(
		reset : in std_logic;
		clk : in std_logic;
		rxIn : in std_logic;
		
		dataOut : out std_logic_vector(7 downto 0);
		newData : out std_logic;
		
		baudRateDivisor : in unsigned(15 downto 0)
	);
end entity;

architecture uart_receiver_arch of uart_receiver_v2 is

	attribute keep : string; 

	signal rxIn1 : std_logic;
	signal rxIn2 : std_logic;
	signal rxInSync : std_logic;
	signal rxBuffer : std_logic_vector(dataOut'length+1 downto 0); -- +2 bits for start and stop
	signal sampleCounter : integer range 0 to OVERSAMPLING_FACTOR-1; -- tenfold oversampling used here
	signal bitCounter : integer range 0 to rxBuffer'length-1; -- 1_8_1

	type uartRxState_t is (idle, sampleWord, samplingDone);
	signal uartRxState : uartRxState_t;
	
	signal rx_data_out : std_logic_vector(7 downto 0);
	signal rx_data_valid : std_logic;
	
	signal rx_ena : std_logic;
	constant RX_BAUD_DIV : natural := (SYSTEM_FREQUENCY_HZ / BAUD_RATE / OVERSAMPLING_FACTOR) - 1; -- TODO: fix this.... has to be programmable
	
	signal errorStartBit : std_logic;
	signal errorStopBit : std_logic;
	signal errorStartBitLatched : std_logic;
	signal errorStopBitLatched : std_logic;
	attribute keep of errorStartBit : signal is "true";
	attribute keep of errorStopBit : signal is "true";
	attribute keep of errorStartBitLatched : signal is "true";
	attribute keep of errorStopBitLatched : signal is "true";
	
	signal rxIn_pipe : std_logic_vector(1 downto 0);

begin
	process(clk)
		--variable clockCounter : integer range 0 to RX_BAUD_DIV := 0;
		variable clockCounter : unsigned(baudRateDivisor'range);
	begin
		if(rising_edge(clk)) then
			rx_ena <= '0'; -- autoreset
			if(reset = '1') then
				clockCounter := (others=>'0');
			else
				if(clockCounter = baudRateDivisor) then
					rx_ena <= '1'; -- autoreset
					clockCounter := (others=>'0');
				else
					clockCounter := clockCounter + 1;
				end if;
			end if;
		end if; 
	end process;
	
	-- TODO: out source this...
	--process(clk)
	--begin
	--	if(rising_edge(clk)) then
	--		if(reset = '1') then
	--			rxIn_pipe <= (others=>'0');
	--		else
	--			rxIn_pipe <= rxIn & rxIn_pipe(rxIn_pipe'left downto rxIn_pipe'right+1);
	--		end if; 
	--	end if; 
	--end process;
	--rxInSync <= rxIn_pipe(0);

	w0: entity work.pipeline_v1 generic map(pipeLength=>2, vectorWidth=>1) port map(clk=>clk, reset=>reset, pipeIn(0)=>rxIn, pipeOut(0)=>rxInSync);

	process(clk)
	begin
		if(rising_edge(clk)) then
			newData <= '0'; -- autoreset
			errorStartBit <= '0'; -- autoreset
			errorStopBit <= '0'; -- autoreset
			if(reset = '1') then
				uartRxState <= idle;
				errorStartBitLatched <= '0';
				errorStopBitLatched <= '0';
			else 
				if(rx_ena = '1') then
					case(uartRxState) is
						when idle =>
							if(rxInSync = '0') then -- start bit
								uartRxState <= sampleWord;
								sampleCounter <= 0;
								bitCounter <= 0; 
							end if;

						when sampleWord =>
							sampleCounter <= sampleCounter + 1;
							if(sampleCounter = SAMPLING_POINT) then
								rxBuffer <= rxInSync & rxBuffer(rxBuffer'left downto rxBuffer'right+1); -- lsb first
								
								if(bitCounter = rxBuffer'length-1) then
									uartRxState <= samplingDone;
								else
									bitCounter <= bitCounter + 1;
								end if;
							elsif(sampleCounter = OVERSAMPLING_FACTOR-1) then
								sampleCounter <= 0;
							end if;  
						
						when samplingDone =>
							dataOut <= rxBuffer(rxBuffer'left-1 downto rxBuffer'right+1);
							newData <= '1'; -- autoreset
							uartRxState <= idle;
							if(rxBuffer(rxBuffer'right) = '1') then
								errorStartBit <= '1'; -- autoreset
								errorStartBitLatched <= '1';
							end if;
							if(rxBuffer(rxBuffer'left) = '0') then
								errorStopBit <= '1'; -- autoreset
								errorStopBitLatched <= '1';
							end if;

					end case;
				end if;
			end if;
		end if;
	end process;

end architecture uart_receiver_arch;
