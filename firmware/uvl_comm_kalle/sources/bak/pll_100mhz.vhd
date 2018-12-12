-------------------------------------------------------------------------------
-- Design Name : pll_100mhz
-- File Name   : pll_100mhz.vhd
-- Device      : Spartan 6, XC6SLX9-2TQG144C
-- Function    : pll design of the L0_TB_V10 FPGA
--               gets 100mhz local or external clock and generates
--               the system clock
-- Coder       : K.-H. Sulanke, DESY, 2016-08-10
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all ;

library unisim ;
use unisim.vcomponents.all ;

ENTITY pll_100mhz IS
   PORT
   (
      pll_reset   : IN  STD_LOGIC;
      pll_clkin   : IN  STD_LOGIC; -- from dig. trigger backplane
      clk         : OUT STD_LOGIC; -- 100mhz, made from pll_clk2, global clock
      pll_locked  : OUT STD_LOGIC
    );
END pll_100mhz;

Architecture pll_100mhz_arch of pll_100mhz is

  signal pll_clkfbin   : std_logic;    -- 
  signal pll_clkout2   : std_logic;    -- pll output,
  signal pll_locked_nd : std_logic;    -- active high pll lock signal
  
  signal clk_nd        : std_logic;    -- global clock output node, clk <= clk_nd

begin
     
   PLL_BASE_inst : PLL_BASE
   generic map (
     BANDWIDTH          => "LOW", -- "HIGH", "LOW" or "OPTIMIZED"
     CLKFBOUT_MULT      => 8,--5,--23,--47,--PLL_MULT,   -- Multiplication factor for all output clocks
     CLKFBOUT_PHASE     => 0.0, -- Phase shift (degrees) of all output clocks
     CLKIN_PERIOD       => 10.0, --CLKIN_PERIOD, -- Clock period (ns) of input clock on CLKIN
     CLKOUT0_DIVIDE     => 4,   -- Division factor for CLKOUT0 (1 to 128)
     CLKOUT0_DUTY_CYCLE => 0.5, -- Duty cycle for CLKOUT0 (0.01 to 0.99)
     CLKOUT0_PHASE      => 0.0, -- Phase shift (degrees) for CLKOUT0 (0.0 to 360.0)
     CLKOUT1_DIVIDE     => 1,   -- Division factor for CLKOUT1 (1 to 128)
     CLKOUT1_DUTY_CYCLE => 0.5, -- Duty cycle for CLKOUT1 (0.01 to 0.99)
     CLKOUT1_PHASE      => 0.0, -- Phase shift (degrees) for CLKOUT1 (0.0 to 360.0)
     CLKOUT2_DIVIDE     => 8,   -- Division factor for CLKOUT2 (1 to 128)
     CLKOUT2_DUTY_CYCLE => 0.5, -- Duty cycle for CLKOUT2 (0.01 to 0.99)
     CLKOUT2_PHASE      => 0.0, -- Phase shift (degrees) for CLKOUT2 (0.0 to 360.0)
     CLKOUT3_DIVIDE     => 8, -- Division factor for CLKOUT3 (1 to 128)
     CLKOUT3_DUTY_CYCLE => 0.5, -- Duty cycle for CLKOUT3 (0.01 to 0.99)
     CLKOUT3_PHASE      => 0.0, -- Phase shift (degrees) for CLKOUT3 (0.0 to 360.0)
     CLKOUT4_DIVIDE     => 8, -- Division factor for CLKOUT4 (1 to 128)
     CLKOUT4_DUTY_CYCLE => 0.5, -- Duty cycle for CLKOUT4 (0.01 to 0.99)
     CLKOUT4_PHASE      => 180.0, -- Phase shift (degrees) for CLKOUT4 (0.0 to 360.0)
     CLKOUT5_DIVIDE     => 5, -- Division factor for CLKOUT5 (1 to 128)
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
     CLKOUT3            => open, -- One of six general clock output signals
     CLKOUT4            => open, -- One of six general clock output signals+
     CLKOUT5            => open, -- One of six general clock output signals
     LOCKED             => pll_locked_nd, -- Active high PLL lock signal
     CLKFBIN            => pll_clkfbin, -- Clock feedback input
     CLKIN              => pll_clkin, -- Clock input
     RST                => pll_reset --open -- Asynchronous PLL reset
   );
    

  PLL_CLK2_inst: BUFG port map ( I => pll_clkout2,  O => clk_nd );       -- 100 Mhz global clock
      
  pll_locked <= pll_locked_nd;
  clk        <= clk_nd;
--  io_clk     <= io_clk_nd;

END pll_100mhz_arch;
