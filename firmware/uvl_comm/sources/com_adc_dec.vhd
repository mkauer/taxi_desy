-------------------------------------------------------
-- Design Name : com_adc_dec 
-- File Name   : com_adc_dec.vhd
-- ADC chip    : AD9649
-- Function    : serial data recovery from com_adc output signal 
-- Coder       : K.-H. Sulanke, DESY
-- Date        : 2018-11-09
-------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

--use ieee.std_logic_unsigned.all;
--use ieee.numeric_bit.all;
--use ieee.std_logic_arith.all;
Library UNISIM;
use UNISIM.vcomponents.all;

entity com_adc_dec is
	port(
		reset           : in  std_logic;
		clk             : in  std_logic; -- 60 MHz comm. clock
		com_thr_adj     : in  std_logic_vector (2 downto 0); -- set the comm. threshold
		COM_ADC_CSBn    : out std_logic;   --
		COM_ADC_SCLK    : out std_logic;   --
		COM_ADC_SDIO    : out std_logic; --
		COM_ADC_D       : in  std_logic_vector (13 downto 0); -- available 3ns after COM_ADC_CLK-LH edge
		COM_ADC_CLK_N   : out std_logic;  --
		COM_ADC_CLK_P   : out std_logic;  -- 
		com_adc_sdout   : out std_logic;   -- decoder serial data output 
		
		--commDebug_0r : out commDebug_registerRead_t;
		commDebug_0w : in commDebug_registerWrite_t
	);
end entity;

architecture com_adc_dec_arch of com_adc_dec is

	-- constant COM_ADC_THR_mV    : natural range 0 to 255 := 2;  -- ADC data difference between consecutive ADC samples to detect signal edges
	-- constant COM_ADC_THRESHOLD : std_logic_vector :=  CONV_STD_LOGIC_VECTOR((COM_ADC_THR_mV * 1000)/ 61, 9); -- 14bit, Vref=1V, 0.061mV / digit
	--constant dU_1mV : std_logic_vector :=  CONV_STD_LOGIC_VECTOR((1 * 1000)/ 61, 9); -- 1 mV delta U between consecutive samples 

	constant adcTicksPer_mv : integer := 61;

	type array_4x14 is array (0 to 3) of unsigned(13 downto 0); 
	signal com_adc_pipe : array_4x14;

	signal com_adc_clock   : std_logic := '0';
	--signal com_adc_thr     : std_logic_vector (8 downto 0);
	
	signal com_adc_thr_TPTHRU_TIG : unsigned(15 downto 0);
	signal com_adc_thr_1 : unsigned(15 downto 0);
	signal com_adc_thr : unsigned(15 downto 0);
	signal com_adc_thr_x : unsigned(15 downto 0);
	
	signal dU_1mV_TPTHRU_TIG : unsigned(15 downto 0);
	signal dU_1mV_1 : unsigned(15 downto 0);
	signal dU_1mV : unsigned(15 downto 0);

begin      

	p0: process(clk)
	begin
		if(rising_edge(clk)) then
			dU_1mV <= dU_1mV_1; 
			dU_1mV_1 <= dU_1mV_TPTHRU_TIG; 
			dU_1mV_TPTHRU_TIG <= unsigned(commDebug_0w.dU_1mV);
			com_adc_thr <= com_adc_thr_1; 
			com_adc_thr_1 <= com_adc_thr_TPTHRU_TIG; 
			com_adc_thr_TPTHRU_TIG <= unsigned(commDebug_0w.com_adc_thr);
		end if;
	end process p0;

	set_com_thr: process (clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				com_adc_thr_x <= to_unsigned((4*1000)/adcTicksPer_mv,com_adc_thr'length);
			else 
				case com_thr_adj is
					when B"000" => com_adc_thr_x <= com_adc_thr;
					--when B"000" => com_adc_thr_x <= to_unsigned((   4 * 1000)/ adcTicksPer_mv, com_adc_thr_x'length); -- 1mV
					when B"001" => com_adc_thr_x <= to_unsigned((   8 * 1000)/ adcTicksPer_mv, com_adc_thr_x'length);
					when B"010" => com_adc_thr_x <= to_unsigned((  16 * 1000)/ adcTicksPer_mv, com_adc_thr_x'length);
					when B"011" => com_adc_thr_x <= to_unsigned((  32 * 1000)/ adcTicksPer_mv, com_adc_thr_x'length);
					when B"100" => com_adc_thr_x <= to_unsigned((  64 * 1000)/ adcTicksPer_mv, com_adc_thr_x'length); -- note the jump here!
					when B"101" => com_adc_thr_x <= to_unsigned(( 128 * 1000)/ adcTicksPer_mv, com_adc_thr_x'length);
					when B"110" => com_adc_thr_x <= to_unsigned(( 256 * 1000)/ adcTicksPer_mv, com_adc_thr_x'length);
					when B"111" => com_adc_thr_x <= to_unsigned(( 512 * 1000)/ adcTicksPer_mv, com_adc_thr_x'length); -- 8mV
					when others => com_adc_thr_x <= to_unsigned((   4 * 1000)/ adcTicksPer_mv, com_adc_thr_x'length);               
				end case;
			end if; -- reset = '1' 
		end if; -- rising_edge(clk)   
	end process set_com_thr; 

	com_adc_decoder: process (clk)
	begin
		if (rising_edge(clk)) then
			if (reset ='1') then
				com_adc_clock <= '0';
			else
				com_adc_clock <= not com_adc_clock; -- 30 MHz ADC clock
				if com_adc_clock = '1' then    -- get data after LH edge
					com_adc_pipe(0) <= unsigned(COM_ADC_D);
					com_adc_pipe(1) <= com_adc_pipe(0);
					com_adc_pipe(2) <= com_adc_pipe(1);
					com_adc_pipe(3) <= com_adc_pipe(2);
				end if;  
				
				if	(com_adc_pipe(0) > (com_adc_pipe(1) + dU_1mV)) and
					(com_adc_pipe(1) > (com_adc_pipe(2) + dU_1mV)) and
					(com_adc_pipe(2) > (com_adc_pipe(3) + dU_1mV)) and
					((com_adc_pipe(0) - com_adc_pipe(3)) > (com_adc_thr_x(13 downto 0))) then
						com_adc_sdout <= '1';
				elsif 	(com_adc_pipe(1) > (com_adc_pipe(0) + dU_1mV)) and
						(com_adc_pipe(2) > (com_adc_pipe(1) + dU_1mV)) and
						(com_adc_pipe(3) > (com_adc_pipe(2) + dU_1mV)) and
						((com_adc_pipe(3)-com_adc_pipe(0)) > (com_adc_thr_x(13 downto 0))) then
							com_adc_sdout <= '0';
				end if;
			end if;
		end if;
	end process com_adc_decoder;                 

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
