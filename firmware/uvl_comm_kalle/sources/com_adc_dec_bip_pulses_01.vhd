-------------------------------------------------------
-- Design Name : com_adc_dec 
-- File Name   : com_adc_dec.vhd
-- ADC chip    : AD9649
-- Function    : serial data recovery from com_adc output signal 
-- Coder       : K.-H. Sulanke, DESY
-- Date        : 2018-11-21
-- Revision    : 06
-------------------------------------------------------
-- decoding bipolar pulses, used for the falling and the rising edge

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;
    use ieee.numeric_bit.all;
    use ieee.std_logic_arith.all;
Library UNISIM;
    use UNISIM.vcomponents.all;

entity com_adc_dec is
   port(
         reset           : in  std_logic;
         clk             : in  std_logic; -- 60 MHz comm. clock
         baudrate_adj    : in std_logic_vector(3 downto 0);
         com_thr_adj     : in  std_logic_vector (2 downto 0); -- set the comm. threshold
         COM_ADC_CSBn    : out std_logic;   --
         COM_ADC_SCLK    : out std_logic;   --
         COM_ADC_SDIO    : inout std_logic; --
         COM_ADC_D       : in  std_logic_vector (13 downto 0); -- available 3ns after COM_ADC_CLK-LH edge
         COM_ADC_CLK_N   : out std_logic;  --
         COM_ADC_CLK_P   : out std_logic;  -- 
         com_adc_sdout   : out std_logic  -- decoder serial data output
--         du              : in  integer range 0 to 2**14-1    -- typical transistion / fall time is 13 mV / ADC tick (33ns)        
       );
end entity;

architecture com_adc_dec_arch of com_adc_dec is

 -- constant COM_ADC_THR_mV    : natural range 0 to 255 := 2;  -- ADC data difference between consecutive ADC samples to detect signal edges
 -- constant COM_ADC_THRESHOLD : std_logic_vector :=  CONV_STD_LOGIC_VECTOR((COM_ADC_THR_mV * 1000)/ 61, 14); -- 14bit, Vref=1V, 0.061mV / digit
 -- constant dU_1mV : std_logic_vector :=  CONV_STD_LOGIC_VECTOR((1 * 1000)/ 61, 14); -- 1 mV delta U between consecutive samples 

  constant du              : integer := ((   1 * 1000)/ 61); -- 1 mV;

  type   array_16x14 is array (0 to 15) of integer range 0 to 2**14 -1; 
  signal com_adc_pipe    : array_16x14 := ( others => 0);
 
  signal com_adc_clock   : std_logic := '0';
  signal com_adc_thr     : integer range 0 to 2**14-1;
  --signal du              : integer range 0 to 2**14-1;
  signal blocked         : std_logic;
  signal bit_length      : integer range 0 to 4095;

  signal block_ct        : integer range 0 to 4095; 

  signal com_adc_sdout_nd     : std_logic;
  signal com_adc_sdout_nd_dld : std_logic;
  
 begin      
 
    get_pulse_length: process (clk) -- amount of clocks per bit
   begin
   if rising_edge(clk) then
     if reset = '1' then
      bit_length    <=  10 - 1;
     else 
       if block_ct = 0 then          -- for synchronized changing of the baudrate    
        case baudrate_adj is
         when X"0"   => bit_length <=   3000; --   20_000 baud
         when X"1"   => bit_length <=   2000; --   30_000 baud
         when X"2"   => bit_length <=   1500; --   40_000 baud 
         when X"3"   => bit_length <=   1200; --   50_000 baud
         when X"4"   => bit_length <=    600; --  100_000 baud
         when X"5"   => bit_length <=    400; --  150_000 baud
         when X"6"   => bit_length <=    300; --  200_000 baud
         when X"7"   => bit_length <=    200; --  300_000 baud
         when X"8"   => bit_length <=    120; --  500_000 baud
         when X"9"   => bit_length <=     60; -- 1000_000 baud
         when X"a"   => bit_length <=     40; -- 1500_000 baud
         when X"b"   => bit_length <=     30; -- 2000_000 baud
         when X"c"   => bit_length <=     20; -- 3000_000 baud
         when X"d"   => bit_length <=     15; -- 4000_000 baud
         when X"e"   => bit_length <=     12; -- 5000_000 baud
         when X"f"   => bit_length <=     10; -- 6000_000 baud
                                                               
         when others => bit_length <= 10 - 1;                
        end case;
       end if; -- 
      end if; -- reset = '1' 
     end if; -- rising_edge(clk)   
   end process get_pulse_length; 
 
 
  set_com_thr: process (clk)
   begin
   if rising_edge(clk) then
     if reset = '1' then
      com_adc_thr    <=                    ((  4 * 1000)/ 61);
     else 
        case com_thr_adj is
         when B"000"   => com_adc_thr <=   ((   4 * 1000)/ 61); -- 4 mV
         when B"001"   => com_adc_thr <=   ((   8 * 1000)/ 61); -- 8 mV
         when B"010"   => com_adc_thr <=   ((  16 * 1000)/ 61); -- 16 mV
         when B"011"   => com_adc_thr <=   ((  32 * 1000)/ 61); -- 32 mV
         when B"100"   => com_adc_thr <=   ((  64 * 1000)/ 61); -- 64 mV
         when B"101"   => com_adc_thr <=   (( 128 * 1000)/ 61); -- 128 mV
         when B"110"   => com_adc_thr <=   (( 256 * 1000)/ 61); -- 256 mV
         when B"111"   => com_adc_thr <=   (( 512 * 1000)/ 61); -- 512 mV

         when others   => com_adc_thr <=   ((   4 * 1000)/ 61);               
        end case;
      end if; -- reset = '1' 
     end if; -- rising_edge(clk)   
   end process set_com_thr; 

   com_adc_decoder_blocking: process (clk)
    begin
     if (rising_edge(clk)) then
      if (reset ='1') then
       blocked              <= '0';
       com_adc_sdout_nd_dld <= '0';
      else
       com_adc_sdout_nd_dld <= com_adc_sdout_nd ;     
        if com_adc_sdout_nd_dld /= com_adc_sdout_nd then
         blocked  <= '1';
         block_ct <= bit_length;
        elsif block_ct /= 0 then
         block_ct <= block_ct - 1;
        else
         blocked <= '0';
        end if;
      end if; -- (reset ='1')
     end if; --(rising_edge(clk))
    end process com_adc_decoder_blocking; 

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
         com_adc_pipe(2) <= com_adc_pipe(1);
         com_adc_pipe(3) <= com_adc_pipe(2);
         com_adc_pipe(4) <= com_adc_pipe(3);
         com_adc_pipe(5) <= com_adc_pipe(4);
         com_adc_pipe(6) <= com_adc_pipe(5);
         com_adc_pipe(7) <= com_adc_pipe(6);
         com_adc_pipe(8) <= com_adc_pipe(7); 
         com_adc_pipe(9) <= com_adc_pipe(8); 
         com_adc_pipe(10) <= com_adc_pipe(9);    
         com_adc_pipe(11) <= com_adc_pipe(10);
         com_adc_pipe(12) <= com_adc_pipe(11);
         com_adc_pipe(13) <= com_adc_pipe(12);
         com_adc_pipe(14) <= com_adc_pipe(13);
         com_adc_pipe(15) <= com_adc_pipe(14);  
       end if;  
       if  (blocked = '0') then
        if   ((com_adc_pipe(15)-com_adc_pipe(0))  > com_adc_thr) then
             com_adc_sdout_nd <= '1';
        elsif ((com_adc_pipe(0)-com_adc_pipe(15)) > com_adc_thr) then
             com_adc_sdout_nd <= '0';
        end if;
       end if;        
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
