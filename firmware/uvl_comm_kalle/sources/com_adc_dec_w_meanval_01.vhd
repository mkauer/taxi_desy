-------------------------------------------------------
-- Design Name : com_adc_dec 
-- File Name   : com_adc_dec.vhd
-- ADC chip    : AD9649
-- Function    : serial data recovery from com_adc output signal 
-- Coder       : K.-H. Sulanke, DESY
-- Date        : 2018-11-29
-- Revision    : 08
-------------------------------------------------------
-- decoding 8b10b, introduced the recognition of high and low level signal plateau drift
-- rx_ena, to reduce the ADC clock rate
-- incl. meanval generation
-- did not work so far

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;


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
         com_adc_sdout   : out std_logic;  -- decoder serial data output
			sig_gt_thr_out  : out std_logic -- for debugging 
--         du              : in  natural range 0 to 2**14-1    -- typical transistion / fall time is 13 mV / ADC tick (33ns)        
       );
end entity;

architecture com_adc_dec_arch of com_adc_dec is

  signal du              : natural ; -- high or low level plateau is drifting at 0.33 mV / 33ns 

  type   array_2x14 is array (0 to 1) of natural range 0 to 2**14 -1; 
  signal com_adc_pipe    : array_2x14 := ( others => 0);

  constant N : natural := 8;

--  type   array_N is array (0 to N-1) of natural; 
--  signal com_adc_sum     : array_N := ( others => 0);
 
  signal com_adc_clock   : std_logic := '0';
  signal com_adc_thr     : natural range 0 to 2**14-1;

  signal com_adc_sum      : unsigned(14+N-1 downto 0) := (others=>'0');  
  signal com_adc_mean_val : unsigned(13 downto 0) := (others=>'0');
 --alias  com_adc_mean_val : unsigned(13 downto 0) is com_adc_sum(com_adc_sum'left downto N);

  signal sig_gt_thr      : std_logic;
  signal up_going        : std_logic;
  signal	down_going      : std_logic;
  
  signal adc_sum_lh_ena  : std_logic;
  signal adc_sum_hl_ena  : std_logic;

  signal com_adc_sdout_nd     : std_logic;

  type dec_state_type is (DEC_IDLE, UP_GOING_90, DOWN_GOING_180, UP_GOING_360, DOWN_GOING_90, UP_GOING_180, DOWN_GOING_360 );
	signal dec_state: dec_state_type := DEC_IDLE;
  

  
 begin      
 
 
  com_adc_mean_val <= com_adc_sum(com_adc_sum'left downto N); 
  
  com_adc_sum  <= com_adc_sum - com_adc_mean_val + com_adc_pipe(0) when (rx_ena ='1' and rising_edge(clk));    
 
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

   get_dU: process (clk) -- du, depending on the ADC clock rate du =  rx_baud_div * 0.33 mV
   begin
   if rising_edge(clk) then
     if reset = '1' then
      du <= (((10 - 1) * 1000) / 60);
     else 
       if rx_ena = '1' then      -- for synchronized changing of the du value    
        case baudrate_adj is
         when X"0"   => du <= (((60 -1) * 1000) / 60); --  rx_baud_div <=    60 - 1; --   25_000 baud  
         when X"1"   => du <= (((30 -1) * 1000) / 60); --  rx_baud_div <=    30 - 1; --   50_000 baud  
         when X"2"   => du <= (((15 -1) * 1000) / 60); --  rx_baud_div <=    15 - 1; --  100_000 baud  
         when X"3"   => du <= (((12 -1) * 1000) / 60); --  rx_baud_div <=    12 - 1; --  125_000 baud  
         when X"4"   => du <= (((10 -1) * 1000) / 60); --  rx_baud_div <=    10 - 1; --  150_000 baud  
         when X"5"   => du <= ((( 6 -1) * 1000) / 60); --  rx_baud_div <=     6 - 1; --  250_000 baud  
         when X"6"   => du <= ((( 4 -1) * 1000) / 60); --  rx_baud_div <=     4 - 1; --  375_000 baud  
         when X"7"   => du <= ((( 3 -1) * 1000) / 60); --  rx_baud_div <=     3 - 1; --  500_000 baud  
                                                               
         when others => du <= (((10 - 1) * 1000) / 60); --  rx_baud_div <=    10 - 1; --  150_000 baud             
        end case;
       end if; -- rx_ena = '1' 
      end if; -- reset = '1' 
     end if; -- rising_edge(clk)   
   end process get_dU; 
 
   dec_sm: process (clk)
	   begin
	    if (rising_edge(clk)) then
	      if (reset = '1') then
           dec_state            <= DEC_IDLE;
           com_adc_sdout_nd <= '0';
			  adc_sum_lh_ena   <= '0';
			  adc_sum_hl_ena   <= '0';			  
         else
			 if (rx_ena ='1') then
			  case (dec_state) is
			  
            when DEC_IDLE =>	
				 adc_sum_lh_ena  <= '0';
				 adc_sum_hl_ena  <= '0';
             if (up_going = '1') and (sig_gt_thr = '1') then --
				  adc_sum_lh_ena <= '1';
				  dec_state          <= UP_GOING_90;
             end if;
				 if (down_going = '1') and (sig_gt_thr = '1') then -- 
				  adc_sum_hl_ena <= '1';
				  dec_state          <= DOWN_GOING_90;
             end if;
                                 -- getting the 8b10b low going edge
            when UP_GOING_90 =>	
             if (down_going = '1') then
				  adc_sum_lh_ena <= '0';
				  adc_sum_hl_ena <= '1';
				  dec_state          <= DOWN_GOING_180;
             end if;

            when DOWN_GOING_180 =>	
             if (up_going = '1') then
				  com_adc_sdout_nd <= '0';
				  adc_sum_lh_ena   <= '0';
				  adc_sum_hl_ena   <= '0';
				  dec_state            <= UP_GOING_360;
             end if;

            when UP_GOING_360 =>	
             if (up_going = '0') then
				  dec_state            <= DEC_IDLE;
             end if;

                                -- getting the 8b10b up going edge
            when DOWN_GOING_90 =>	
             if (up_going = '1') then
				  adc_sum_lh_ena <= '0';
				  adc_sum_hl_ena <= '1';
				  dec_state          <= UP_GOING_180;
             end if;

            when UP_GOING_180 =>	
             if (up_going = '1') then
				  com_adc_sdout_nd <= '1';
				  adc_sum_lh_ena   <= '0';
				  adc_sum_hl_ena   <= '0';
				  dec_state            <= DOWN_GOING_360;
             end if;

            when DOWN_GOING_360 =>	
             if (down_going = '0') then
				  dec_state            <= DEC_IDLE;
             end if;
				 
				 when others =>
				  dec_state            <= DEC_IDLE;
				  
			end case;
        end if; --(rx_ena ='1')			
	    end if; --(reset ='1')			
		end if; -- rising_edge(clk)
    end process dec_sm; 		
 
   com_adc_decoder: process (clk)
    begin
     if (rising_edge(clk)) then
      if (reset ='1') then
       com_adc_clock    <= '0';
		 sig_gt_thr       <= '0';
		 up_going         <= '0';
		 down_going       <= '0';
      elsif rx_ena = '1' then
       com_adc_clock <= not com_adc_clock; 
		 if com_adc_clock = '1' then    -- get data after LH edge
         com_adc_pipe(0) <= conv_integer(COM_ADC_D);
         com_adc_pipe(1) <= com_adc_pipe(0);
			
			if (com_adc_pipe(0) > com_adc_pipe(1) + du) then
			  up_going   <= '1';
			  down_going <= '0';
			elsif (com_adc_pipe(1) > com_adc_pipe(0) + du) then
			  up_going   <= '0';
			  down_going <= '1';
         end if;
			if (com_adc_pipe(0) > (com_adc_mean_val + com_adc_thr)) or
			   (com_adc_pipe(0) < (com_adc_mean_val - com_adc_thr)) then
			  sig_gt_thr <= '1';
			else
           sig_gt_thr <= '0';
         end if;			  
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

   sig_gt_thr_out <= sig_gt_thr;
  
 end architecture com_adc_dec_arch;
