-------------------------------------------------------
-- Design Name : com_adc_dec 
-- File Name   : com_adc_dec.vhd
-- ADC chip    : AD9649
-- Function    : serial data recovery from com_adc output signal 
-- Coder       : K.-H. Sulanke, DESY
-- Date        : 2018-11-22
-- Revision    : 07
-------------------------------------------------------
-- decoding 8b10b, introduced the recognition of high and low level signal plateau drift

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_bit.all;
use ieee.std_logic_arith.all;
Library UNISIM;
use UNISIM.vcomponents.all;

entity com_adc_dec_va is
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
		com_adc_sdout   : out std_logic  -- decoder serial data output
										 --         du              : in  integer range 0 to 2**14-1    -- typical transistion / fall time is 13 mV / ADC tick (33ns)        
	);
end entity;

architecture com_adc_dec_arch of com_adc_dec_va is

	constant du : integer := (( 4 * 1000)/ 61); -- 4 mV; high or low level plateau is drifting at 3.6 mV / 33ns (ADC tick)

	type   array_2x14 is array (0 to 1) of integer range 0 to 2**14 -1; 
	signal com_adc_pipe    : array_2x14 := ( others => 0);

	signal com_adc_clock   : std_logic := '0';
	signal com_adc_thr     : integer range 0 to 2**14-1;
	signal com_adc_sig     : integer range 0 to 2**14-1;

	signal com_adc_sdout_nd     : std_logic;

begin      


	set_com_thr: process (clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				com_adc_thr    <=                    ((  4 * 1000)/ 61);
			else 
				case com_thr_adj is
					when B"000"   => com_adc_thr <=   ((  16 * 1000)/ 61); -- 4 mV
					when B"001"   => com_adc_thr <=   ((  32 * 1000)/ 61); -- 8 mV
					when B"010"   => com_adc_thr <=   ((  64 * 1000)/ 61); -- 16 mV
					when B"011"   => com_adc_thr <=   ((  96 * 1000)/ 61); -- 32 mV
					when B"100"   => com_adc_thr <=   (( 128 * 1000)/ 61); -- 64 mV
					when B"101"   => com_adc_thr <=   (( 160 * 1000)/ 61); -- 128 mV
					when B"110"   => com_adc_thr <=   (( 192 * 1000)/ 61); -- 256 mV
					when B"111"   => com_adc_thr <=   (( 224 * 1000)/ 61); -- 512 mV
					when others   => com_adc_thr <=   (( 256 * 1000)/ 61);               
				end case;
			end if; -- reset = '1' 
		end if; -- rising_edge(clk)   
	end process set_com_thr; 

	com_adc_decoder: process (clk)
	begin
		if (rising_edge(clk)) then
			if (reset ='1') then
				com_adc_clock    <= '0';
				com_adc_sdout_nd <= '0';
			else
				com_adc_clock <= not com_adc_clock; -- 30 MHz ADC clock
				if com_adc_clock = '1' then    -- get data after LH edge
					com_adc_pipe(0) <= conv_integer(COM_ADC_D);
					com_adc_pipe(1) <= com_adc_pipe(0);
					if    (com_adc_pipe(0) > com_adc_pipe(1) + du) and  (com_adc_sdout_nd = '0') then
						com_adc_sig <= com_adc_sig + (com_adc_pipe(0) - com_adc_pipe(1));
						if com_adc_sig > com_adc_thr then
							com_adc_sdout_nd <= '1';
							com_adc_sig      <= 0;
						end if;             
					elsif (com_adc_pipe(1) > com_adc_pipe(0) + du) and (com_adc_sdout_nd = '1') then
						com_adc_sig <= com_adc_sig + (com_adc_pipe(1) - com_adc_pipe(0));
						if com_adc_sig > com_adc_thr then
							com_adc_sdout_nd <= '0';
							com_adc_sig      <= 0;
						end if;
					end if;  -- (com_adc_pipe(0) > com_adc_pipe(1)) and  (com_adc_sdout_nd = '0')         
				end if; --com_adc_clock = '1'     
			end if; -- (reset = '1') 
		end if; --  (rising_edge(clk))
	end process com_adc_decoder; 


	com_adc_sdout <=  com_adc_sdout_nd;    

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
