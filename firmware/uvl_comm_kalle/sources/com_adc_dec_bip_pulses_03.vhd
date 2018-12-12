-------------------------------------------------------
-- Design Name : com_adc_dec 
-- File Name   : com_adc_dec.vhd
-- ADC chip    : AD9649
-- Function    : serial data recovery from com_adc output signal 
-- Coder       : K.-H. Sulanke, DESY
-- Date        : 2018-11-30
-- Revision    : 08
-------------------------------------------------------
-- decoding 8b10b, introduced the recognition of high and low level signal plateau drift
-- rx_ena, to reduce the ADC clock rate
-- tested with filter boy only, most critical is the du value, the latter is for
-- long (middle) edge ~  twice compared to the trailing and leading edge and of course cable
-- type / length dependent

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
			rx_ena          : in  std_logic;
			baudrate_adj    : in std_logic_vector(3 downto 0);
         com_thr_adj     : in  std_logic_vector (2 downto 0); -- set the comm. threshold
         COM_ADC_CSBn    : out std_logic;   --
         COM_ADC_SCLK    : out std_logic;   --
         COM_ADC_SDIO    : inout std_logic; --
         COM_ADC_D       : in  std_logic_vector (13 downto 0); -- available 3ns after COM_ADC_CLK-LH edge
         COM_ADC_CLK_N   : out std_logic;  --
         COM_ADC_CLK_P   : out std_logic;  -- 
         com_adc_sdout   : out std_logic  -- decoder serial data output
--         du              : in  natural range 0 to 2**14-1    -- typical transistion / fall time is 13 mV / ADC tick (33ns)        
       );
end entity;

architecture com_adc_dec_arch of com_adc_dec is

  constant N : natural := 10;
  signal du              : natural ; -- high or low level plateau is drifting at 0.33 mV / 33ns 

  type   array_Nx14 is array (0 to N-1) of natural range 0 to 2**14 -1; 
  signal com_adc_pipe    : array_Nx14 := ( others => 0);
 
  signal com_adc_clock   : std_logic := '0';
  signal com_adc_thr     : natural range 0 to 2**14-1;
  signal com_adc_sig     : natural range 0 to 2**14-1;
  signal com_adc_mean    : natural range 0 to 2**14-1;

  signal com_adc_sdout_nd     : std_logic;
  
 begin      
 
 
  set_com_thr: process (clk)
   begin
   if rising_edge(clk) then
     if reset = '1' then
      com_adc_thr    <=                    ((100 * 1000)/ 60);
     elsif rx_ena = '1' then 
        case com_thr_adj is
         when B"000"   => com_adc_thr <=   ((  6 * 1000)/ 60); -- 6 mV
         when B"001"   => com_adc_thr <=   (( 12 * 1000)/ 60); -- 
         when B"010"   => com_adc_thr <=   (( 24 * 1000)/ 60); -- 
         when B"011"   => com_adc_thr <=   (( 60 * 1000)/ 60); -- 
         when B"100"   => com_adc_thr <=   ((120 * 1000)/ 60); -- 
         when B"101"   => com_adc_thr <=   ((240 * 1000)/ 60); -- 
         when B"110"   => com_adc_thr <=   ((360 * 1000)/ 60); -- 
         when B"111"   => com_adc_thr <=   ((480 * 1000)/ 60); -- 
         when others   => com_adc_thr <=   ((600 * 1000)/ 60);               
        end case;
      end if; -- reset = '1' 
     end if; -- rising_edge(clk)   
   end process set_com_thr; 

        
--   get_dU: process (clk) -- du, depending on the ADC clock rate du =  rx_baud_div * 0.33 mV
--   begin
--   if rising_edge(clk) then
--     if reset = '1' then
--      du <= (((10 - 1) * 2 * 1000) / 60); -- 150_000 baud
--     else 
--       if rx_ena = '1' then      -- for synchronized changing of the du value    
--        case baudrate_adj is
--         when X"0"   => du <= (((60 - 1) * 2 * 1000) / 60); --  25_000 baud
--         when X"1"   => du <= (((30 - 1) * 2 * 1000) / 60); --  50_000 baud
--         when X"2"   => du <= (((15 - 1) * 2 * 1000) / 60); -- 100_000 baud
--         when X"3"   => du <= (((12 - 1) * 2 * 1000) / 60); -- 125_000 baud
--         when X"4"   => du <= (((10 - 1) * 2 * 1000) / 60); -- 150_000 baud
--         when X"5"   => du <= ((( 6 - 1) * 2 * 1000) / 60); -- 250_000 baud
--         when X"6"   => du <= ((( 4 - 1) * 2 * 1000) / 60); -- 375_000 baud
--         when X"7"   => du <= ((( 3 - 1) * 2 * 1000) / 60); -- 500_000 baud
--                                                       
--         when others => du <= (((10 - 1) * 2 * 1000) / 60); -- 150_000 baud           
--        end case;
--       end if; -- rx_ena = '1' 
--      end if; -- reset = '1' 
--     end if; -- rising_edge(clk)   
--   end process get_dU; 
 
     du <= ((35 * 1000) / 60);

   com_adc_decoder: process (clk)
    begin
     if (rising_edge(clk)) then
      if (reset ='1') then
       com_adc_clock    <= '0';
       com_adc_sdout_nd <= '0';
      elsif rx_ena = '1' then
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
		
         if (
			   (com_adc_pipe(0) > com_adc_pipe(1)+ du     ) and
				(com_adc_pipe(1) > com_adc_pipe(2)+ du ) and
				(com_adc_pipe(2) > com_adc_pipe(3)+ du ) and
				(com_adc_pipe(3) > com_adc_pipe(4) + du )) then
--				(com_adc_pipe(4) > com_adc_pipe(5) + du )) then
--				(com_adc_pipe(5) > com_adc_pipe(6) + du ) and
--				(com_adc_pipe(6) > com_adc_pipe(7) + du )) then
--				(com_adc_pipe(7) > com_adc_pipe(8) ) and
--				(com_adc_pipe(8) > com_adc_pipe(9))    ) then	
		    com_adc_sdout_nd <= '1';
         elsif (
			   (com_adc_pipe(1) > com_adc_pipe(0) + du    ) and
				(com_adc_pipe(2) > com_adc_pipe(1) + du) and
				(com_adc_pipe(3) > com_adc_pipe(2) + du) and
   			(com_adc_pipe(4) > com_adc_pipe(3) + du )) then
--				(com_adc_pipe(5) > com_adc_pipe(4) + du )) then
--				(com_adc_pipe(6) > com_adc_pipe(5) + du) and
--				(com_adc_pipe(7) > com_adc_pipe(6) + du)) then			
--				(com_adc_pipe(8) > com_adc_pipe(7) ) and
--				(com_adc_pipe(9) > com_adc_pipe(8))    ) then	
		    com_adc_sdout_nd <= '0';
         end if;
       end if; --com_adc_clock = '1'     
      end if; -- (reset = '1') 
     end if; --  (rising_edge(clk))
    end process com_adc_decoder; 

--+ du
--+ du
--+ du
--+ du
--+ du
--+ du
--+ du




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
