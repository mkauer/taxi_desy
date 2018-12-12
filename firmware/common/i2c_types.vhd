-- DAC_Controller_3.vhd--------------------------------------------------------------------------------
-- Company: DESY
-- Author: 
-- 
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

package i2c_types is
	constant i2c_direction_read_c : std_logic := '1';
	constant i2c_direction_write_c : std_logic := '0';

	type i2c_message_t is record
		direction : std_logic;
		sendStartBeforeData : std_logic;
		sendStopAfterData : std_logic;
		waitForAckAfterData : std_logic;
		sendAckAfterData : std_logic;
		data : std_logic_vector(7 downto 0);
	end record;

end i2c_types;

--package body i2c_types is
--end i2c_types;
	
