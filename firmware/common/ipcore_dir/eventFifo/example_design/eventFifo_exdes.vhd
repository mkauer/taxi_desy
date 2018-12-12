--------------------------------------------------------------------------------
--
-- FIFO Generator Core - core top file for implementation
--
--------------------------------------------------------------------------------
--
-- (c) Copyright 2009 - 2010 Xilinx, Inc. All rights reserved.
-- 
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
-- 
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
-- 
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
-- 
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
--------------------------------------------------------------------------------
--
-- Filename: eventFifo_exdes.vhd
--
-- Description:
--   This is the FIFO core wrapper with BUFG instances for clock connections.
--
--------------------------------------------------------------------------------
-- Library Declarations
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library unisim;
use unisim.vcomponents.all;

--------------------------------------------------------------------------------
-- Entity Declaration
--------------------------------------------------------------------------------
entity eventFifo_exdes is
   PORT (
           CLK                       : IN  std_logic;
     	   DATA_COUNT                : OUT std_logic_vector(13-1 DOWNTO 0);
           RST                       : IN  std_logic;
           OVERFLOW                  : OUT std_logic;
           UNDERFLOW                 : OUT std_logic;
           WR_EN 		     : IN  std_logic;
           RD_EN                     : IN  std_logic;
           DIN                       : IN  std_logic_vector(144-1 DOWNTO 0);
           DOUT                      : OUT std_logic_vector(144-1 DOWNTO 0);
           FULL                      : OUT std_logic;
           EMPTY                     : OUT std_logic);

end eventFifo_exdes;



architecture xilinx of eventFifo_exdes is

  signal clk_i    : std_logic;



  component eventFifo is
   PORT (
           CLK                       : IN  std_logic;
     	   DATA_COUNT                : OUT std_logic_vector(13-1 DOWNTO 0);
           RST                       : IN  std_logic;
           OVERFLOW                  : OUT std_logic;
           UNDERFLOW                 : OUT std_logic;
           WR_EN 		     : IN  std_logic;
           RD_EN                     : IN  std_logic;
           DIN                       : IN  std_logic_vector(144-1 DOWNTO 0);
           DOUT                      : OUT std_logic_vector(144-1 DOWNTO 0);
           FULL                      : OUT std_logic;
           EMPTY                     : OUT std_logic);

  end component;


begin
  clk_buf: bufg
    PORT map(
      i => CLK,
      o => clk_i
      );



  exdes_inst : eventFifo 
    PORT MAP (
           CLK                       => clk_i,
           DATA_COUNT                => data_count,
           RST                       => rst,
           OVERFLOW                  => overflow,
           UNDERFLOW                 => underflow,
           WR_EN 		     => wr_en,
           RD_EN                     => rd_en,
           DIN                       => din,
           DOUT                      => dout,
           FULL                      => full,
           EMPTY                     => empty);

end xilinx;
