-------------------------------------------------------
-- Design Name : com_dac_enc 
-- File Name   : com_dac_enc.vhd
-- Function    : com_dac input signal gen. from serial data in
-- Coder       : K.-H. Sulanke, DESY
-- Date        : 2018-11-28
-- Revision    : 03
-------------------------------------------------------
-- encoding falling edges and rising edges as bipolar pulse

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;
    use ieee.numeric_bit.all;
    use ieee.std_logic_arith.all;
Library UNISIM;
    use UNISIM.vcomponents.all;
    
entity com_dac_enc is
   port(
        reset           : in  std_logic;
        clk             : in  std_logic;
        baudrate_adj    : in std_logic_vector(3 downto 0);
        sdin            : in  std_logic; -- serial data input
        com_dac_quiet   : in  std_logic; -- get zero baseline value, when comm. is inactive
        com_dac_in      : out std_logic_vector (11 downto 0); 
        com_dac_clock   : out std_logic
       );
end entity;

architecture com_dac_enc_arch of com_dac_enc is
 
  constant COM_DAC_MAX    : std_logic_vector  :=  X"fff"; -- about 1.5V at transformer 
  
  signal com_dac_val      : std_logic_vector (11 downto 0);
  signal com_dac_din      : std_logic_vector (11 downto 0);
  signal com_dac_clock_nd : std_logic;
  signal sdin_del         : std_logic;
  signal l_pulse          : std_logic;
  signal h_pulse          : std_logic;
  
  --signal dld_edge         : std_logic;
  signal pulse_length     : integer range 0 to 4095;
  signal half_pulse_length : integer range 0 to 4095;
  
  signal ct               : integer range 0 to 4095;
 
 begin
 
   get_pulse_length: process (clk) -- amount of clocks per bit
   begin
   if rising_edge(clk) then
     if reset = '1' then
      pulse_length <=   200 ; half_pulse_length <=  200 / 2 ; --   400 - 1;   150_000 baud
     else 
       if ct = 0 then            -- for synchronized changing of the baudrate    
        case baudrate_adj is
         when X"0"   => pulse_length <=  1200 ; half_pulse_length <= 1200 / 2 ; --  2400 - 1;    25_000 baud
         when X"1"   => pulse_length <=   600 ; half_pulse_length <=  600 / 2 ; --  1200 - 1;    50_000 baud
         when X"2"   => pulse_length <=   300 ; half_pulse_length <=  300 / 2 ; --   600 - 1;   100_000 baud
         when X"3"   => pulse_length <=   240 ; half_pulse_length <=  240 / 2 ; --   480 - 1;   125_000 baud
         when X"4"   => pulse_length <=   200 ; half_pulse_length <=  200 / 2 ; --   400 - 1;   150_000 baud
         when X"5"   => pulse_length <=   120 ; half_pulse_length <=  120 / 2 ; --   240 - 1;   250_000 baud
         when X"6"   => pulse_length <=    80 ; half_pulse_length <=   80 / 2 ; --   160 - 1;   375_000 baud
         when X"7"   => pulse_length <=    60 ; half_pulse_length <=   60 / 2 ; --   120 - 1;   500_000 baud
                                                              
         when others => pulse_length <=   200 ; half_pulse_length <=  200 / 2 ; --   400 - 1;   150_000 baud              
        end case;
       end if; -- tx_ena = '1'
      end if; -- reset = '1' 
     end if; -- rising_edge(clk)   
   end process get_pulse_length; 
 
 
   get_edges: process (clk)
    begin
     if (rising_edge(clk)) then
      -- h_pulse       <= '0';
      -- lh_edge       <= '0';    
      if (reset = '1') then
       sdin_del      <= '0';
       h_pulse       <= '0';
       l_pulse       <= '0';   
      else
        sdin_del <= sdin;
        if    (sdin_del ='0') and (sdin ='1') then
         h_pulse       <= '1';
         l_pulse       <= '0';
        elsif (sdin_del ='1') and (sdin ='0') then
         h_pulse       <= '0';
         l_pulse       <= '1';
        end if;
      end if; -- (reset = '1')
     end if; --  (rising_edge(clk))
    end process get_edges ;                 
 
   com_dac_clock_gen: process (clk)
    begin
     if(rising_edge(clk)) then
      if (ct = pulse_length) or (ct = half_pulse_length) or (ct = 1) then
        com_dac_clock_nd  <= '1';
       else
        com_dac_clock_nd  <= '0';
       end if;           

    end if; --rising_edge(clk) 
   end process com_dac_clock_gen;      

 com_dac_ctrl: process (clk)
	  begin
	   if (rising_edge(clk)) then
      if (reset = '1') then
        com_dac_in  <= X"800"; -- zero level
      else
       if (com_dac_quiet = '1') then
        com_dac_in <= X"800"; -- zero level
       elsif
        ((sdin_del ='0') and (sdin ='1')) or ((sdin_del ='1') and (sdin ='0')) then
        ct   <= pulse_length + 2;       
       elsif ct /= 0 then
        ct <= ct - 1;
        if   (ct > half_pulse_length + 2) then
         if    (l_pulse ='1') then          
          com_dac_in <= X"FFF";
         elsif (h_pulse ='1') then
          com_dac_in <= X"000";
         end if;
        elsif (ct > 3) then
         if    (l_pulse ='1') then          
          com_dac_in <= X"000";
         elsif (h_pulse ='1') then
          com_dac_in <= X"fff";
         end if;
        else
          com_dac_in <= X"800"; 
        end if; -- (ct > half_pulse_length)
       end if; -- (com_dac_quiet = '1')       
      end if; --(reset = '1')
     end if;  -- (rising_edge(clk)) 
    end process com_dac_ctrl; 

  com_dac_clock <= com_dac_clock_nd;

 end architecture com_dac_enc_arch;
