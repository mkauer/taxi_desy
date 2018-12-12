-------------------------------------------------------
-- Design Name : com_dac_enc 
-- File Name   : com_dac_enc.vhd
-- Function    : com_dac input signal gen. from serial data in
-- Coder       : K.-H. Sulanke, DESY
-- Date        : 2018-11-10
-------------------------------------------------------



library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

Library UNISIM;
use UNISIM.vcomponents.all;

entity com_dac_enc is
	port(
		reset            :in  std_logic;
		clk              :in  std_logic;
		bitStrobe	     :in  std_logic; -- from baudrate generator
		
		dataIn0			 :in  std_logic_vector (7 downto 0);
		fifoEmpty0       :in  std_logic; -- like tx_fifo_not_empty
		fifoRead0	     :out std_logic;
		dataIn1			 :in  std_logic_vector (7 downto 0);
		fifoEmpty1       :in  std_logic; -- like tx_fifo_not_empty
		fifoRead1	     :out std_logic;
		
		com_dac_data     :out std_logic_vector (11 downto 0); 
		com_dac_clock    :out std_logic;
		commDebug_0w     :in commDebug_registerWrite_t
	);
end entity;

architecture com_dac_enc_arch of com_dac_enc is

	constant COM_DAC_MAX    : std_logic_vector  :=  X"fff"; -- about 1.5V at transformer 

	signal bitToSend : std_logic;
	signal counter : unsigned(15 downto 0);

	signal dac_valueIdle : std_logic_vector(11 downto 0);
	signal dac_valueIdle_TPTHRU_TIG : std_logic_vector(11 downto 0);
	signal dac_valueLow : std_logic_vector(11 downto 0);
	signal dac_valueLow_TPTHRU_TIG : std_logic_vector(11 downto 0);
	signal dac_valueHigh : std_logic_vector(11 downto 0);
	signal dac_valueHigh_TPTHRU_TIG : std_logic_vector(11 downto 0);

	signal dac_time1 : unsigned(15 downto 0);
	signal dac_time2 : unsigned(15 downto 0);
	signal dac_time3 : unsigned(15 downto 0);
	signal dac_time1_TPTHRU_TIG : unsigned(15 downto 0);
	signal dac_time2_TPTHRU_TIG : unsigned(15 downto 0);
	signal dac_time3_TPTHRU_TIG : unsigned(15 downto 0);
	signal dac_clkTime : unsigned(15 downto 0);
	signal dac_clkTime_TPTHRU_TIG : unsigned(15 downto 0);

	type lineState_t is (init_1, init_2, init_3, idle, changeSource, getFirstBit_1, getFirstBit_2, waitForStrobe, getNextBit, sendPulse_1, sendPulse_2, sendPulse_3);
	signal lineState : lineState_t;

	signal DAC_CLK_HIGH_TIME : unsigned(15 downto 0) := x"0002";
	
	signal bitCounter : integer range 0 to 15;
	signal dataIn : std_logic_vector(dataIn0'length-1 downto 0);
	signal fifoRead : std_logic;
	signal fifoEmpty : std_logic;
	signal dataBuffer : std_logic_vector(dataIn'length downto 0);
	signal source : std_logic;

begin

	process(clk)
	begin
		if(rising_edge(clk)) then
			dac_valueIdle <= dac_valueIdle_TPTHRU_TIG; 
			dac_valueIdle_TPTHRU_TIG <= commDebug_0w.dac_valueIdle;
			dac_valueLow <= dac_valueLow_TPTHRU_TIG; 
			dac_valueLow_TPTHRU_TIG <= commDebug_0w.dac_valueLow;
			dac_valueHigh <= dac_valueHigh_TPTHRU_TIG; 
			dac_valueHigh_TPTHRU_TIG <= commDebug_0w.dac_valueHigh;
			
			dac_time1 <= dac_time1_TPTHRU_TIG; 
			dac_time1_TPTHRU_TIG <= unsigned(commDebug_0w.dac_time1);
			dac_time2 <= dac_time2_TPTHRU_TIG; 
			dac_time2_TPTHRU_TIG <= unsigned(commDebug_0w.dac_time2);
			dac_time3 <= dac_time3_TPTHRU_TIG; 
			dac_time3_TPTHRU_TIG <= unsigned(commDebug_0w.dac_time3);
			
			dac_clkTime <= dac_clkTime_TPTHRU_TIG; 
			dac_clkTime_TPTHRU_TIG <= unsigned(commDebug_0w.dac_clkTime);
		end if;
	end process;

	bitToSend <= dataBuffer(dataBuffer'length-1); -- msb first

	fifoEmpty <= fifoEmpty0 when source = '0' else fifoEmpty1;
	fifoRead0 <= fifoRead when source = '0' else '0';
	fifoRead1 <= fifoRead when source = '1' else '0';
	dataIn <= dataIn0 when source = '0' else dataIn1;

	process (clk)
	begin
		if(rising_edge(clk)) then
			com_dac_clock <= '0'; -- autoreset
			fifoRead <= '0'; -- autoreset
			if(reset = '1') then
				lineState <= init_1;
				counter <= (others=>'0');
				--bitToSend <= '0';
				com_dac_data <= dac_valueIdle;
				bitCounter <= 0;
				dataBuffer <= (others=>'0');
				source <= '0';
			else
				case(lineState) is
					when init_1 =>
						com_dac_data <= dac_valueIdle;
						counter <= counter + 1;
						com_dac_clock <= '0';
						lineState <= init_2;

					when init_2 =>
						com_dac_clock <= '0';
						lineState <= init_3;

					when init_3 =>
						com_dac_clock <= '0';
						lineState <= idle;
					
					when idle =>
						lineState <= changeSource; 
						com_dac_data <= dac_valueIdle;
						if(fifoEmpty = '0') then
							fifoRead <= '1'; -- autoreset
							counter <= (others=>'0');
							bitCounter <= 0;
							--dataBuffer <= dataIn; 
							lineState <= getFirstBit_1; 
						end if;

					when changeSource =>
						source <= not(source);
						lineState <= idle; 

					when getFirstBit_1 =>
						lineState <= getFirstBit_2; 
					
					when getFirstBit_2 =>
						dataBuffer <= source & dataIn;
						lineState <= waitForStrobe; 

					when getNextBit =>
						dataBuffer <= dataBuffer(dataBuffer'length-2 downto 0) & "0";
						bitCounter <= bitCounter + 1;
						lineState <= waitForStrobe; 

					when waitForStrobe =>
						if(bitCounter > dataBuffer'length-1) then
							lineState <= idle; 
						else 
							if(bitStrobe = '1') then
								lineState <= sendPulse_1; 
							end if;
						end if;

					when sendPulse_1 =>
						if(bitToSend = '1') then 
							com_dac_data <= dac_valueLow;
						else
							com_dac_data <= dac_valueHigh;
						end if;
						counter <= counter + 1;
						if(counter > dac_time1) then
							counter <= (others=>'0');
							lineState <= sendPulse_2;
						end if;
						if(counter <= dac_clkTime) then com_dac_clock <= '1'; end if; -- autoreset
						if(counter = x"0000") then com_dac_clock <= '0'; end if; -- autoreset
					
					when sendPulse_2 =>
						if(bitToSend = '1') then 
							com_dac_data <= dac_valueHigh;
						else
							com_dac_data <= dac_valueLow;
						end if;
						counter <= counter + 1;
						if(counter > dac_time2) then
							counter <= (others=>'0');
							lineState <= sendPulse_3;
						end if;
						if(counter <= dac_clkTime) then com_dac_clock <= '1'; end if; -- autoreset
						if(counter = x"0000") then com_dac_clock <= '0'; end if; -- autoreset

					when sendPulse_3 =>
						com_dac_data <= dac_valueIdle;
						counter <= counter + 1;
						if(counter > dac_time3) then
							counter <= (others=>'0');
							lineState <= getNextBit;
						end if;
						if(counter <= dac_clkTime) then com_dac_clock <= '1'; end if; -- autoreset
						if(counter = x"0000") then com_dac_clock <= '0'; end if; -- autoreset

					when others => lineState <= idle;
				end case;
			end if;
		end if; 
	end process;  

end architecture com_dac_enc_arch;
