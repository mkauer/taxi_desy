-------------------------------------------------------
-- Design Name : com_adc_dec 
-- File Name   : com_adc_dec.vhd
-- ADC chip    : AD9649
-- Function    : serial data recovery from com_adc output signal 
-- Coder       : K.-H. Sulanke, DESY
-- Date        : 2018-11-14
-------------------------------------------------------
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
         com_thr_adj     : in  std_logic_vector (2 downto 0); -- set the comm. threshold
         COM_ADC_CSBn    : out std_logic;   --
         COM_ADC_SCLK    : out std_logic;   --
         COM_ADC_SDIO    : inout std_logic; --
         COM_ADC_D       : in  std_logic_vector (13 downto 0); -- available 3ns after COM_ADC_CLK-LH edge
         COM_ADC_CLK_N   : out std_logic;  --
         COM_ADC_CLK_P   : out std_logic;  -- 
         com_adc_sdout   : out std_logic   -- decoder serial data output      
       );
end entity;

architecture com_adc_dec_arch of com_adc_dec is

 -- constant COM_ADC_THR_mV    : natural range 0 to 255 := 2;  -- ADC data difference between consecutive ADC samples to detect signal edges
 -- constant COM_ADC_THRESHOLD : std_logic_vector :=  CONV_STD_LOGIC_VECTOR((COM_ADC_THR_mV * 1000)/ 61, 14); -- 14bit, Vref=1V, 0.061mV / digit
  constant dU_1mV : std_logic_vector :=  CONV_STD_LOGIC_VECTOR((1 * 1000)/ 61, 14); -- 1 mV delta U between consecutive samples 

  type array_2x14 is array (0 to 3) of std_logic_vector (13 downto 0); 
  signal com_adc_pipe    : array_2x14 := ( others => B"00" & X"000");
 
  signal com_adc_clock   : std_logic := '0';
  signal com_adc_thr     : std_logic_vector (13 downto 0);
 
 begin      
 
  set_com_thr: process (clk)
   begin
   if rising_edge(clk) then
     if reset = '1' then
      com_adc_thr    <= CONV_STD_LOGIC_VECTOR((  4 * 1000)/ 61, 14);
     else 
        case com_thr_adj is
         when B"000"   => com_adc_thr <=   CONV_STD_LOGIC_VECTOR((   4 * 1000)/ 61, 14); -- 4 mV
         when B"001"   => com_adc_thr <=   CONV_STD_LOGIC_VECTOR((   8 * 1000)/ 61, 14); -- 8 mV
         when B"010"   => com_adc_thr <=   CONV_STD_LOGIC_VECTOR((  16 * 1000)/ 61, 14); -- 16 mV
         when B"011"   => com_adc_thr <=   CONV_STD_LOGIC_VECTOR((  32 * 1000)/ 61, 14); -- 32 mV
         when B"100"   => com_adc_thr <=   CONV_STD_LOGIC_VECTOR((  64 * 1000)/ 61, 14); -- 64 mV
         when B"101"   => com_adc_thr <=   CONV_STD_LOGIC_VECTOR(( 128 * 1000)/ 61, 14); -- 128 mV
         when B"110"   => com_adc_thr <=   CONV_STD_LOGIC_VECTOR(( 256 * 1000)/ 61, 14); -- 256 mV
         when B"111"   => com_adc_thr <=   CONV_STD_LOGIC_VECTOR(( 512 * 1000)/ 61, 14); -- 512 mV

         when others   => com_adc_thr <=   CONV_STD_LOGIC_VECTOR((   4 * 1000)/ 61, 14);               
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
         com_adc_pipe(0) <= COM_ADC_D;
         com_adc_pipe(1) <= com_adc_pipe(0);
         com_adc_pipe(2) <= com_adc_pipe(1);
         com_adc_pipe(3) <= com_adc_pipe(2);
       end if;  
       if    (com_adc_pipe(0) > (com_adc_pipe(1) + dU_1mV)) and
             (com_adc_pipe(1) > (com_adc_pipe(2) + dU_1mV)) and
             (com_adc_pipe(2) > (com_adc_pipe(3) + dU_1mV)) and
             ((com_adc_pipe(0)-com_adc_pipe(3)) > com_adc_thr) then -- after ~100 ns 
         com_adc_sdout <= '1';
       elsif (com_adc_pipe(1) > (com_adc_pipe(0) + dU_1mV)) and
             (com_adc_pipe(2) > (com_adc_pipe(1) + dU_1mV)) and
             (com_adc_pipe(3) > (com_adc_pipe(2) + dU_1mV)) and
             ((com_adc_pipe(3)-com_adc_pipe(0)) > com_adc_thr) then -- after ~100 ns
         com_adc_sdout <= '0';
       end if;
      end if; -- (reset = '1') 
     end if; --  (rising_edge(clk))
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
