-------------------------------------------------------
-- Design Name : com_adc_dec 
-- File Name   : com_adc_dec.vhd
-- ADC chip    : AD9649
-- Function    : serial data recovery from com_adc output signal 
-- Coder       : K.-H. Sulanke, DESY
-- Date        : 2018-12-04
-- Revision    : 10
-------------------------------------------------------
-- to be used for IceCube gen1 encoding style, decoding the trailing edge only
-- runs perfectly with IceCube gen1 3.5 km filter box ...
-- original cable not yet tested
-- simplified, du set to 0.5 mV fixed

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
--         du              : in  natural range 0 to 2**14-1    -- typical transistion / fall time iper ADC tick        
       );
end entity;

architecture com_adc_dec_arch of com_adc_dec is

  constant N                : natural := 2;
  signal   du               : natural range 0 to 1023;

  type   array_Nx14 is array (0 to N-1) of natural range 0 to 2**14 -1; 
  signal com_adc_pipe    : array_Nx14 := ( others => 0);
 
  signal com_adc_clock    : std_logic := '0';
  signal com_adc_thr      : natural range 0 to 2**14-1;
  signal com_adc_sum      : natural range 0 to 2**14-1;
  signal com_adc_above_thr : std_logic;
  signal com_adc_sdout_nd : std_logic;
  
  signal adc_sum_ena      : std_logic;
  signal up_going_edge    : std_logic;
  
  constant MAX_PULSE_LENGTH : natural := 42; -- each '1' pulse corresponds to 40 rx_ena pulses
  signal pulse_length_ct  : natural range 0 to MAX_PULSE_LENGTH;

  type dec_state_type is (DEC_IDLE, LOW_GOING_EDGE);
	signal dec_state: dec_state_type := DEC_IDLE;
  
 begin      

 
  set_com_thr: process (clk)
   begin
   if rising_edge(clk) then
     if reset = '1' then
      com_adc_thr <=   (( 60 * 1000)/ 60); --
     elsif rx_ena = '1' then 
        case com_thr_adj is
         when B"000"   => com_adc_thr <=   ((  6 * 1000)/ 60); -- 6 mV
         when B"001"   => com_adc_thr <=   (( 12 * 1000)/ 60); -- 
         when B"010"   => com_adc_thr <=   (( 24 * 1000)/ 60); -- 
         when B"011"   => com_adc_thr <=   (( 60 * 1000)/ 60); -- 
         when B"100"   => com_adc_thr <=   (( 90 * 1000)/ 60); -- 
         when B"101"   => com_adc_thr <=   ((120 * 1000)/ 60); -- 
         when B"110"   => com_adc_thr <=   ((150 * 1000)/ 60); -- 
         when B"111"   => com_adc_thr <=   ((180 * 1000)/ 60); -- 
         when others   => com_adc_thr <=   (( 60 * 1000)/ 60);               
        end case;
      end if; -- reset = '1' 
     end if; -- rising_edge(clk)   
   end process set_com_thr; 


   dec_sm: process (clk)
	   begin
	    if (rising_edge(clk)) then
	     if (reset = '1') then
          dec_state    <= DEC_IDLE;
       elsif (rx_ena ='1') then
       
			  case (dec_state) is
			  
         when DEC_IDLE =>
          adc_sum_ena <= '1';
          if  com_adc_sum > com_adc_thr then
           dec_state   <= LOW_GOING_EDGE;
           adc_sum_ena <= '0';
          end if; 
         
         when LOW_GOING_EDGE =>	
          if (up_going_edge = '1') then
           dec_state   <= DEC_IDLE; 
          end if;
          
				 when others =>
				  dec_state    <= DEC_IDLE;
				  
			  end case;
	   end if; --(reset ='1')			
		end if; -- rising_edge(clk)
  end process dec_sm; 		

   du <= 8; -- !!! estimated ADC input level of ~0.5 mV

   com_adc_decoder: process (clk)
    begin
     if (rising_edge(clk)) then
      if (reset ='1') then
       com_adc_clock     <= '0';
       com_adc_above_thr <= '0';
      elsif rx_ena = '1' then
       com_adc_above_thr <= '0'; -- to get single pulses
       com_adc_clock <= not com_adc_clock;       
       if com_adc_clock = '1' then    -- get data after LH edge
         com_adc_pipe(0) <= conv_integer(COM_ADC_D);
         com_adc_pipe(1) <= com_adc_pipe(0);         
         if (com_adc_pipe(0) > com_adc_pipe(1) + du) then
          up_going_edge <= '1';
         else
          up_going_edge <= '0';
         end if; 
         if (adc_sum_ena = '1') then         
          if (com_adc_pipe(1) > com_adc_pipe(0) + du ) then
           com_adc_sum <= com_adc_sum + (com_adc_pipe(1) - com_adc_pipe(0));
          else
           com_adc_sum <= 0;
          end if; --(com_adc_pipe(1) > com_adc_pipe(0) + du )           
         else            
           com_adc_sum <= 0;
         end if;   -- ((com_adc_pipe(1) > com_adc_pipe(0) + du ) 
         if com_adc_sum > com_adc_thr then
          com_adc_above_thr <= '1';
         end if;      
       end if; --com_adc_clock = '1'     
      end if; -- (reset = '1') 
     end if; --  (rising_edge(clk))
    end process com_adc_decoder; 

   pulse_keeper: process (clk)
    begin
     if (rising_edge(clk)) then
      if (reset ='1') then
       com_adc_sdout_nd <= '0';
      elsif rx_ena = '1' then
       if com_adc_above_thr = '1' then -- single pulse
        pulse_length_ct  <=  0;
        com_adc_sdout_nd <= '1';
       elsif  pulse_length_ct < MAX_PULSE_LENGTH then
        pulse_length_ct  <= pulse_length_ct  + 1;
       else
        com_adc_sdout_nd <= '0';
       end if; -- com_adc_above_thr = '1'
      end if; --(reset ='1')
     end if; --(rising_edge(clk))
    end process pulse_keeper; 


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

