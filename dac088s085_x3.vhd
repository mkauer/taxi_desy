----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:24:53 03/15/2017 
-- Design Name: 
-- Module Name:    dac088s085_x3 - Behavioral 
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
use IEEE.numeric_std.all;
use work.types.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity dac088s085_x3 is
--	generic
--	)
--		modulClockRate_Hz : integer := 118750000;
--		spiClockRate_Hz : integer := 10000000;
--	);
	port
	(
		nSync :out std_logic;
		mosi :out std_logic;
		sclk :out std_logic;
		triggerPixelIn : in std_logic_vector(8*8-1 downto 0);
		registerRead : out dac088s085_x3_registerRead_t;
		registerWrite : in dac088s085_x3_registerWrite_t
	);
end dac088s085_x3;

architecture behavioral of dac088s085_x3 is
	constant spiNumberOfBits : integer := 3*16;
	constant sclkDivisor : unsigned(3 downto 0) := x"3"; -- ((systemClock / spiClock) / 2) ... 3=~20MHz@118MHz
	constant sclkDefaultLevel : std_logic := '0';
	constant mosiDefaultLevel : std_logic := '0';
	--constant mosiValidEdge : std_logic := '0'; -- '0'=rising, '1'=falling
	--constant mosiMsbFirst : std_logic := '1'; -- '0'=LsbFirst, '1'=MsbFirst

	type spiState_t is (idle, init,load,transfer0,transfer1,transfer2,transfer3);
	signal spiState : spiState_t := init;

	signal mosiBuffer_latched : std_logic_vector (spiNumberOfBits-1 downto 0);

	signal spiCounter : integer range 0 to 31 := 0;
	signal sclkDivisorCounter : unsigned (3 downto 0) := x"0";
	signal sclk_i : std_logic;
	signal sclkEnable : std_logic;
	signal sclkEdgeRising : std_logic;
	signal sclkEdgeFalling : std_logic;
	
	signal busy : std_logic;
	
	signal registerSpiRx : std_logic_vector(31 downto 0) := (others => '0');
		alias registerSpiRxData is registerSpiRx(15 downto 0);
		alias registerSpiRxChannel is registerSpiRx(18 downto 16);
		alias registerSpiRxChip is registerSpiRx(23 downto 19);
		alias registerSpiRxMagic is registerSpiRx(31 downto 24);
	signal nSync : std_logic := '0';
	signal ss : std_logic_vector(4 downto 0) := "00000";
	signal first : std_logic := '0';
	signal chip : std_logic_vector(4 downto 0) := "00000";
	
begin

	P0:process (clock)
	begin
		if rising_edge(clock) then
			sclkEdgeRising <= '0'; -- autoreset
			sclkEdgeFalling <= '0'; -- autoreset
			if (reset = '1') then
				sclkDivisorCounter <= to_unsigned(0, sclkDivisorCounter'length);
				sclk_i <= sclkDefaultLevel;
			else
				if (sclkDivisorCounter = sclkDivisor) then
					sclkDivisorCounter <= to_unsigned(0, sclkDivisorCounter'length);
					if (sclkEnable = '1') then
						sclk_i <= NOT sclk_i;
						if ((sclk_i = '0')) then
							sclkEdgeRising <= '1'; -- autoreset
						end if;
						if ((sclk_i = '1')) then
							sclkEdgeFalling <= '1'; -- autoreset
						end if;
					else
						sclk_i <= sclkDefaultLevel;
					end if;
				else
					sclkDivisorCounter <= sclkDivisorCounter + 1;
				end if;
			end if;
		end if;
	end process P0;

	spi2:process (clock)
	begin
		if rising_edge(clock) then
			sclkEnable <= '0'; -- autoreset
			busy <= '0'; -- autoreset
			nSync <= '0'; -- autoreset
			registerSpiRx <= dacData;
			if (reset = '1') then
				spiState <= init;
				first <= '0';
			else
				case spiState is					
					when idle =>
						if(spiStartTransfer = '1') then
							spiState <= load;
						end if;

					when load =>
						nSync <= '1'; -- autoreset
						mosiBuffer_latched <= "0000" & "0011" & '0'&registerSpiRxChannel & registerSpiRxData & "0000";
						ss <= registerSpiRxChip;
						spiState <= prepare;
					
					when prepare =>
						nSync <= '1'; -- autoreset
						spiCounter <= mosiBuffer_latched'length-1;
						spiState <= transfer2;
					
					when transfer2 =>
						busy <= '1'; -- autoreset
						sclkEnable <= '1'; -- autoreset
						if (sclkEdgeRising = '1') then
							if(spiCounter /= mosiBuffer_latched'length-1) then
								mosiBuffer_latched(mosiBuffer_latched'length-1 downto 0) <= mosiBuffer_latched(mosiBuffer_latched'length-2 downto 0) & mosiDefaultLevel;
							end if;
							spiCounter <= spiCounter - 1;
							if (spiCounter = 0) then
								spiState <= transfer3;
							end if;
						end if;
										
					when transfer3 =>
						busy <= '1'; -- autoreset
						sclkEnable <= '1'; -- autoreset
						if (sclkEdgeFalling = '1') then
							spiState <= idle;
						end if;

				end case;
			end if;
		end if;
	end process spi2;

end behavioral;
