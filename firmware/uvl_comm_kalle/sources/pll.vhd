-------------------------------------------------------------------------------
-- Design Name : pll
-- File Name   : pll.vhd
-- Device      : Spartan 6, XC6SLX9-2TQG144C
-- Function    : pll design to get from 25 MHz local clock
--               6 MHz, USB to UART bridge
--               60 MHz system clock
--               80 MHz communication clock
-- Coder       : K.-H. Sulanke, DESY, 2018-11-29
-- Revision    : 02
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all ;

library unisim ;
use unisim.vcomponents.all ;

ENTITY pll IS
   PORT
   (
      qosc_25MHz  : IN  STD_LOGIC; -- local clock oscillator
      clk         : OUT STD_LOGIC; --  60 MHz, system clock, made by pll_clkout2
      com_clk     : OUT STD_LOGIC; --  60 Mhz, communication clock made by pll_clkout4
      com_reset   : OUT STD_LOGIC; -- communication reset, synchronous to com_clk
      clk_6MHz    : OUT STD_LOGIC; --   6 MHz, USB to UART bridge clock, made by pll_clkout3
      reset       : OUT STD_LOGIC  -- synchronous to the 60 MHz system clock
    );
END pll;

Architecture pll_arch of pll is

  signal pll_rst       : std_logic;    -- 
  signal pll_clkin     : std_logic;  
  signal pll_clkfbin   : std_logic;    -- 
  signal pll_clkout2   : std_logic;    -- pll output,
  signal pll_clkout3   : std_logic;    -- pll output,
  signal pll_clkout4   : std_logic;    -- pll output,
   
  signal pll_locked    : std_logic;    -- active high pll lock signal
  signal pll_reset_ct  : std_logic_vector(3 downto 0) := X"0"; 
  signal reset_ct      : std_logic_vector(3 downto 0) := X"0";  -- synchronous to clk
  signal reset_nd      : std_logic;    -- 
  signal clk_nd        : std_logic;    -- 
  signal com_clk_nd    : std_logic;    -- 
  signal com_reset_nd  : std_logic;    --
  signal com_reset_ct  : std_logic_vector(3 downto 0) := X"0";  -- synchronous to com_clk
  signal clk_12mhz     : std_logic;    -- 
  signal clk_6mhz_nd   : std_logic;    -- 

begin
   
  pll_clkin_BUFG_inst : BUFG
   port map (
         O => pll_clkin, -- 1-bit output: Clock buffer output
         I => qosc_25MHz -- 1-bit input: Clock buffer input
        );
     
 
  PLL_RESET_GEN: process(qosc_25MHz) 
   begin
     if rising_edge (qosc_25MHz) then
      if (pll_reset_ct /= X"F") then
        pll_reset_ct <= pll_reset_ct + '1';
      end if; --(pll_reset_ct /= X"F")   
      if (pll_reset_ct = X"E") then 
       pll_rst <= '1';
      else 
       pll_rst <= '0';
      end if; -- (pll_reset_ct = X"E") 
     end if; -- rising_edge (qosc_25MHz)
   end process PLL_RESET_GEN; 
     
   PLL_BASE_inst : PLL_BASE
   generic map (
     BANDWIDTH          => "LOW", -- "HIGH", "LOW" or "OPTIMIZED"
     CLKFBOUT_MULT      =>  24, --PLL_MULT,   -- Multiplication factor for all output clocks
     CLKFBOUT_PHASE     => 0.0, -- Phase shift (degrees) of all output clocks
     CLKIN_PERIOD       => 40.0, --CLKIN_PERIOD, -- Clock period (ns) of input clock on CLKIN
     CLKOUT0_DIVIDE     => 1,   -- Division factor for CLKOUT0 (1 to 128)
     CLKOUT0_DUTY_CYCLE => 0.5, -- Duty cycle for CLKOUT0 (0.01 to 0.99)
     CLKOUT0_PHASE      => 0.0, -- Phase shift (degrees) for CLKOUT0 (0.0 to 360.0)
     CLKOUT1_DIVIDE     => 1,   -- Division factor for CLKOUT1 (1 to 128)
     CLKOUT1_DUTY_CYCLE => 0.5, -- Duty cycle for CLKOUT1 (0.01 to 0.99)
     CLKOUT1_PHASE      => 0.0, -- Phase shift (degrees) for CLKOUT1 (0.0 to 360.0)
     CLKOUT2_DIVIDE     => 10,   -- Division factor for CLKOUT2 (1 to 128)
     CLKOUT2_DUTY_CYCLE => 0.5, -- Duty cycle for CLKOUT2 (0.01 to 0.99)
     CLKOUT2_PHASE      => 0.0, -- Phase shift (degrees) for CLKOUT2 (0.0 to 360.0)
     CLKOUT3_DIVIDE     => 50, -- Division factor for CLKOUT3 (1 to 128)
     CLKOUT3_DUTY_CYCLE => 0.5, -- Duty cycle for CLKOUT3 (0.01 to 0.99)
     CLKOUT3_PHASE      => 0.0, -- Phase shift (degrees) for CLKOUT3 (0.0 to 360.0)
     CLKOUT4_DIVIDE     => 10, -- Division factor for CLKOUT4 (1 to 128)
     CLKOUT4_DUTY_CYCLE => 0.5, -- Duty cycle for CLKOUT4 (0.01 to 0.99)
     CLKOUT4_PHASE      => 0.0, -- Phase shift (degrees) for CLKOUT4 (0.0 to 360.0)
     CLKOUT5_DIVIDE     => 10, -- Division factor for CLKOUT5 (1 to 128)
     CLKOUT5_DUTY_CYCLE => 0.5, -- Duty cycle for CLKOUT5 (0.01 to 0.99)
     CLKOUT5_PHASE      => 180.0, -- Phase shift (degrees) for CLKOUT5 (0.0 to 360.0)
     COMPENSATION       => "INTERNAL", -- "SYSTEM_SYNCHRNOUS",
                           -- "SOURCE_SYNCHRNOUS", "INTERNAL",
                           -- "EXTERNAL", "DCM2PLL", "PLL2DCM"
     DIVCLK_DIVIDE      => 1,--1,--5,--PLL_DIV, -- Division factor for all clocks (1 to 52)
     REF_JITTER         => 0.100) -- Input reference jitter (0.000 to 0.999 UI%)
     port map (
     CLKFBOUT           => pll_clkfbin, -- General output feedback signal
     CLKOUT0            => open, -- One of six general clock output signals
     CLKOUT1            => open, -- One of six general clock output signals
     CLKOUT2            => pll_clkout2, -- One of six general clock output signals
     CLKOUT3            => pll_clkout3, -- One of six general clock output signals
     CLKOUT4            => pll_clkout4, -- One of six general clock output signals+
     CLKOUT5            => open, -- One of six general clock output signals
     LOCKED             => pll_locked, -- Active high PLL lock signal
     CLKFBIN            => pll_clkfbin, -- Clock feedback input
     CLKIN              => pll_clkin, -- Clock input
     RST                => pll_rst --open -- Asynchronous PLL reset
   );
    

  SYNC_SYS_RESET: process ( pll_locked, clk_nd)
    begin                           -- do power on reset, just once !
     if rising_edge(clk_nd) then   
      --if (pll_locked ='1') then
       if reset_ct /= B"1111" then
        reset_ct <= reset_ct + '1';
       end if;
       if (reset_ct = B"1110") then
        reset_nd <= '1';
       else
        reset_nd <= '0';
       end if;
      ---end if; -- (pll_locked ='1') 
    end if; -- rising_edge(clk_nd)
   end process SYNC_SYS_RESET;      


  SYNC_COM_RESET: process ( pll_locked, com_clk_nd)
    begin                           -- do power on reset, just once !
     if rising_edge(com_clk_nd) then   
      --if (pll_locked ='1') then
       if com_reset_ct /= B"1111" then
        com_reset_ct <= com_reset_ct + '1';
       end if;
       if (com_reset_ct = B"1110") then
        com_reset_nd <= '1';
       else
        com_reset_nd <= '0';
       end if;
      --end if; -- (pll_locked ='1') 
    end if; -- rising_edge(com_clk_nd)
   end process SYNC_COM_RESET;      


  PLL_CLKOUT2_inst: BUFG port map ( I => pll_clkout2,  O => clk_nd );      
  PLL_CLKOUT3_inst: BUFG port map ( I => pll_clkout3,  O => clk_12mhz ); 
  PLL_CLKOUT4_inst: BUFG port map ( I => pll_clkout4,  O => com_clk_nd ); 
  --PLL_CLKOUT5_inst: BUFG port map ( I => pll_clkout5,  O => not_com_clk_nd ); 
  
  CLK_6MHZ_GEN: process (clk_12mhz)
    begin                           -- do power on reset, just once !
     if rising_edge(clk_12mhz) then   
      if (clk_6mhz_nd ='1') then
        clk_6mhz_nd <= '0';
      else
        clk_6mhz_nd <= '1';
      end if;  
    end if; -- rising_edge(clk_nd)
   end process CLK_6MHZ_GEN;      
  
  
  clk        <= clk_nd;
  clk_6mhz   <= clk_6mhz_nd;
  com_clk    <= com_clk_nd;
  reset      <= reset_nd;
  com_reset  <= com_reset_nd;


END pll_arch;
