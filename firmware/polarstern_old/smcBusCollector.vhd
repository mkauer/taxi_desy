----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:15:37 03/01/2017 
-- Design Name: 
-- Module Name:    smcBusCollector - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.types.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity smcBusCollector is 
port(
	chipSelect : in std_logic;
	addressAsync : in std_logic_vector(23 downto 0);
	controlRead : in std_logic;
	controlWrite : in std_logic;
	asyncReset : in std_logic;
	asyncAddressAndControlBus : out std_logic_vector(27 downto 0)
	);
end smcBusCollector;

architecture behaviour of smcBusCollector is
	signal controlBus : smc_asyncBus;
begin
	asyncAddressAndControlBus <= smc_busToAsyncVector(controlBus);
	
	controlBus.chipSelect <= chipSelect;
	controlBus.address(23 downto 0) <= addressAsync;
	controlBus.read <= controlRead;
	controlBus.write <= controlWrite;
	controlBus.asyncReset <= asyncReset;
end behaviour;

