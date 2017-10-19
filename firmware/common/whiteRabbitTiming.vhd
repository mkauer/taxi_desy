----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:45:59 03/21/2017 
-- Design Name: 
-- Module Name:    gpsTiming - Behavioral 
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

entity whiteRabbitTiming is
	port(
		whiteRabbitPps : in std_logic;
		whiteRabbitClock : in std_logic;
		internalTiming : in internalTiming_t;
		whiteRabbitTiming : out whiteRabbitTiming_t;
		registerRead : out whiteRabbitTiming_registerRead_t;
		registerWrite : in whiteRabbitTiming_registerWrite_t	
	);
end whiteRabbitTiming;

architecture behavioral of whiteRabbitTiming is
	signal localClockSubSecondCounter : signed(31 downto 0) := (others => '0');
	signal localClockSubSecondCounterLatched : std_logic_vector(31 downto 0) := (others => '0');
	signal realTimeCounterLatched : std_logic_vector(63 downto 0) := (others => '0');
	signal whiteRabbitClockCounter : unsigned(31 downto 0) := (others => '0');
	signal whiteRabbitClockCounterLatched : std_logic_vector(31 downto 0) := (others => '0');
	
	signal newData : std_logic := '0';
	
	signal ppsSync : std_logic_vector(5 downto 0) := (others => '0');
	signal clockSync : std_logic_vector(5 downto 0) := (others => '0');
	
begin

whiteRabbitTiming.newData <= newData;
whiteRabbitTiming.realTimeCounterLatched <= realTimeCounterLatched;
whiteRabbitTiming.localClockSubSecondCounterLatched <= localClockSubSecondCounterLatched;
whiteRabbitTiming.whiteRabbitClockCounterLatched <= whiteRabbitClockCounterLatched;

registerRead.counterPeriod <= registerWrite.counterPeriod;

P0:process (registerWrite.clock)
begin
	if rising_edge(registerWrite.clock) then
		newData <= '0'; -- autoreset
		if (registerWrite.reset = '1') then
			localClockSubSecondCounter <= to_signed(0,localClockSubSecondCounter'length);
			realTimeCounterLatched <= (others=>'0');
			localClockSubSecondCounterLatched <= (others=>'0');
			whiteRabbitClockCounterLatched <= (others=>'0');
			whiteRabbitClockCounter <= (others=>'0');
		else
			ppsSync <= ppsSync(ppsSync'left downto 1) & whiteRabbitPps;
			clockSync <= clockSync(clockSync'left downto 1) & whiteRabbitClock;
			
			if((clockSync(clockSync'left) = '0') and (clockSync(clockSync'left-1) = '1')) then
				whiteRabbitClockCounter <= whiteRabbitClockCounter + 1;
			end if;
				
			if((ppsSync(ppsSync'left) = '0') and (ppsSync(ppsSync'left-1) = '1')) then
				localClockSubSecondCounterLatched <= std_logic_vector(localClockSubSecondCounter);
				localClockSubSecondCounter <= to_signed(0,localClockSubSecondCounter'length);
				realTimeCounterLatched <= std_logic_vector(internalTiming.realTimeCounter);
				whiteRabbitClockCounterLatched <= std_logic_vector(whiteRabbitClockCounter);
				whiteRabbitClockCounter <= to_unsigned(0,whiteRabbitClockCounter'length);
				newData <= '1'; -- autoreset
			else
				localClockSubSecondCounter <= localClockSubSecondCounter + 1;
			end if;
			
		end if;
	end if;
end process P0;

end behavioral;

