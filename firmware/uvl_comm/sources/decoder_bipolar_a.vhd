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
use work.types.all;

Library UNISIM;
use UNISIM.vcomponents.all;

entity decoder_bipolar_a is
	generic
	(
		frameWidthMax : natural := 32
		--frameGap : unsigned(15 downto 0) := x"0400"
		--adc_threshold_p : unsigned(15 downto 0) := x"2134";
		--adc_threshold_n : unsigned(15 downto 0) := x"1f40"
	);
	port(
		reset : in  std_logic;
		clk : in  std_logic; 
		adcDataIn : in  std_logic_vector(13 downto 0);
		decoderOut : out std_logic_vector(frameWidthMax-1 downto 0);
		newDataReady : out std_logic;
		
		frameGap : in  unsigned(15 downto 0);
		adc_threshold_p : in  unsigned(15 downto 0);
		adc_threshold_n : in  unsigned(15 downto 0)
		--frameWidth : in unsigned(15 downto 0)
	);
end entity;

architecture behavioral of decoder_bipolar_a is
	
	attribute keep : string;

	type decoder2State_t is (syncToBaseline0, syncToBaseline1, trackBaseline, s00, autoBaud, s0, s1, s2, frameEnd);
	signal decoder2State : decoder2State_t;

	signal decoder2Error : std_logic;
	signal newData : std_logic;
	signal decoder2Data : std_logic_vector(frameWidthMax-1 downto 0);
	signal frameGapCounter : unsigned(frameGap'range);
	signal decoder2AdcValue : unsigned(adcDataIn'range);
	--signal adc_threshold_p : unsigned(15 downto 0);
	--signal adc_threshold_n : unsigned(15 downto 0);
	signal peakFinderWindowWidth : unsigned(15 downto 0);
	signal decoder2PeakPositionCounter : unsigned(15 downto 0);
	signal peakPosition : unsigned(15 downto 0);
	signal positivePeakValue : unsigned(adcDataIn'range);
	signal negativePeakValue : unsigned(adcDataIn'range);
	signal firstPeak : std_logic;
	
	signal adcValueIsP : std_logic;
	signal adcValueIsN : std_logic;
	signal adcValueIsBaseline : std_logic;
	attribute keep of adcValueIsP : signal is "true";
	attribute keep of adcValueIsN : signal is "true";
	attribute keep of adcValueIsBaseline : signal is "true";
	attribute keep of decoder2Error : signal is "true";
	
	signal timeourError : std_logic;
	attribute keep of timeourError : signal is "true";
	signal timeourErrorLatched : std_logic;
	attribute keep of timeourErrorLatched : signal is "true";
	
	signal timeout : unsigned(15 downto 0);

begin    

	decoder2AdcValue <= unsigned(adcDataIn);
	newDataReady <= newData;

	adcValueIsP <= '1' when (decoder2AdcValue > adc_threshold_p) else '0';
	adcValueIsN <= '1' when (decoder2AdcValue < adc_threshold_n) else '0';
	adcValueIsBaseline <= not(adcValueIsP) and not(adcValueIsN);

	process (clk)
	begin
		if (rising_edge(clk)) then
			decoder2Error <= '0'; -- autoreset
			newData <= '0'; -- autoreset
			timeourError <= '0'; -- autoreset
			if (reset = '1') then
				decoder2State <= syncToBaseline0;
				decoder2Data <= (others=>'0');
				--decoder2BitCounter <= (others=>'0');
				timeourErrorLatched <= '0';
			else
				case decoder2State is
					when syncToBaseline0 =>
						decoder2State <= syncToBaseline1;
						frameGapCounter <= (others=>'0');

					when syncToBaseline1 =>
						if(adcValueIsBaseline = '1') then
							frameGapCounter <= frameGapCounter + 1;
						else
							frameGapCounter <= (others=>'0');
						end if;
						if(frameGapCounter > frameGap) then
							frameGapCounter <= (others=>'0');
							decoder2State <= trackBaseline;
						end if;

					when trackBaseline =>
						-- TODO: track it and use relative thresholds for n and p
						decoder2State <= s00;
					
					when s00 =>
						if(adcValueIsBaseline = '0') then
							decoder2Data <= (others=>'0');
							decoder2State <= autoBaud;
						end if;

					when autoBaud =>
						-- TODO: measure the distance from bit to bit and calculate all the counterWidths
						peakFinderWindowWidth <= to_unsigned(260,peakFinderWindowWidth'length); -- from 1st peak to 3rd peak minus something
						decoder2State <= s0;

					when s0 => -- start inside first edge of the bit
						decoder2PeakPositionCounter <= (others=>'0');
						peakPosition <= (others=>'0');
						positivePeakValue <= decoder2AdcValue;
						negativePeakValue <= decoder2AdcValue;
					
						if(adcValueIsP = '1') then
							firstPeak <= '1';
							decoder2State <= s1;
						end if;
						if(adcValueIsN = '1') then
							firstPeak <= '0';
							decoder2State <= s1;
						end if;
						
						if(adcValueIsBaseline = '1') then
							frameGapCounter <= frameGapCounter + 1;
						end if;
						if(frameGapCounter > frameGap) then
							frameGapCounter <= (others=>'0');
							decoder2State <= frameEnd;
						end if;

					when frameEnd =>
						decoder2State <= trackBaseline;
						decoderOut <= decoder2Data;
						newData <= '1'; -- autoreset
						
					when s1 =>
						decoder2PeakPositionCounter <= decoder2PeakPositionCounter + 1;
						if(decoder2PeakPositionCounter >= peakFinderWindowWidth) then
							decoder2State <= s2;
						else
							if(positivePeakValue < decoder2AdcValue) then
								positivePeakValue <= decoder2AdcValue;
								peakPosition <= decoder2PeakPositionCounter;
								if(firstPeak = '1') then
									decoder2PeakPositionCounter <= (others=>'0');
									peakPosition <= (others=>'0');
								end if;
							end if;
							if(negativePeakValue > decoder2AdcValue) then
								negativePeakValue <= decoder2AdcValue;
								peakPosition <= decoder2PeakPositionCounter;
								if(firstPeak = '0') then
									decoder2PeakPositionCounter <= (others=>'0');
									peakPosition <= (others=>'0');
								end if;
							end if;
						end if;

					when s2 =>
						decoder2State <= s0;
						if((positivePeakValue > adc_threshold_p) and (negativePeakValue < adc_threshold_n)) then
							-- bit is OKish
							--decoder2State <= s0;

							-- TODO: much more checking: delta_t, delta_voltage, ...
							--if(positivePeakPosition > negativePeakPosition) then
							-- if(peakPosition > 1234) and ((peakPosition < 4321)) then ...
							if(firstPeak = '1') then
								decoder2Data <= decoder2Data(decoder2Data'length-2 downto 0) & '0';
							else
								decoder2Data <= decoder2Data(decoder2Data'length-2 downto 0) & '1';
							end if;

						else
							decoder2Data <= decoder2Data(decoder2Data'length-2 downto 0) & '0';
							decoder2Error <= '1'; -- ## -- autoreset
						end if;

				end case;

				

				if(adcValueIsBaseline <= '1') then
					if(timeout < x"1000") then
						timeout <= timeout + 1;
					end if;
					if(timeout = x"1000") then
						timeout <= timeout + 1;
						decoder2State <= trackBaseline;
						timeourErrorLatched <= '1';
						timeourError <= '1'; --autoreset
					end if;
				else
					timeout <= (others=>'0');
				end if;

			end if;
		end if;
	end process;

end architecture;
