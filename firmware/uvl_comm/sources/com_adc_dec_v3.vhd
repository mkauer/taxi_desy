-------------------------------------------------------
-- Design Name : com_adc_dec 
-- File Name   : com_adc_dec.vhd
-- ADC chip    : AD9649
-- Function    : serial data recovery from com_adc output signal 
-- Coder       : K.-H. Sulanke, DESY
-- Date        : 2018-11-20
-- Revision    : 04
-------------------------------------------------------
-- so far best performance, using the 3.5 km IceCube filter box
-- fixed setting com_thr_adj = B"001"  worked for all baud rates !!!


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.std_logic_unsigned.all;
--use ieee.numeric_bit.all;
--use ieee.std_logic_arith.all;
use work.types.all;

Library UNISIM;
use UNISIM.vcomponents.all;

entity com_adc_dec_v3 is
	port(
		reset           : in  std_logic;
		clk             : in  std_logic; -- 60 MHz comm. clock
		--com_thr_adj     : in  std_logic_vector(2 downto 0); -- set the comm. threshold
		COM_ADC_CSBn    : out std_logic;   --
		COM_ADC_SCLK    : out std_logic;   --
		COM_ADC_SDIO    : out std_logic; --
		COM_ADC_D       : in  std_logic_vector(13 downto 0); -- available 3ns after COM_ADC_CLK-LH edge
		COM_ADC_CLK_N : out std_logic;
		COM_ADC_CLK_P : out std_logic;
		byte_out_debug : out std_logic; 
		word_out : out std_logic_vector(7 downto 0);
		word_ready0 : out std_logic;	
		word_ready1 : out std_logic;	
		notSync : out std_logic;	
		commDebug_0w : in commDebug_registerWrite_t
	);
end entity;

architecture com_adc_dec_arch of com_adc_dec_v3 is

	attribute keep : string;

	type array_Xx14 is array (0 to 20) of unsigned(13 downto 0); 
	signal com_adc_pipe : array_Xx14;

	signal com_adc_clock : std_logic;

	--signal com_adc_thr_TPTHRU_TIG : unsigned(15 downto 0);
	--signal com_adc_thr_1 : unsigned(15 downto 0);
	--signal com_adc_thr_x : unsigned(15 downto 0);
	
	signal dU_1mV_TPTHRU_TIG : unsigned(15 downto 0);
	signal dU_1mV_1 : unsigned(15 downto 0);
	signal du : unsigned(15 downto 0);
	
	signal adc_threshold_p : unsigned(15 downto 0);
	signal adc_threshold_p_TPTHRU_TIG : unsigned(15 downto 0);
	signal adc_threshold_n : unsigned(15 downto 0);
	signal adc_threshold_n_TPTHRU_TIG : unsigned(15 downto 0);
	signal adcSignalLevel : std_logic;
	attribute keep of adcSignalLevel : signal is "true";
	signal adcSignalBaseline : std_logic;
	attribute keep of adcSignalBaseline : signal is "true";
	signal adcSignalLevelH : std_logic;
	signal adcSignalLevelL : std_logic;
	
	signal baselineSum : unsigned(24 downto 0);
	signal baselineAverage : unsigned(13 downto 0);
	signal baselineCounter : unsigned(15 downto 0);
	
	signal bitCounter : integer range 0 to 16;
	signal syncCounter : unsigned(15 downto 0);
	signal currentBit : std_logic;
	signal currentBitValid : std_logic;
	signal data : std_logic_vector(word_out'length downto 0);
	signal data_latched : std_logic_vector(word_out'length-1 downto 0);
	signal dataReady : std_logic;
	signal dataReady_delayed : std_logic;

	signal deadTimeCounter : unsigned(11 downto 0);
	signal enableDeadTime : std_logic;
	
	signal wordCounter : unsigned(7 downto 0);
	attribute keep of wordCounter : signal is "true";

	signal adc_deadTime : unsigned(11 downto 0);
	signal adc_deadTime_TPTHRU_TIG : unsigned(11 downto 0);
	
	signal syncTimeout : unsigned(15 downto 0);
	signal syncTimeout_TPTHRU_TIG : unsigned(15 downto 0);
	
	signal adc_baselineAveragingTime : unsigned(15 downto 0);
	signal adc_baselineAveragingTime_TPTHRU_TIG : unsigned(15 downto 0);
	
	signal source : std_logic;

	signal sample1 : std_logic;
	signal sample2 : std_logic;
	signal decoderValue : std_logic_vector(15 downto 0);
	signal decoderValue_latched : std_logic_vector(15 downto 0);

	signal decoderBitCounter : unsigned(15 downto 0);
	signal decoderCounter : unsigned(15 downto 0);

	signal adc_decoder_t1 : unsigned(15 downto 0);
	signal adc_decoder_t1_TPTHRU_TIG : unsigned(15 downto 0);

	signal adc_decoder_t2 : unsigned(15 downto 0);
	signal adc_decoder_t2_TPTHRU_TIG : unsigned(15 downto 0);

	signal adc_decoder_t3 : unsigned(15 downto 0);
	signal adc_decoder_t3_TPTHRU_TIG : unsigned(15 downto 0);
	
	signal adc_decoder_t4 : unsigned(15 downto 0);
	signal adc_decoder_t4_TPTHRU_TIG : unsigned(15 downto 0);
	
	signal adc_decoder_bits : unsigned(15 downto 0);
	signal adc_decoder_bits_TPTHRU_TIG : unsigned(15 downto 0);

	signal bitError : std_logic;
	signal decoderValue_newData : std_logic;

	type decoderState_t is (sync0, sync1, sync2, data0, data1);
	signal decoderState : decoderState_t;
	
	signal decoder2Data : std_logic_vector(15 downto 0);
	attribute keep of decoder2Data : signal is "true";
	signal decoder2NewData : std_logic;
	attribute keep of decoder2NewData : signal is "true";
	signal decoder2frameWidth : unsigned(15 downto 0);
	signal decoder2frameWidth_TPTHRU_TIG : unsigned(15 downto 0);
	
	signal adc_debug : std_logic_vector(15 downto 0);
	signal adc_debug_TPTHRU_TIG : std_logic_vector(15 downto 0);
	signal fifo_avrFactor : std_logic_vector(3 downto 0);
	signal fifo_avrFactor_TPTHRU_X_TIG : std_logic_vector(3 downto 0);
	
	signal adcAvg : std_logic_vector(15 downto 0);
	attribute keep of adcAvg : signal is "true";
	attribute DONT_TOUCH of adcAvg : signal is "true";

	signal decoderIn : std_logic_vector(13 downto 0);
	attribute keep of decoderIn : signal is "true";

begin    

	--word_out <= data_latched;
	--word_ready0 <= dataReady_delayed when source = '0' else '0';
	--word_ready1 <= dataReady_delayed when source = '1' else '0';
	word_out <= decoder2Data(7 downto 0);
	word_ready0 <= decoder2NewData when decoder2Data(8) = '0' else '0';
	word_ready1 <= decoder2NewData when decoder2Data(8) = '1' else '0';

	decoderIn <= adcAvg(13 downto 0) when adc_debug(0) = '0' else std_logic_vector(com_adc_pipe(com_adc_pipe'length-1));

	q1: entity work.fifo_average_v1 port map
	(
		reset,
		clk,
		"00"&COM_ADC_D,
		adcAvg,
		fifo_avrFactor
	);

	q0: entity work.decoder_bipolar_a 
		generic map (frameWidthMax => decoder2Data'length)
		port map
		(
			reset,
			clk,
			--std_logic_vector(com_adc_pipe(com_adc_pipe'length-1)),
			--adcAvg(13 downto 0),
			decoderIn,
			decoder2Data,
			decoder2NewData,
			x"0200",
			adc_threshold_p,
			adc_threshold_n
			--decoder2frameWidth
		); 

	p0: process(clk)
	begin
		if(rising_edge(clk)) then
			du <= dU_1mV_1; 
			dU_1mV_1 <= dU_1mV_TPTHRU_TIG; 
			dU_1mV_TPTHRU_TIG <= unsigned(commDebug_0w.dU_1mV);
			adc_threshold_p <= adc_threshold_p_TPTHRU_TIG;
			adc_threshold_p_TPTHRU_TIG <= unsigned(commDebug_0w.adc_threshold_p);
			adc_threshold_n <= adc_threshold_n_TPTHRU_TIG;
			adc_threshold_n_TPTHRU_TIG <= unsigned(commDebug_0w.adc_threshold_n);
			decoder2frameWidth <= decoder2frameWidth_TPTHRU_TIG;
			decoder2frameWidth_TPTHRU_TIG <= unsigned(commDebug_0w.decoder2frameWidth);
		--	com_adc_thr <= com_adc_thr_1; 
		--	com_adc_thr_1 <= com_adc_thr_TPTHRU_TIG; 
		--	com_adc_thr_TPTHRU_TIG <= unsigned(commDebug_0w.com_adc_thr);
			adc_deadTime <= adc_deadTime_TPTHRU_TIG; 
			adc_deadTime_TPTHRU_TIG <= unsigned(commDebug_0w.adc_deadTime);
			syncTimeout <= syncTimeout_TPTHRU_TIG; 
			syncTimeout_TPTHRU_TIG <= unsigned(commDebug_0w.adc_syncTimeout);
			adc_baselineAveragingTime <= adc_baselineAveragingTime_TPTHRU_TIG; 
			adc_baselineAveragingTime_TPTHRU_TIG <= unsigned(commDebug_0w.adc_baselineAveragingTime);
			adc_decoder_t1 <= adc_decoder_t1_TPTHRU_TIG;
			adc_decoder_t1_TPTHRU_TIG <= unsigned(commDebug_0w.adc_decoder_t1);
			adc_decoder_t2 <= adc_decoder_t2_TPTHRU_TIG;
			adc_decoder_t2_TPTHRU_TIG <= unsigned(commDebug_0w.adc_decoder_t2);
			adc_decoder_t3 <= adc_decoder_t3_TPTHRU_TIG;
			adc_decoder_t3_TPTHRU_TIG <= unsigned(commDebug_0w.adc_decoder_t3);
			adc_decoder_t4 <= adc_decoder_t4_TPTHRU_TIG;
			adc_decoder_t4_TPTHRU_TIG <= unsigned(commDebug_0w.adc_decoder_t4);
			adc_decoder_bits <= adc_decoder_bits_TPTHRU_TIG;
			adc_decoder_bits_TPTHRU_TIG <= unsigned(commDebug_0w.adc_decoder_bits);
			adc_debug <= adc_debug_TPTHRU_TIG;
			adc_debug_TPTHRU_TIG <= commDebug_0w.adc_debug;
			fifo_avrFactor <= fifo_avrFactor_TPTHRU_X_TIG;
			fifo_avrFactor_TPTHRU_X_TIG <= commDebug_0w.fifo_avrFactor;
		end if;
	end process p0;

	process (clk)
	begin
		if (rising_edge(clk)) then
			currentBitValid <= '0'; --autoreset
			notSync <= '0'; -- autoreset
			dataReady <= '0'; -- autorest
			dataReady_delayed <= dataReady; -- ## hack for 8b10b decoder
			adcSignalBaseline <= '1'; -- autoreset 
			adcSignalLevelH <= '0'; -- autoreset
			adcSignalLevelL <= '0'; -- autoreset
			if (reset = '1') then
				com_adc_clock <= '0';
				baselineSum <= (others=>'0');
				baselineCounter <= (others=>'0');
				baselineAverage <= (others=>'0');
				syncCounter <= (others=>'1');
				bitCounter <= 0;
				dataReady <= '0';
				data <= (others=>'0'); 
				data_latched <= (others=>'0');
				enableDeadTime <= '0';
				deadTimeCounter <= (others=>'0');
				wordCounter <= x"00";
				source <= '0';
				byte_out_debug <= '1';
				adcSignalLevel <= '0';
			else
				com_adc_clock <= not com_adc_clock; -- 30 MHz ADC clock

				syncCounter <= syncCounter + 1;
				if(syncCounter = x"ffff") then
					syncCounter <= x"ffff";
				end if;
				if(syncCounter >= syncTimeout) then -- ## fine tune here....
					notSync <= '1'; -- autoreset
					bitCounter <= 0;
					wordCounter <= x"00";
				end if;

				if(currentBitValid = '1') and (enableDeadTime = '0') then
					syncCounter <= (others=>'0');
					data <= data(data'length-2 downto 0) & currentBit;
					bitCounter <= bitCounter + 1;
					enableDeadTime <= '1';
					byte_out_debug <= currentBit;
				end if;
				if(enableDeadTime = '1') then
					deadTimeCounter <= deadTimeCounter + 1;
				end if;
				if(deadTimeCounter > adc_deadTime) then
					deadTimeCounter <= (others=>'0');
					enableDeadTime <= '0';
				end if;

				if(bitCounter >= data'length) then
					data_latched <= data(data'length-2 downto 0);
					source <= data(data'length-1);
					dataReady <= '1'; -- autorest
					bitCounter <= 0;
					wordCounter <= wordCounter + 1;
				end if;

				for i in 0 to com_adc_pipe'length-2 loop
					com_adc_pipe(i) <= com_adc_pipe(i+1);
				end loop;
				com_adc_pipe(com_adc_pipe'length-1) <= unsigned(COM_ADC_D);
				
				if ((com_adc_pipe(0) + du < baselineAverage) and
					(com_adc_pipe(19) - du > baselineAverage)) then
						currentBit <= '1'; -- rising edge
						currentBitValid <= '1'; --autoreset
				end if;
				if ((com_adc_pipe(19) + du < baselineAverage) and
					(com_adc_pipe(0) - du > baselineAverage)) then
						currentBit <= '0'; -- falling edge
						currentBitValid <= '1'; --autoreset
				end if;

				if(com_adc_clock = '1') then
					baselineCounter <= baselineCounter + 1;
					baselineSum <= baselineSum + unsigned(COM_ADC_D);
				end if;
				if(baselineCounter = adc_baselineAveragingTime) then
					baselineSum <= (others=>'0');
					baselineCounter <= (others=>'0');
					baselineAverage <= baselineSum(23 downto 10);
				end if;

				if(com_adc_pipe(com_adc_pipe'length-1) > adc_threshold_p) then
					adcSignalLevel <= '1';
					adcSignalLevelH <= '1'; -- autoreset
					adcSignalBaseline <= '0'; -- autoreset
				end if;
				if(com_adc_pipe(com_adc_pipe'length-1) < adc_threshold_n) then
					adcSignalLevel <= '0';
					adcSignalLevelL <= '1'; -- autoreset
					adcSignalBaseline <= '0'; -- autoreset 
				end if;

			end if;
		end if;
	end process;    

	process (clk)
		variable bitValue : std_logic;
	begin
		if (rising_edge(clk)) then
			bitError <= '0'; -- autoreset
			decoderValue_newData <= '0'; -- autoreset
			if (reset = '1') then
				decoderState <= sync0;
				bitValue := '0';
				sample1 <= '0';
				sample2 <= '0';
				decoderValue <= (others=>'0');
				decoderBitCounter <= (others=>'0');
			else
				case decoderState is
					when sync0 =>
						if(adcSignalBaseline = '1') then
							decoderState <= sync1;
							decoderCounter <= (others=>'0');
						end if;

					when sync1 =>
						if(adcSignalBaseline = '1') then
							decoderCounter <= decoderCounter + 1;
							if(decoderCounter >= adc_decoder_t1) then
								decoderState <= sync2;
							end if;
						else
							decoderCounter <= (others=>'0');
						end if;
					
					when sync2 =>
						if(adcSignalBaseline = '0') then
							decoderState <= data0;
							decoderCounter <= (others=>'0');
							decoderValue <= (others=>'0');
							decoderBitCounter <= (others=>'0');
						end if;
					
					when data0 =>
						decoderCounter <= decoderCounter + 1;
						if(decoderCounter = adc_decoder_t2) then
							sample1 <= adcSignalLevel;
						elsif(decoderCounter = adc_decoder_t3) then
							sample2 <= adcSignalLevel;
						elsif(decoderCounter = adc_decoder_t4) then
							decoderState <= data1;
						end if;
					
					when data1 =>
						decoderCounter <= (others=>'0');
						decoderState <= data0;
						if((sample1 = '0') and (sample2 = '1')) then
							bitValue := '1';
						elsif((sample1 = '1') and (sample2 = '0')) then
							bitValue := '1';
						else
							bitError <= '1'; -- autoreset
						end if;

						decoderValue <= decoderValue(decoderValue'length-2 downto 0) & bitValue;
						decoderBitCounter <= decoderBitCounter + 1;
						if(decoderBitCounter >= adc_decoder_bits) then
							decoderValue_latched <= decoderValue;
							decoderValue_newData <= '1'; -- autoreset
							decoderBitCounter <= (others=>'0');
						end if;

				end case;

			end if;
		end if;
	end process;    


	COM_ADC_CLK_inst : OBUFDS
	generic map (
		IOSTANDARD => "DEFAULT")
	port map (
		O  => COM_ADC_CLK_P,   -- Diff_p output (connect directly to top-level port)
		OB => COM_ADC_CLK_N,   -- Diff_n output (connect directly to top-level port)
		I  => com_adc_clock    -- Buffer input 
	);


	COM_ADC_CSBn    <= '1';   -- serial interface disabled
	COM_ADC_SCLK    <= '0';   -- offset binary
	COM_ADC_SDIO    <= '0';   -- normal operation

end architecture com_adc_dec_arch;
