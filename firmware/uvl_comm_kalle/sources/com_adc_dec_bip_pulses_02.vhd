-------------------------------------------------------
-- Design Name : com_adc_dec 
-- File Name   : com_adc_dec.vhd
-- ADC chip    : AD9649
-- Function    : serial data recovery from com_adc output signal 
-- Coder       : K.-H. Sulanke, DESY
-- Date        : 2018-11-28
-- Revision    : 08
-------------------------------------------------------
-- decoding 8b10b, introduced the recognition of high and low level signal plateau drift
-- rx_ena, to reduce the ADC clock rate
-- works like expected at 200 Kbaud, with com_thr_adj = 0..3;

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

  signal du              : natural ; -- high or low level plateau is drifting at 0.33 mV / 33ns 

  type   array_2x14 is array (0 to 1) of natural range 0 to 2**14 -1; 
  signal com_adc_pipe    : array_2x14 := ( others => 0);
 
  signal com_adc_clock   : std_logic := '0';
  signal com_adc_thr     : natural range 0 to 2**14-1;
  signal com_adc_sig     : natural range 0 to 2**14-1;

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

--  set_baudrate: process (clk)
--   begin
--   if rising_edge(clk) then
--     if reset = '1' then
--      tx_baud_div <= 600 - 1;  rx_baud_div <=    30 - 1; 
--     else 
--       if clock_count = tx_baud_div then  -- for synchronized changing of the baudrate    
--        case baudrate_adj is
--         when X"0"   => tx_baud_div <=   3000 - 1; rx_baud_div <=   150 - 1; --   20_000 baud
--         when X"1"   => tx_baud_div <=   2000 - 1; rx_baud_div <=   100 - 1; --   30_000 baud
--         when X"2"   => tx_baud_div <=   1500 - 1; rx_baud_div <=    75 - 1; --   40_000 baud 
--         when X"3"   => tx_baud_div <=   1200 - 1; rx_baud_div <=    60 - 1; --   50_000 baud
--         when X"4"   => tx_baud_div <=    600 - 1; rx_baud_div <=    30 - 1; --  100_000 baud
--         when X"5"   => tx_baud_div <=    400 - 1; rx_baud_div <=    20 - 1; --  150_000 baud
--         when X"6"   => tx_baud_div <=    300 - 1; rx_baud_div <=    15 - 1; --  200_000 baud
--         when X"7"   => tx_baud_div <=    200 - 1; rx_baud_div <=    10 - 1; --  300_000 baud
--         when X"8"   => tx_baud_div <=    120 - 1; rx_baud_div <=     6 - 1; --  500_000 baud 
--         when X"9"   => tx_baud_div <=     60 - 1; rx_baud_div <=     3 - 1; -- 1000_000 baud 33 ns
--                                                            
--         when others => tx_baud_div <= 600 - 1;  rx_baud_div <=    30 - 1;              
--        end case;
--       end if; -- tx_ena = '1'
--      end if; -- reset = '1' 
--     end if; -- rising_edge(clk)   
--   end process set_baudrate; 
        
   get_dU: process (clk) -- du, depending on the ADC clock rate du =  rx_baud_div * 0.33 mV
   begin
   if rising_edge(clk) then
     if reset = '1' then
      du <= ((( 7 - 1) * 2 * 1000) / 60);
     else 
       if rx_ena = '1' then      -- for synchronized changing of the du value    
        case baudrate_adj is
         when X"0"   => du <= (((75 - 1) * 2 * 1000) / 60); --   20_000 baud
         when X"1"   => du <= (((50 - 1) * 2 * 1000) / 60); --   30_000 baud
         when X"2"   => du <= (((37 - 1) * 2 * 1000) / 60); --   40_000 baud 
         when X"3"   => du <= (((30 - 1) * 2 * 1000) / 60); --   50_000 baud
         when X"4"   => du <= (((15 - 1) * 2 * 1000) / 60); --  100_000 baud, 4 mV per ADC tick
         when X"5"   => du <= (((10 - 1) * 2 * 1000) / 60); --  150_000 baud
         when X"6"   => du <= ((( 7 - 1) * 2 * 1000) / 60); --  200_000 baud
         when X"7"   => du <= ((( 5 - 1) * 2 * 1000) / 60); --  300_000 baud
         when X"8"   => du <= ((( 3 - 1) * 2 * 1000) / 60); --  500_000 baud
         when X"9"   => du <= ((( 2 - 1) * 2 * 1000) / 60); -- 1000_000 baud
                                                      
         when others => du <= ((( 7 - 1) * 2 * 1000) / 60);                
        end case;
       end if; -- rx_ena = '1' 
      end if; -- reset = '1' 
     end if; -- rising_edge(clk)   
   end process get_dU; 
 

--
--   com_adc_decoder: process (clk)
--    begin
--     if (rising_edge(clk)) then
--      if (reset ='1') then
--       com_adc_clock    <= '0';
--       com_adc_sdout_nd <= '0';
--      elsif rx_ena = '1' then
--       com_adc_clock <= not com_adc_clock; -- 30 MHz ADC clock
--       if com_adc_clock = '1' then    -- get data after LH edge
--         com_adc_pipe(0) <= conv_integer(COM_ADC_D);
--         com_adc_pipe(1) <= com_adc_pipe(0);
--         if    (com_adc_pipe(0) > com_adc_pipe(1) + du) and  (com_adc_sdout_nd = '0') then
--           com_adc_sig <= com_adc_sig + (com_adc_pipe(0) - com_adc_pipe(1));
--           if com_adc_sig > com_adc_thr then
--            com_adc_sdout_nd <= '1';
--            com_adc_sig      <= 0;
--           end if;             
--         elsif (com_adc_pipe(1) > com_adc_pipe(0) + du) and (com_adc_sdout_nd = '1') then
--          com_adc_sig <= com_adc_sig + (com_adc_pipe(1) - com_adc_pipe(0));
--           if com_adc_sig > com_adc_thr then
--            com_adc_sdout_nd <= '0';
--            com_adc_sig      <= 0;
--           end if;
--         end if;  -- (com_adc_pipe(0) > com_adc_pipe(1)) and  (com_adc_sdout_nd = '0')         
--       end if; --com_adc_clock = '1'     
--      end if; -- (reset = '1') 
--     end if; --  (rising_edge(clk))
--    end process com_adc_decoder; 


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
			if (com_adc_sdout_nd = '0') then
           if (com_adc_pipe(0) > com_adc_pipe(1) + du) then
            com_adc_sig <= com_adc_sig + (com_adc_pipe(0) - com_adc_pipe(1));
			  end if;
           if com_adc_sig > com_adc_thr then
            com_adc_sdout_nd <= '1';
            com_adc_sig      <= 0;
			  elsif (com_adc_pipe(1) > com_adc_pipe(0)) then
			   com_adc_sig      <= 0;
           end if;
         end if; --(com_adc_sdout_nd = '0') 
         if (com_adc_sdout_nd = '1') then			
           if (com_adc_pipe(1) > com_adc_pipe(0) + du) then
            com_adc_sig <= com_adc_sig + (com_adc_pipe(1) - com_adc_pipe(0));
			  end if;	
           if com_adc_sig > com_adc_thr then
            com_adc_sdout_nd <= '0';
            com_adc_sig      <= 0;
           elsif (com_adc_pipe(0) > com_adc_pipe(1)) then
			   com_adc_sig      <= 0;
           end if;
         end if;  -- (com_adc_sdout_nd = '1')    
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
