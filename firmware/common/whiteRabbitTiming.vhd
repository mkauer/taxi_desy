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
--	generic(
--		clockRate_Hz : integer := 0 
--	);
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
	signal realTimeCounter : std_logic_vector(63 downto 0) := (others => '0');
	signal realTimeCounterLatched : std_logic_vector(63 downto 0) := (others => '0');
	signal whiteRabbitClockCounter : unsigned(31 downto 0) := (others => '0');
	signal whiteRabbitClockCounterLatched : std_logic_vector(31 downto 0) := (others => '0');
	
	signal newData : std_logic := '0';
	
	signal ppsSync : std_logic_vector(5 downto 0) := (others => '0');
	signal clockSync : std_logic_vector(5 downto 0) := (others => '0');
	
	signal pps : std_logic := '0';
	signal newSymbol : std_logic := '0';
	signal symbolValue : std_logic := '0';
	signal id : std_logic := '0';
	signal irigData : std_logic_vector(89 downto 0) := (others => '0');
	signal irigDataLatched : std_logic_vector(89 downto 0) := (others => '0');
	
	type stateWR1_t is (sync, low, high);
	signal stateWR1 : stateWR1_t := sync;
	type stateWR2_t is (sync0, sync1, readData);
	signal stateWR2 : stateWR2_t := sync0;

	signal bitCounter : integer range 0 to 255 := 0; 	
	signal ppsCounter : integer range 0 to 2**22-1 := 0; 	

	-- all for 118.75MHz
	-- invalid \ 2ms \ 5ms \ 8ms \ invalid
	constant IDENTIFIER_MAX : integer := 1128125; -- 8ms+1.5ms 
	constant IDENTIFIER_MIN : integer := 771875; -- 5ms+1.5ms
	constant ONE_MIN : integer := 415625; -- 2ms+1.5ms
	constant ZERO_MIN : integer := 59375; -- 2ms-1.5ms
	
	signal errorCounter : unsigned(15 downto 0) := (others => '0');
	signal idCounter : integer range 0 to 15 := 0;
	
begin

whiteRabbitTiming.newData <= newData;
whiteRabbitTiming.realTimeCounterLatched <= realTimeCounterLatched;
whiteRabbitTiming.localClockSubSecondCounterLatched <= localClockSubSecondCounterLatched;
whiteRabbitTiming.whiteRabbitClockCounterLatched <= whiteRabbitClockCounterLatched;
whiteRabbitTiming.irigDataLatched <= irigDataLatched;
registerRead.irigDataLatched <= irigDataLatched;
registerRead.errorCounter <= std_logic_vector(errorCounter);

registerRead.counterPeriod <= registerWrite.counterPeriod;

P0:process (registerWrite.clock)
begin
	if rising_edge(registerWrite.clock) then
		newData <= '0'; -- autoreset
		newSymbol <= '0'; -- autoreset
		id <= '0'; -- autoreset
		--one <= '0'; -- autoreset
		--zero <= '0'; -- autoreset
		if (registerWrite.reset = '1') then
			localClockSubSecondCounter <= to_signed(0,localClockSubSecondCounter'length);
			realTimeCounterLatched <= (others=>'0');
			realTimeCounter <= (others=>'0');
			localClockSubSecondCounterLatched <= (others=>'0');
			whiteRabbitClockCounterLatched <= (others=>'0');
			whiteRabbitClockCounter <= (others=>'0');
			symbolValue <= '0';
			irigData <= (others=>'0');
			irigDataLatched <= (others=>'0');
			stateWR2 <= sync0;
			stateWR1 <= sync;
			errorCounter <= (others=>'0');
			idCounter <= 0;
		else
			ppsSync <= ppsSync(ppsSync'left downto 1) & whiteRabbitPps;
			clockSync <= clockSync(clockSync'left downto 1) & whiteRabbitClock;
			
--			if((clockSync(clockSync'left) = '0') and (clockSync(clockSync'left-1) = '1')) then
--				whiteRabbitClockCounter <= whiteRabbitClockCounter + 1;
--			end if;
--				
--			if((ppsSync(ppsSync'left) = '0') and (ppsSync(ppsSync'left-1) = '1')) then
--				localClockSubSecondCounterLatched <= std_logic_vector(localClockSubSecondCounter);
--				localClockSubSecondCounter <= to_signed(0,localClockSubSecondCounter'length);
--				realTimeCounterLatched <= std_logic_vector(internalTiming.realTimeCounter);
--				whiteRabbitClockCounterLatched <= std_logic_vector(whiteRabbitClockCounter);
--				whiteRabbitClockCounter <= to_unsigned(0,whiteRabbitClockCounter'length);
--				newData <= '1'; -- autoreset
--			else
--				localClockSubSecondCounter <= localClockSubSecondCounter + 1;
--			end if;
			
			pps <= whiteRabbitPps;
			--pps <= ppsSync(ppsSync'left);

			case stateWR1 is
				when sync =>
					if(pps = '0') then
						stateWR1 <= low;
					end if;
					
				when low =>
					if(pps = '1') then
						realTimeCounter <= std_logic_vector(internalTiming.realTimeCounter); -- ## plus diff from serdes...
						stateWR1 <= high;
						ppsCounter <= 0;
					end if;
				
				when high =>
					ppsCounter <= ppsCounter + 1;
					if(pps = '0') then
						stateWR1 <= low;
						--ppsCounterLatched <= ppsCounter;
						if(ppsCounter > IDENTIFIER_MAX) then
							errorCounter <= errorCounter + 1;
						elsif(ppsCounter > IDENTIFIER_MIN) then
							id <= '1'; -- autoreset
						elsif(ppsCounter > ONE_MIN) then
							--one <= '1'; -- autoreset
							symbolValue <= '1';
							newSymbol <= '1'; -- autoreset
						elsif(ppsCounter > ZERO_MIN) then
							--zero <= '1'; -- autoreset
							symbolValue <= '0';
							newSymbol <= '1'; -- autoreset
						else
							errorCounter <= errorCounter + 1;
						end if;
					end if;
			end case;

			case stateWR2 is
				when sync0 =>
					if(id = '1') then
						stateWR2 <= sync1;
					end if;

				when sync1 =>
					if(id = '1') then
						stateWR2 <= readData;
						bitCounter <= 0;
						idCounter <= 0;
					end if;
					--if(one = '1') or (zero = '1') then
					if(symbolValue = '1') then
						stateWR2 <= sync0;
					end if;

				when readData =>
					if(newSymbol = '1') then
						bitCounter <= bitCounter + 1;
						irigData <= irigData(irigData'length-2 downto 0) & symbolValue;
					end if;
					--if((bitCounter >= irigDataLatched'length) or (idCountrt >= 10)) then
					--if(bitCounter >= irigDataLatched'length) then
					if(idCounter >= 10) then
						newData <= '1'; -- autoreset
						realTimeCounterLatched <= realTimeCounter;
						irigDataLatched <= irigData;
						irigData <= (others=>'0');
						--stateWR2 <= sync0;
						stateWR2 <= sync1;
					end if;
					if(id = '1') then
						idCounter <= idCounter + 1;
					end if;
			end case;	
		end if;
	end if;
end process P0;

end behavioral;

