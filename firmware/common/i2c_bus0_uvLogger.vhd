-- DAC_Controller_3.vhd--------------------------------------------------------------------------------
-- Company: DESY
-- Author: 
-- 
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
use work.i2c_types.all;
use work.i2c_tmp10x.all;
use work.i2c_dps310.all;
use work.i2c_hmc6343.all;
use work.types.all;
use work.types_platformSpecific.all;

entity i2c_bus0_uvLogger is
	port 
	(
		i2c_scl : out std_logic;
		i2c_sda : inout std_logic;
		
		registerRead : out tmp10x_uvLogger_registerRead_t;
		registerWrite : in tmp10x_uvLogger_registerWrite_t	
	);
end i2c_bus0_uvLogger;

architecture behavior of i2c_bus0_uvLogger is

	type state_data_t is (init_0, init_1, init_2, idle, send_package, send_1, send_2);
	signal state_data : state_data_t := init_0;
	signal state_callback : state_data_t := init_0;
	
	signal i2c_startTransfer : std_logic := '0';
	signal i2c_transferDone : std_logic := '0';
	signal i2c_busy : std_logic := '0';
	
	signal i2c_dataRead : std_logic_vector(7 downto 0);
	signal i2c_message : i2c_message_t;
	signal i2c_package : i2c_package_t;
	
	signal i : integer range 0 to 7 := 0;

	type tmp_t is array (0 to 1) of std_logic_vector(7 downto 0);
	signal tmp : tmp_t;
	signal temperature : std_logic_vector(15 downto 0);
	signal startConversion : std_logic := '0';
	signal busy : std_logic := '0';

begin
	
	x2: entity work.i2cWrapper generic map (CLK_FREQ_HZ => globalClockRate_platformSpecific_hz, BAUD => 100000)
		port map (registerWrite.clock, registerWrite.reset, i2c_scl, i2c_sda, i2c_busy, i2c_startTransfer, i2c_transferDone, i2c_message, i2c_dataRead);

	registerRead.temperature <= temperature;
	registerRead.busy <= busy;

	P10:process (registerWrite.clock)
	begin
		if rising_edge(registerWrite.clock) then
			i2c_startTransfer <= '0'; -- autoreset
			--if((registerWrite.reset = '1') or (registerWrite.debug2 = '1')) then
			if(registerWrite.reset = '1') then
				state_data <= init_0;
				state_callback <= init_0;
				temperature <= (others=>'0');
				startConversion <= '0';
				busy <= '0';
			else
				startConversion <= startConversion or registerWrite.startConversion;

				case state_data is
					when init_0 =>
						i <= 0;
						if (i2c_busy = '0') then
							--state_data <= init_1;
							state_data <= idle;
						end if;
					
			--		when init_1 =>
			--			i2c_package <= i2c_package_resetNormalSpeed;
			--			state_data <= send_package;
			--			state_callback <= init_2; 
			--			
			--		when init_2 =>
			--			i2c_package <= i2c_package_resetNormalSpeed;
			--			state_data <= send_package;
			--			state_callback <= idle;
					
					when idle =>
						busy <= '0';
						if(startConversion = '1') then
							i2c_package <= i2c_package_tmp10x_readTemperature;
							state_data <= send_package;
							--state_callback <= saveTemperature;
							state_callback <= idle;
							busy <= '1';
						end if;

					--when saveTemperature =>
					--	temperature <= tmp(0) & tmp(1);
					--	state_data <= idle;

					when send_package =>
						i <= 0;
						state_data <= send_1;
					
					when send_1 =>
						if (i2c_busy = '0') then
							i2c_message <= i2c_package(i);
							i2c_startTransfer <= '1'; -- autoreset
							state_data <= send_2;
						end if;
						
					when send_2 =>
						if(i2c_transferDone = '1') then
							state_data <= send_1;
							if(i = i2c_package'length) then
								state_data <= state_callback;							
							end if;
							i <= i + 1;
								--tmp(i) <= i2c_dataRead;
							
							if(i=1) then
								temperature(15 downto 8) <= i2c_dataRead;
							end if;
							if(i=2) then
								temperature(7 downto 0) <= i2c_dataRead;
							end if;
						end if;
					
					when others => state_data <= init_0;
				end case;
			end if;
		end if;
	end process P10;

end behavior;
