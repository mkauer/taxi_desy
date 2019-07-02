-- DAC_Controller_3.vhd--------------------------------------------------------------------------------
-- Company: DESY
-- Author: 
-- 
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
use work.i2c_types.all;

package i2c_dac7678 is

--	constant i2c_address : std_logic_vector(6 downto 0) := "1001" & "000"; -- 8 possible devices at the same bus 
	constant i2c_address_dacA : std_logic_vector(6 downto 0) := "1001" & "000";
	constant i2c_address_dacB : std_logic_vector(6 downto 0) := "1001" & "010";
--	constant address_r : std_logic_vector(7 downto 0) := i2c_address & i2c_direction_read_c;
--	constant address_w : std_logic_vector(7 downto 0) := i2c_address & i2c_direction_write_c;

	type i2c_dac767_package_t is array(0 to 3) of i2c_message_t;
	
	constant i2c_package_resetNormalSpeed : i2c_dac767_package_t := (
		(direction => i2c_direction_write_c, sendStartBeforeData => '1', data => x"00",	waitForAckAfterData => '1', sendAckAfterData=> '0', sendStopAfterData => '0'),	
		(direction => i2c_direction_write_c, sendStartBeforeData => '0', data => x"70",	waitForAckAfterData => '1', sendAckAfterData=> '0', sendStopAfterData => '0'),
		(direction => i2c_direction_write_c, sendStartBeforeData => '0', data => x"00",	waitForAckAfterData => '1', sendAckAfterData=> '0', sendStopAfterData => '0'),
		(direction => i2c_direction_write_c, sendStartBeforeData => '0', data => x"00",	waitForAckAfterData => '1', sendAckAfterData=> '0', sendStopAfterData => '1'));
		
	constant i2c_package_allChannelsToZero : i2c_dac767_package_t := (
		(direction => i2c_direction_write_c, sendStartBeforeData => '1', data => x"00",	waitForAckAfterData => '1', sendAckAfterData=> '0', sendStopAfterData => '0'),
		(direction => i2c_direction_write_c, sendStartBeforeData => '0', data => x"3f",	waitForAckAfterData => '1', sendAckAfterData=> '0', sendStopAfterData => '0'),
		(direction => i2c_direction_write_c, sendStartBeforeData => '0', data => x"00",	waitForAckAfterData => '1', sendAckAfterData=> '0', sendStopAfterData => '0'),
		(direction => i2c_direction_write_c, sendStartBeforeData => '0', data => x"00",	waitForAckAfterData => '1', sendAckAfterData=> '0', sendStopAfterData => '1'));
		
		-- write to channel x
	constant i2c_package_setDacChannel : i2c_dac767_package_t := (
		(direction => i2c_direction_write_c, sendStartBeforeData => '1', data => x"00",	waitForAckAfterData => '1', sendAckAfterData=> '0', sendStopAfterData => '0'),
		(direction => i2c_direction_write_c, sendStartBeforeData => '0', data => x"30",	waitForAckAfterData => '1', sendAckAfterData=> '0', sendStopAfterData => '0'),
		(direction => i2c_direction_write_c, sendStartBeforeData => '0', data => x"00",	waitForAckAfterData => '1', sendAckAfterData=> '0', sendStopAfterData => '0'),
		(direction => i2c_direction_write_c, sendStartBeforeData => '0', data => x"00",	waitForAckAfterData => '1', sendAckAfterData=> '0', sendStopAfterData => '1'));
	
	constant i2c_package_useInternalReference : i2c_dac767_package_t := (
		(direction => i2c_direction_write_c, sendStartBeforeData => '1', data => x"00",	waitForAckAfterData => '1', sendAckAfterData=> '0', sendStopAfterData => '0'),
		(direction => i2c_direction_write_c, sendStartBeforeData => '0', data => x"80",	waitForAckAfterData => '1', sendAckAfterData=> '0', sendStopAfterData => '0'),
		(direction => i2c_direction_write_c, sendStartBeforeData => '0', data => x"00",	waitForAckAfterData => '1', sendAckAfterData=> '0', sendStopAfterData => '0'),
		(direction => i2c_direction_write_c, sendStartBeforeData => '0', data => x"10",	waitForAckAfterData => '1', sendAckAfterData=> '0', sendStopAfterData => '1'));

end i2c_dac7678;

--package body i2c_dac7678 is
--end i2c_dac7678;
	
