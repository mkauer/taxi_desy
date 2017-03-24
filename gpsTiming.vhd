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

entity gpsTiming is
	generic(
		ticksPerBit : integer := 12370; --12370 => 9600baud@118.75MHz
		bitTimeSamlePoint : integer := 6000
	);
	port(
		gpsPps : in std_logic;
		gpsTimepulse2 : in std_logic;
		gpsRx : in std_logic;
		gpsTx : out std_logic;
		gpsIrq : out std_logic;
		gpsNotReset : out std_logic;
		gpsTiming : out gpsTiming_t;
		registerRead : out gpsTiming_registerRead_t;
		registerWrite : in gpsTiming_registerWrite_t	
	);
end gpsTiming;

architecture behavioral of gpsTiming is
	type state2_t is (sync, idle, startBit, sample, stopBit);
	signal state2 : state2_t := sync;
	
	signal differenceGpsToLocalClock : signed(31 downto 0) := (others => '0');
	signal localClockSubSecondCounter : signed(31 downto 0) := (others => '0');
	signal cycleCountLatched : std_logic_vector(31 downto 0) := (others => '0');
	signal gpsRx_now : std_logic := '0';
	signal rx : std_logic := '0';
	signal gpsPps_now : std_logic := '0';
	signal gpsPps_old : std_logic := '0';
	signal rxBuffer : std_logic_vector(8*24-1 downto 0) := (others => '0');
	signal PacketTimTp : std_logic_vector(rxBuffer'length-1 downto 0) := (others => '0');
		alias MessageTimTp is PacketTimTp(18*8-1 downto 2*8);
			alias syncChar1 is PacketTimTp(1*8-1 downto 0*8);
			alias syncChar2 is PacketTimTp(2*8-1 downto 1*8);
			alias class is PacketTimTp(3*8-1 downto 2*8);
			alias id is PacketTimTp(4*8-1 downto 3*8);
			alias len is PacketTimTp(6*8-1 downto 4*8);
		
			alias towMS is PacketTimTp(10*8-1 downto 6*8); 
			alias towSubMS is PacketTimTp(14*8-1 downto 10*8); -- will be 0
			alias qErr is PacketTimTp(18*8-1 downto 14*8);
			alias week is PacketTimTp(20*8-1 downto 18*8);
			alias flags is PacketTimTp(21*8-1 downto 20*8);
				alias timebase is PacketTimTp(20*8+0);
				alias utc is PacketTimTp(20*8+1);
			alias reserved1 is PacketTimTp(22*8-1 downto 21*8);
	
	signal tick_ms : std_logic := '0';
	signal newData : std_logic := '0';
	
	signal counter_ms : integer range 0 to 2**17-1 := 0;
	signal counter1 : integer range 0 to 2**7-1 := 0;
	signal counter2 : integer range 0 to 2**16-1 := 0;
	
	signal bitCounter : integer range 0 to 15 := 0;
	signal byteCounter : integer range 0 to 31 := 0;
	
begin

gpsTiming.newData <= newData;
gpsTiming.week <= week;
gpsTiming.quantizationError <= qErr;
gpsTiming.timeOfWeekMilliSecond <= towMS;
gpsTiming.timeOfWeekSubMilliSecond <= towSubMS;
gpsTiming.differenceGpsToLocalClock <= std_logic_vector(resize(differenceGpsToLocalClock, 16));

registerRead.week <= week;
registerRead.quantizationError <= qErr;
registerRead.timeOfWeekMilliSecond <= towMS;
registerRead.timeOfWeekSubMilliSecond <= towSubMS;
registerRead.differenceGpsToLocalClock <= std_logic_vector(resize(differenceGpsToLocalClock, 16));

gpsTx <= '0';
gpsIrq <= '0';
gpsNotReset <= '1';

P0:process (registerWrite.clock)
begin
	if rising_edge(registerWrite.clock) then
		tick_ms <= '0'; -- autoreset
		newData <= '0'; -- autoreset
		if (registerWrite.reset = '1') then
			localClockSubSecondCounter <= to_signed(0,localClockSubSecondCounter'length);
			counter_ms <= 1;
			state2 <= sync;
		else
			gpsPps_now <= gpsPps; -- ## not in sync....
			gpsPps_old <= gpsPps_now; 
			
			gpsRx_now <= gpsRx;
			rx <= gpsRx_now;	
			
			if((gpsPps_old = '0') and (gpsPps_now = '1')) then
				cycleCountLatched <= std_logic_vector(localClockSubSecondCounter);
				localClockSubSecondCounter <= to_signed(0,localClockSubSecondCounter'length);
				differenceGpsToLocalClock <= to_signed(118750000,differenceGpsToLocalClock'length) - localClockSubSecondCounter;
			else
				localClockSubSecondCounter <= localClockSubSecondCounter + 1;
			end if;
			
			counter_ms <= counter_ms + 1;
			if(counter_ms = 118750) then
				counter_ms <= 1;
				tick_ms <= '1'; -- autoreset
			end if;
			
			case state2 is				
				when sync =>
					if(rx = '1') then
						if(tick_ms = '1') then
							counter1 <= counter1 + 1;
						end if;
						if(counter1 = 100) then
							state2 <= idle;
							byteCounter <= 0;
						end if;
					else
						counter1 <= 0;
					end if;
					
				when idle =>
					if(rx = '0') then -- startbit
						state2 <= startBit;
						bitCounter <= 0;
						counter2 <= 0;
					end if;
					
				when startBit =>
					counter2 <= counter2 + 1;
					if(counter2 = ticksPerBit) then
						counter2 <= 0;
						bitCounter <= 0;
						state2 <= sample;
					end if;
					
				when sample =>
					counter2 <= counter2 + 1;
					if(counter2 = bitTimeSamlePoint) then
						rxBuffer <= rx & rxBuffer(rxBuffer'length-1 downto 1);
						bitCounter <= bitCounter + 1;
					end if;
					if(counter2 = ticksPerBit) then
						counter2 <= 0;
						if(bitCounter = 8) then
							state2 <= stopBit;
							byteCounter <= byteCounter + 1;
						end if;
					end if;
					
				when stopBit =>
					if(rx = '1') then
						state2 <= idle;
						if(byteCounter = 1) then
							if(rxBuffer(rxBuffer'length-1-0*8 downto rxBuffer'length-1*8) /= x"b5") then
								byteCounter <= 0;
							end if;
						elsif(byteCounter = 2) then
							if(rxBuffer(rxBuffer'length-1-0*8 downto rxBuffer'length-1*8) /= x"62") then
								byteCounter <= 0;
							end if;
						end if;
						
						if(byteCounter = 4) then
							if((rxBuffer(rxBuffer'length-1-0*8 downto rxBuffer'length-1*8) = x"01") and 
								(rxBuffer(rxBuffer'length-1-1*8 downto rxBuffer'length-2*8) = x"0d") and 
								(rxBuffer(rxBuffer'length-1-2*8 downto rxBuffer'length-3*8) = x"62") and 
								(rxBuffer(rxBuffer'length-1-3*8 downto rxBuffer'length-4*8) = x"b5")) then
								null; -- packed found....
							else
								byteCounter <= 0;								
							end if;
						end if;
						if(byteCounter = 24) then
							byteCounter <= 0;
							PacketTimTp <= rxBuffer;
							newData <= '1'; -- autoreset
						end if;
					end if;			
					
				when others => null;
			end case;

			if(newData = '1') then
				-- ## implement checksum algorithm RFC 1145 / page 86 in ublox protocol spec
			end if;
			
		end if;
	end if;
end process P0;

end behavioral;

