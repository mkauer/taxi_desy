----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:18:09 03/01/2017 
-- Design Name: 
-- Module Name:    smcBusEntry - Behavioral 
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
use IEEE.NUMERIC_STD.ALL;
use work.types.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity smcBusEntry is 
	generic (
		addressBitsUsed : integer range 0 to 31 := 16
	);

	port (
		busClock : in std_logic;
		asyncBus : in std_logic_vector(27 downto 0);
		addressAndControlBus : out std_logic_vector(31 downto 0)
	);
end smcBusEntry;

architecture behaviour of smcBusEntry is
	signal controlBus : smc_bus;
	signal asyncControlBus : smc_asyncBus;
	signal ReadSR : std_logic_vector(2 downto 0) := (others=>'0');
	signal WriteSR : std_logic_vector(2 downto 0) := (others=>'0');
	signal address : std_logic_vector(23 downto 0) := (others=>'0');
	signal reset : std_logic_vector(2 downto 0) := (others=>'0');
	signal resetCounter : integer range 0 to 7 := 0;
begin
	asyncControlBus <= smc_asyncVectorToBus(asyncBus);
	addressAndControlBus <= smc_busToVector(controlBus);
	controlBus.address(23 downto 0) <= std_logic_vector(to_unsigned(0, controlBus.address'length-addressBitsUsed)) & address(addressBitsUsed-1 downto 0); --x"00" & address(15 downto 0); -- ##
	controlBus.read <= asyncControlBus.read;
	controlBus.chipSelect <= '1' when ((asyncControlBus.chipSelect = '1') and (address(address'length-1 downto addressBitsUsed) = std_logic_vector(to_unsigned(0, address'length-addressBitsUsed)) )) else '0';
	controlBus.reset <= reset(2);
	controlBus.clock <= busClock;

	--P0: process (asyncControlBus.asyncReset, busClock) is
	P0: process (busClock) is
	begin
		if (asyncControlBus.asyncReset = '1') then
			resetCounter <= 0;
			reset(0) <= '1';
		elsif (rising_edge(busClock)) then
			reset(0) <= '0';
			if (resetCounter /= 7) then
				resetCounter <= resetCounter + 1;
				reset(0) <= '1';
			end if;
		end if;
	end process P0;
	
	P1:process (busClock)
	begin
		if rising_edge(busClock) then
			reset(1) <= reset(0);
			reset(2) <= reset(1);
		end if;  
	end process P1;
	
	P2:process (busClock)
	begin
		if rising_edge(busClock) then
			address <= asyncControlBus.address;
			if(reset(2) = '1') then
				controlBus.writeStrobe <= '0';
				controlBus.readStrobe <= '0';
			else
				ReadSR(2 downto 0) <= ReadSR(1 downto 0) & asyncControlBus.read;
				WriteSR(2 downto 0) <= WriteSR(1 downto 0) & asyncControlBus.write;
				if ((ReadSR(1)='1') and (ReadSR(2)='0')) then
					controlBus.readStrobe <= '1';
				else
					controlBus.readStrobe <= '0';	  
				end if;
				if ((WriteSR(1)='1') and (WriteSR(2)='0')) then
					controlBus.writeStrobe <= '1';
				else
					controlBus.writeStrobe <= '0';	  
				end if;
			end if;
		end if;  
	end process P2;

end behaviour;
