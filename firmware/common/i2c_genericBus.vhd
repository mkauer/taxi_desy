-- DAC_Controller_3.vhd--------------------------------------------------------------------------------
-- Company: DESY
-- Author: 
-- 
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
use work.i2c_types.all;
use work.types.all;
use work.types_platformSpecific.all;

entity i2c_genericBus is
	port 
	(
		i2c_scl : out std_logic;
		i2c_sda : inout std_logic;
		
		registerRead : out i2c_genericBus_registerRead_t;
		registerWrite : in i2c_genericBus_registerWrite_t	
	);
end i2c_genericBus;

architecture behavior of i2c_genericBus is

	type state_data_t is (idle, send_1, send_2);
	signal state_data : state_data_t := idle;
	
	signal i2c_startTransfer : std_logic := '0';
	signal i2c_transferDone : std_logic := '0';
	signal i2c_busy : std_logic := '0';
	
	--signal startTransfer : std_logic := '0';
	
	signal i2c_dataRead : std_logic_vector(7 downto 0);
	signal i2c_message : i2c_message_t;
	
begin
	
	x2: entity work.i2cWrapper generic map (CLK_FREQ_HZ => globalClockRate_platformSpecific_hz, BAUD => 100000)
		port map (registerWrite.clock, registerWrite.reset, i2c_scl, i2c_sda, i2c_busy, i2c_startTransfer, i2c_transferDone, i2c_message, i2c_dataRead);

	P10:process (registerWrite.clock)
	begin
		if rising_edge(registerWrite.clock) then
			i2c_startTransfer <= '0'; -- autoreset
			if(registerWrite.reset = '1') then
				state_data <= idle;
				registerRead.busy <= '0';
			else
				--startTransfer <= startTransfer or registerWrite.startTransfer;

				case state_data is
					when idle =>
						registerRead.busy <= '0';
						if(registerWrite.startTransfer = '1') then
							registerRead.busy <= '1';
							i2c_message.direction <= registerWrite.direction;
							i2c_message.sendStartBeforeData <= registerWrite.sendStartBeforeData;
							i2c_message.sendStopAfterData <= registerWrite.sendStopAfterData;
							i2c_message.waitForAckAfterData <= registerWrite.waitForAckAfterData;
							i2c_message.sendAckAfterData <= registerWrite.sendAckAfterData;
							i2c_message.data <= registerWrite.data;
							state_data <= send_1;
						end if;

					when send_1 =>
						if (i2c_busy = '0') then
							i2c_startTransfer <= '1'; -- autoreset
							state_data <= send_2;
						end if;
						
					when send_2 =>
						if(i2c_transferDone = '1') then
							state_data <= idle;
							--if(i2c_message.direction = i2c_direction_read_c) then
								registerRead.data <= i2c_dataRead;
							--end if;
						end if;
					
					when others => state_data <= idle;
				end case;
			end if;
		end if;
	end process P10;

end behavior;
