-- DAC_Controller_3.vhd--------------------------------------------------------------------------------
-- Company: DESY
-- Author: 
-- 
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
use work.i2c_dac7678.all;
use work.i2c_types.all;
use work.types.all;
use work.types_platformSpecific.all;

entity i2c_dac1_uvLogger is
	port 
	(
		i2c_scl : out std_logic;
		i2c_sda : inout std_logic;
		
		stats : out dac1_uvLogger_stats_t;
		registerRead : out dac1_uvLogger_registerRead_t;
		registerWrite : in dac1_uvLogger_registerWrite_t	
	);
end i2c_dac1_uvLogger;

architecture behavior of i2c_dac1_uvLogger is

	type state_data_t is (init_0, init_1, init_2, init_3, init_4, init_5, idle, build_package, send_package, send_1, send_2);
	signal state_data : state_data_t := init_0;
	signal state_callback : state_data_t := init_0;
	
	signal i2c_startTransfer : std_logic := '0';
	signal i2c_transferDone : std_logic := '0';
	signal i2c_busy : std_logic := '0';
	
	signal i2c_message : i2c_message_t;
	signal i2c_package : i2c_dac767_package_t;
	
	signal i : integer range 0 to 7 := 0;

	--signal valuesChangedDacA : std_logic_vector(7 downto 0) := x"00";
	--signal valuesChangedDacAReset : std_logic_vector(7 downto 0) := x"00";
	--signal channelDacA : std_logic_vector(2 downto 0) := "000";
	--signal channelDacA_int : integer range 0 to 7 := 0;
	--signal valuesChangedDacB : std_logic_vector(7 downto 0) := x"00";
	--signal valuesChangedDacBReset : std_logic_vector(7 downto 0) := x"00";
	--signal channelDacB : std_logic_vector(2 downto 0) := "000";
	--signal channelDacB_int : integer range 0 to 7 := 0;
	
	constant numberOfDacs : integer := 2;
	type valuesChanged_t is array (0 to numberOfDacs-1) of std_logic_vector(7 downto 0);
	type valuesChangedReset_t is array (0 to numberOfDacs-1) of  std_logic_vector(7 downto 0);
	type dacChannel_t is array (0 to numberOfDacs-1) of std_logic_vector(2 downto 0);
	type dacChannel_int_t is array (0 to numberOfDacs-1) of  integer range 0 to 7;

	signal valuesChanged : valuesChanged_t;
	signal valuesChangedReset : valuesChangedReset_t;
	signal dacChannel : dacChannel_t;
	signal dacChannel_int : dacChannel_int_t;
	
	signal currentDacValue : std_logic_vector(11 downto 0) := x"000";
	signal currentDacChannel : std_logic_vector(2 downto 0) := "000";

begin
	
	x2: entity work.i2cWrapper generic map (CLK_FREQ_HZ => globalClockRate_platformSpecific_hz, BAUD => 100000)
		port map (registerWrite.clock, registerWrite.reset, i2c_scl, i2c_sda, i2c_busy, i2c_startTransfer, i2c_transferDone, i2c_message, open);
	
	registerRead.valuesChangedA <= valuesChanged(0);
	registerRead.valuesChangedB <= valuesChanged(1);
	
	l0: for k in 0 to numberOfDacs-1 generate
		dacChannel_int(k) <= getFistOneFromRight8(valuesChanged(k));
		dacChannel(k) <= std_logic_vector(to_unsigned(dacChannel_int(k),3));
	end generate;


	P1:process (registerWrite.clock)
	begin
		if rising_edge(registerWrite.clock) then
			if(registerWrite.reset = '1') then
				l1: for k in 0 to numberOfDacs-1 loop valuesChanged(k) <= (others=>'1'); end loop;
			else
				registerRead.channelA <= registerWrite.channelA;
				registerRead.channelB <= registerWrite.channelB;
				valuesChanged(0) <= (valuesChanged(0) or registerWrite.valuesChangedA) and not valuesChangedReset(0);
				valuesChanged(1) <= (valuesChanged(1) or registerWrite.valuesChangedB) and not valuesChangedReset(1);
				stats.channelA <= registerWrite.channelA;
				stats.channelB <= registerWrite.channelB;
			end if;
		end if;
	end process P1;

	P10:process (registerWrite.clock)
	begin
		if rising_edge(registerWrite.clock) then
			i2c_startTransfer <= '0'; -- autoreset
			l2: for k in 0 to numberOfDacs-1 loop valuesChangedReset(k) <= (others=>'0'); end loop; -- autoreset 
			if((registerWrite.reset = '1') or (registerWrite.debug2 = '1')) then
				state_data <= init_0;
				state_callback <= init_0;
				registerRead.debug <= x"0"; -- ## remove
			else
				case state_data is
					when init_0 => 
						i <= 0;
						if (i2c_busy = '0') then
							state_data <= init_1;
						end if;
					
					when init_1 =>
						i2c_package <= i2c_package_resetNormalSpeed;
						i2c_package(0).data <= i2c_address_dacA & i2c_direction_write_c;
						state_data <= send_package;
						state_callback <= init_2; 
						
					when init_2 =>
						i2c_package <= i2c_package_resetNormalSpeed;
						i2c_package(0).data <= i2c_address_dacB & i2c_direction_write_c;
						state_data <= send_package;
						state_callback <= init_3; 
						
					when init_3 =>
						i2c_package <= i2c_package_allChannelsToZero;
						i2c_package(0).data <= i2c_address_dacA & i2c_direction_write_c;
						state_data <= send_package;
						state_callback <= init_4;
					
					when init_4 =>
						i2c_package <= i2c_package_allChannelsToZero;
						i2c_package(0).data <= i2c_address_dacB & i2c_direction_write_c;
						state_data <= send_package;
						state_callback <= init_5;

					when init_5 =>
						i2c_package <= i2c_package_useInternalReference;
						i2c_package(0).data <= i2c_address_dacB & i2c_direction_write_c;
						state_data <= send_package;
						state_callback <= idle;
					
					when idle =>
						if(valuesChanged(0) /= x"00") then
							--valuesChangedReset(0)(dacChannel_int(0)) <= '1'; -- autoreset
							--currentDacChannel <= dacChannel(0);
							--currentDacValue <= registerWrite.channelA(dacChannel_int(0));
							--state_data <= build_package;
					
							valuesChangedReset(0)(dacChannel_int(0)) <= '1'; -- autoreset
							i2c_package <= i2c_package_setDacChannel;
							i2c_package(0).data <= i2c_address_dacA & i2c_direction_write_c;
							i2c_package(1).data(2 downto 0) <= dacChannel(0);
							i2c_package(2).data <= registerWrite.channelA(dacChannel_int(0))(11 downto 4);
							i2c_package(3).data(7 downto 4) <= registerWrite.channelA(dacChannel_int(0))(3 downto 0);
							state_data <= send_package;
							state_callback <= idle;
						--end if;
						elsif(valuesChanged(1) /= x"00") then
							--valuesChangedReset(1)(dacChannel_int(1)) <= '1'; -- autoreset
							--currentDacChannel <= dacChannel(1);
							--currentDacValue <= registerWrite.channelB(dacChannel_int(1));
							--state_data <= build_package;

							valuesChangedReset(1)(dacChannel_int(1)) <= '1'; -- autoreset
							i2c_package <= i2c_package_setDacChannel;
							i2c_package(0).data <= i2c_address_dacB & i2c_direction_write_c;
							i2c_package(1).data(2 downto 0) <= dacChannel(1);
							i2c_package(2).data <= registerWrite.channelB(dacChannel_int(1))(11 downto 4);
							i2c_package(3).data(7 downto 4) <= registerWrite.channelB(dacChannel_int(1))(3 downto 0);
							state_data <= send_package;
							state_callback <= idle;
						end if;

				--	when build_package =>
				--		i2c_package <= i2c_package_setDacChannel;
				--		i2c_package(1).data(2 downto 0) <= currentDacChannel;
				--		i2c_package(2).data <= currentDacValue(11 downto 4);
				--		i2c_package(3).data(7 downto 4) <= currentDacValue(3 downto 0);
				--		state_data <= send_package;
				--		state_callback <= idle;
					-----------
					
					when send_package =>
						i <= 0;
						state_data <= send_1;
					
					when send_1 =>
						if (i2c_busy = '0') then
							i2c_message <= i2c_package(i);
							i2c_startTransfer <= '1'; -- autoreset
							i <= i + 1;
							state_data <= send_2;
						end if;
						
					when send_2 =>
						if(i2c_transferDone = '1') then
							state_data <= send_1;
							if(i = i2c_package'length) then
								state_data <= state_callback;							
							end if;
						end if;
					
					when others => state_data <= init_0;
				end case;
			end if;
		end if;
	end process P10;

end behavior;
