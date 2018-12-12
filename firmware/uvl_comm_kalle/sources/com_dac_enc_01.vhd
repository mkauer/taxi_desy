-------------------------------------------------------
-- Design Name : com_dac_enc 
-- File Name   : com_dac_enc.vhd
-- Function    : com_dac input signal gen. from serial data in
-- Coder       : K.-H. Sulanke, DESY
-- Date        : 2018-11-14
-- Revision    : 01
-------------------------------------------------------
-- is functional 

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
  signal lh_edge          : std_logic;
  signal hl_edge          : std_logic;
  signal dld_edge         : std_logic;
 
 begin
 
   get_edges: process (clk)
    begin
     if (rising_edge(clk)) then
       hl_edge       <= '0';
       lh_edge       <= '0';    
      if (reset = '1') then
       sdin_del      <= '0';
      else
        sdin_del <= sdin;
        if    (sdin_del ='0') and (sdin ='1') then
         hl_edge       <= '0';
         lh_edge       <= '1';
        elsif (sdin_del ='1') and (sdin ='0') then
         hl_edge       <= '1';
         lh_edge       <= '0'; 
        end if;
      end if; -- (reset = '1')
     end if; --  (rising_edge(clk))
    end process get_edges ;                 
 
   com_dac_clock_gen: process (com_dac_quiet, clk)
    begin
     if(rising_edge(clk)) then
      if com_dac_quiet = '1' then
       com_dac_clock_nd  <= '0';
       dld_edge          <= '0';
      else
       dld_edge          <= lh_edge or hl_edge;
       com_dac_clock_nd  <= dld_edge;
      end if; -- com_dac_quiet = '1'
    end if; --rising_edge(clk) 
   end process com_dac_clock_gen;      
 

  com_dac_ctrl: process (clk)
	  begin
	   if (rising_edge(clk)) then
      com_dac_val <= COM_DAC_MAX;
      if (reset = '1') then
        com_dac_in  <= X"800"; -- zero level
      else
       if (com_dac_quiet = '1') then
        com_dac_in <= X"800"; -- zero level
       elsif (lh_edge ='1') then
        com_dac_in <=      com_dac_val; 
       elsif (hl_edge ='1') then
        com_dac_in <= NOT com_dac_val; 
       end if; -- (com_dac_quiet = '1')       
      end if; --(reset = '1')
     end if;  -- (rising_edge(clk)) 
    end process com_dac_ctrl; 

  com_dac_clock <= com_dac_clock_nd;

 end architecture com_dac_enc_arch;
