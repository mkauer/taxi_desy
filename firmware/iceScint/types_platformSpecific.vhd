--
--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 
--
--   To use any of the example code shown below, uncomment the lines and modify as necessary
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;

package types_platformSpecific is

constant numberOfChannels_platformSpecific : integer := 8;
constant globalClockRate_platformSpecific : integer := 118750;

--alias numberOfChannels : integer is numberOfChannels_platformSpecific;

end types_platformSpecific;

package body types_platformSpecific is
	
--	constant numberOfChannels_platformSpecific : integer := 8;

end types_platformSpecific;


