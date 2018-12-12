-- DAC_Controller_3.vhd--------------------------------------------------------------------------------
-- Company: DESY
-- Author: 
-- 
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

entity i2cWrapper is
	port 
	(
		clock : in std_logic;
		reset : in std_logic;
		dacData : in std_logic_vector(31 downto 0);
		spiStartTransfer : in std_logic;
		i2c_scl : out std_logic;
		i2c_sda : inout std_logic; -- inout std_logic_vector(23 downto 0);
		clear : out std_logic --_vector(23 downto 0)		
	);
end i2cWrapper;

architecture behavior of i2cWrapper is

	constant spiNumberOfBits : integer := 32;
	
	signal registerSpiRx : std_logic_vector(31 downto 0) := (others => '0');
		alias registerSpiRxData is registerSpiRx(15 downto 0);
		alias registerSpiRxChannel is registerSpiRx(18 downto 16);
		alias registerSpiRxChip is registerSpiRx(23 downto 19);
		alias registerSpiRxMagic is registerSpiRx(31 downto 24);
	
---------------------------------------------

	signal i2c_controlAsync : std_logic_vector(15 downto 0) := x"0000";
	signal i2c_control : std_logic_vector(15 downto 0) := x"0000";
		alias i2c_start : std_logic is i2c_control(0);
		alias i2c_stop : std_logic is i2c_control(1);
		alias i2c_read : std_logic is i2c_control(2);
		alias i2c_write : std_logic is i2c_control(3);
		alias i2c_sendAcknowledge : std_logic is i2c_control(4);
		alias i2c_acknowledgeReceived : std_logic is i2c_control(5);
		alias i2c_free : std_logic is i2c_control(6);
		alias i2c_ready : std_logic is i2c_control(7);
	signal i2c_miso : std_logic_vector(7 downto 0);
	signal i2c_mosi : std_logic_vector(7 downto 0);
	
	type state_i2c_t is (s_t0, s_t1, s_t2, s_t3, s_t4, s_t5, s_t6, s_t7, s_t30, s_t40);
	signal state_i2c : state_i2c_t := s_t0;
	type state_data_t is (init_0, init_1, init_2, idle, setRefVoltage_0, setRefVoltage_1, setRefVoltage_2, setClearCode_0, setClearCode_1, setClearCode_2, setDacChannel_0, setDacChannel_1, setDacChannel_2);
	signal state_data : state_data_t := init_0;
	
	signal i2c_reset : std_logic := '0';
	signal i2c_package : i2c_message_t;
	signal i2c_startTransfer : std_logic := '0';
	signal i2c_transferDone : std_logic := '0';
	signal busy : std_logic := '0';
	
	constant i2c_address : std_logic_vector(7 downto 0) := x"57";
	constant i2c_address_read : std_logic_vector(7 downto 0) := i2c_address(6 downto 0) & i2c_direction_read_c;
	alias address_r is i2c_address_read;
	constant i2c_address_write : std_logic_vector(7 downto 0) := i2c_address(6 downto 0) & i2c_direction_write_c;
	alias address_w is i2c_address_write;
	type i2c_packages_t is array(0 to 3) of i2c_message_t;
	
		-- internal ref == on
	constant i2c_package_setRefVoltage : i2c_packages_t := (
		(direction => i2c_direction_write_c, sendStartBeforeData => '1', data => address_w,	waitForAckAfterData => '1', sendStopAfterData => '0'),	
		(direction => i2c_direction_write_c, sendStartBeforeData => '0', data => x"80",		waitForAckAfterData => '1', sendStopAfterData => '0'),
		(direction => i2c_direction_write_c, sendStartBeforeData => '0', data => x"00",		waitForAckAfterData => '1', sendStopAfterData => '0'),
		(direction => i2c_direction_write_c, sendStartBeforeData => '0', data => x"01",		waitForAckAfterData => '1', sendStopAfterData => '1'));
		
		-- clear code = 0x0000
	constant i2c_package_setClearCode : i2c_packages_t := (
		(direction => i2c_direction_write_c, sendStartBeforeData => '1', data => address_w,	waitForAckAfterData => '1', sendStopAfterData => '0'),
		(direction => i2c_direction_write_c, sendStartBeforeData => '0', data => x"50",		waitForAckAfterData => '1', sendStopAfterData => '0'),
		(direction => i2c_direction_write_c, sendStartBeforeData => '0', data => x"00",		waitForAckAfterData => '1', sendStopAfterData => '0'),		
		(direction => i2c_direction_read_c,  sendStartBeforeData => '0', data => x"00",		waitForAckAfterData => '1', sendStopAfterData => '1'));
		
		-- write to channel x
	constant i2c_package_setDacChannel : i2c_packages_t := (
		(direction => i2c_direction_write_c, sendStartBeforeData => '1', data => address_w,	waitForAckAfterData => '1', sendStopAfterData => '0'),
		(direction => i2c_direction_write_c, sendStartBeforeData => '0', data => x"30",		waitForAckAfterData => '1', sendStopAfterData => '0'),
		(direction => i2c_direction_write_c, sendStartBeforeData => '0', data => x"00",		waitForAckAfterData => '1', sendStopAfterData => '0'),
		(direction => i2c_direction_read_c,  sendStartBeforeData => '0', data => x"00",		waitForAckAfterData => '1', sendStopAfterData => '1'));
	
	signal i : integer range 0 to 7 := 0;

	signal sda_in : std_logic := '0';
	signal sda_out : std_logic := '0';
	signal scl_out : std_logic := '0';
	signal in_out : std_logic := '0';
	signal sda_inAsync : std_logic := '0';
	signal i2c_reset_pm : std_logic := '0';
	--signal i2cDoesNotAcknowledge : std_logic := '0';

begin

--	x0: alt_iobuf
--	port map
--	(
--		scl_out,
--		'1',
--		i2c_scl,
--		open
--	);
--	
--	x1: alt_iobuf
--	port map
--	(
--		sda_out,
--		in_out,
--		i2c_sda,
--		sda_inAsync
--	);
	
	i2c_scl <= scl_out;
	i2c_sda <= sda_out when in_out = '1' else 'Z';
	sda_inAsync <= i2c_sda when in_out = '0' else '0';

	
	i2c_reset_pm <= reset or i2c_reset;
	x2: entity work.i2c_master_v01
	generic map 
	(
		CLK_FREQ => 200000000,
		BAUD => 100000
	)
	port map
	(
		clock,
		i2c_reset_pm,
		i2c_start,
		i2c_stop,
		i2c_read,
		i2c_write,
		i2c_sendAcknowledge,
		i2c_mosi,
		i2c_free,
		i2c_acknowledgeReceived,
		i2c_ready,
		open,
		i2c_miso,
		--
		sda_in,
		sda_out,
		scl_out,
		in_out
	);
	
	P0:process (clock)
	begin
		if rising_edge(clock) then
			sda_in <= sda_inAsync;
		end if;
	end process P0;

	P10:process (clock)
	begin
		if rising_edge(clock) then
			registerSpiRx <= dacData;
			i2c_read <= '0'; --autoreset
			i2c_write <= '0'; --autoreset
			i2c_start <= '0'; --autoreset
			i2c_stop <= '0'; --autoreset
			i2c_startTransfer <= '0'; -- autoreset
			i2c_transferDone <= '0'; -- autoreset
			clear <= '0'; -- autoreset
			if(reset = '1' or i2c_reset = '1') then
				state_i2c <= s_t0;
				state_data <= init_0;
				--i2cDoesNotAcknowledge <= '0';
			else
				case state_i2c is
					when s_t0 =>
						busy <= '0';
						if(i2c_startTransfer = '1') then
							state_i2c <= s_t1;
							busy <= '1';
						end if;
					
					when s_t1 =>
						if(i2c_package.sendStartBeforeData = '1') then
							if(i2c_free = '1') then
								i2c_start <= '1'; -- autoreset
								state_i2c <= s_t2;
							end if;
						else
							state_i2c <= s_t2;
						end if;
										
					when s_t2 =>
						if(i2c_ready = '1') then
							if(i2c_package.direction = i2c_direction_write_c) then
								i2c_mosi <= i2c_package.data;
								i2c_write <= '1'; --autoreset
								state_i2c <= s_t3;
							elsif(i2c_package.direction = i2c_direction_read_c) then
								--i2c_mosi <= x"00";
								i2c_read <= '1'; --autoreset
								state_i2c <= s_t3;
							end if;
						end if;
									
					when s_t3 =>
						if(i2c_ready = '0') then
							state_i2c <= s_t4;
						end if;
									
					when s_t4 =>
						if(i2c_ready = '1') then
							if((i2c_package.waitForAckAfterData = '0') or (i2c_acknowledgeReceived = '1')) then
								state_i2c <= s_t6;
							else
								state_i2c <= s_t7;
							end if;
						end if;
											
					when s_t6 =>
						if(i2c_package.sendStopAfterData = '1') then
							i2c_stop <= '1'; -- autoreset
						end if;
						i2c_transferDone <= '1'; -- autoreset
						state_i2c <= s_t0;
					
					when s_t7 =>
						--i2cDoesNotAcknowledge <= '1';
						i2c_stop <= '1'; -- autoreset
						state_i2c <= s_t0;
						 
					when others => state_i2c <= s_t0;
				end case;
				
--------------------------------------------------------------------------------
				case state_data is
					when init_0 => 
						i <= 0;
						if (busy = '0') then
							state_data <= init_1;
							--i2cDoesNotAcknowledge <= '0';
						end if;
					
					when init_1 =>
						state_data <= setRefVoltage_0;
						
					when init_2 =>
						clear <= '1'; -- autoreset
						state_data <= idle;
					
					when idle =>
						if(spiStartTransfer = '1') then
							registerSpiRx <= dacData;
							state_data <= setDacChannel_0;
							if(registerSpiRxMagic = x"21") then -- 0x21 == '!'
								state_data <= init_0;
							end if;
						end if;
					-----
					
					---------
					when setRefVoltage_0 =>
						i <= 0;
						state_data <= setRefVoltage_1;
						
					when setRefVoltage_1 =>
						if (busy = '0') then
							i2c_package <= i2c_package_setRefVoltage(i);
							i2c_startTransfer <= '1'; -- autoreset
							i <= i + 1;
							state_data <= setRefVoltage_2;
						end if;
						
					when setRefVoltage_2 =>
						if(i2c_transferDone = '1') then
							state_data <= setRefVoltage_1;
							if(i = 4) then
								state_data <= setClearCode_0;							
							end if;
						end if;
					---------
					
					---------
					when setClearCode_0 =>
						i <= 0;
						state_data <= setClearCode_1;
						
					when setClearCode_1 =>
						if (busy = '0') then
							i2c_package <= i2c_package_setClearCode(i);
							i2c_startTransfer <= '1'; -- autoreset
							i <= i + 1;
							state_data <= setClearCode_2;
						end if;
						
					when setClearCode_2 =>
						if(i2c_transferDone = '1') then
							state_data <= setClearCode_1;
							if(i = 4) then
								state_data <= init_2;
							end if;
						end if;
					---------
					
					---------
					when setDacChannel_0 =>
						i <= 0;
						state_data <= setDacChannel_1;
						
					when setDacChannel_1 =>
						if (busy = '0') then
							--i2c_package <= i2c_package_setDacChannel(i);
							
							if(i = 0) then
								i2c_package <= i2c_package_setDacChannel(0);
							elsif(i = 1) then
								i2c_package <= i2c_package_setDacChannel(1);
								i2c_package.data <= i2c_package_setDacChannel(1).data(7 downto 3) & registerSpiRxChannel;
							elsif(i = 2) then
								i2c_package <= i2c_package_setDacChannel(2);
								i2c_package.data <= registerSpiRxData(15 downto 8);
							elsif(i = 3) then
								i2c_package <= i2c_package_setDacChannel(3);
								i2c_package.data <= registerSpiRxData(7 downto 0);
							end if;
							
							i2c_startTransfer <= '1'; -- autoreset
							i <= i + 1;
							state_data <= setDacChannel_2;
						end if;
						
					when setDacChannel_2 =>
						if(i2c_transferDone = '1') then
							state_data <= setDacChannel_1;
							if(i = 3) then
								--register_blup(15 downto 8) <= i2c_miso;
							elsif(i = 4) then
								--register_blup(7 downto 0) <= i2c_miso;
								state_data <= idle;
							end if;
						end if;
					---------
					
					when others => state_data <= init_0;
				end case;
			end if;
		end if;
	end process P10;

end behavior;
