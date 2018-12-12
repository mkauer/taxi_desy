-- DAC_Controller_3.vhd--------------------------------------------------------------------------------
-- Company: DESY
-- Author: 
-- 
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;
use work.i2c_types.all;

library unisim;
use unisim.vcomponents.all;

entity i2cWrapper is
	generic 
	(
		CLK_FREQ_HZ : integer := 125000000;
		BAUD : integer := 100000
	);
	port 
	(
		clock : in std_logic;
		reset : in std_logic;
		i2c_scl : out std_logic;
		i2c_sda : inout std_logic;
	
		busy : out std_logic;
		startTransfer : in std_logic;
		transferDone : out std_logic;
		message : in i2c_message_t;
		dataOut : out std_logic_vector(7 downto 0)
	);
end i2cWrapper;

architecture behavior of i2cWrapper is

--	attribute keep : string;
	
--	signal i2c_control : std_logic_vector(15 downto 0) := x"0000";
--		alias i2c_start : std_logic is i2c_control(0);
--		alias i2c_stop : std_logic is i2c_control(1);
--		alias i2c_read : std_logic is i2c_control(2);
--		alias i2c_write : std_logic is i2c_control(3);
--		alias i2c_sendAcknowledge : std_logic is i2c_control(4);
--		alias i2c_acknowledgeReceived : std_logic is i2c_control(5);
--		alias i2c_free : std_logic is i2c_control(6);
	signal i2c_start : std_logic;
	signal i2c_stop : std_logic;
	signal i2c_read : std_logic;
	signal i2c_write : std_logic;
	signal i2c_sendAcknowledge : std_logic;
	signal i2c_acknowledgeReceived : std_logic;
	signal i2c_free : std_logic;
	signal i2c_ready : std_logic;
	signal i2c_miso : std_logic_vector(7 downto 0);
	signal i2c_mosi : std_logic_vector(7 downto 0);
	
	type state_i2c_t is (s_t0, s_t1, s_t2, s_t3, s_t4, s_t5, s_t6, s_t7);
	signal state_i2c : state_i2c_t := s_t0;
	
	signal sda_in : std_logic := '0';
	signal sda_out : std_logic := '0';
--	attribute keep of sda_out : signal is "true";
	signal scl_out : std_logic := '0';
	signal sda_tri : std_logic := '0';
	signal sda_inAsync : std_logic := '0';
	
	signal i2c_message : i2c_message_t;

begin

	i1: IOBUF port map (O=>sda_inAsync, IO=>i2c_sda, I=>sda_out, T=>sda_tri);
	i2: OBUF port map(O => i2c_scl, I => scl_out);

	x2: entity work.i2c_master_v02
	generic map 
	(
		CLK_FREQ => CLK_FREQ_HZ,
		BAUD => BAUD
	)
	port map
	(
		clock,
		reset,
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
		sda_tri
	);
	
	dataOut <= i2c_miso;
	
	P0:process (clock)
	begin
		if rising_edge(clock) then
		--	if(sda_tri = '1') then
				sda_in <= sda_inAsync;
		--	else
		--		sda_in <= '0';
		--	end if;
		end if;
	end process P0;

	P10:process (clock)
	begin
		if rising_edge(clock) then
			i2c_read <= '0'; --autoreset
			i2c_write <= '0'; --autoreset
			i2c_start <= '0'; --autoreset
			i2c_stop <= '0'; --autoreset
			transferDone <= '0'; -- autoreset
			if(reset = '1') then
				state_i2c <= s_t0;
				i2c_sendAcknowledge <= '0';
				--i2cDoesNotAcknowledge <= '0';
			else
				case state_i2c is
					when s_t0 =>
						busy <= '0';
						if(startTransfer = '1') then
							state_i2c <= s_t1;
							busy <= '1';
							i2c_message <= message;
						end if;
					
					when s_t1 =>
						i2c_sendAcknowledge <= i2c_message.sendAckAfterData;
						if((i2c_free = '1') or (i2c_ready = '1')) then
							if(i2c_message.sendStartBeforeData = '1') then
								i2c_start <= '1'; -- autoreset
								state_i2c <= s_t2;
							else
								state_i2c <= s_t3; -- ## possible deadlock if bus is free an you dont send start
							end if;
						end if;
					
					when s_t2 =>
						if(i2c_ready = '0') then
							state_i2c <= s_t3;
						end if;
										
					when s_t3 =>
						if(i2c_ready = '1') then
							if(i2c_message.direction = i2c_direction_write_c) then
								i2c_mosi <= i2c_message.data;
								i2c_write <= '1'; --autoreset
								state_i2c <= s_t4;
							elsif(i2c_message.direction = i2c_direction_read_c) then
								--i2c_mosi <= x"00";
								i2c_read <= '1'; --autoreset
								state_i2c <= s_t4;
							end if;
						end if;
									
					when s_t4 =>
						if(i2c_ready = '0') then
							state_i2c <= s_t5;
						end if;
									
					when s_t5 =>
						if(i2c_ready = '1') then
							if((i2c_message.waitForAckAfterData = '0') or (i2c_acknowledgeReceived = '1')) then
								state_i2c <= s_t6;
							else
								state_i2c <= s_t7;
							end if;
						end if;
											
					when s_t6 =>
						if(i2c_message.sendStopAfterData = '1') then
							i2c_stop <= '1'; -- autoreset
						end if;
						transferDone <= '1'; -- autoreset
						state_i2c <= s_t0;
					
					when s_t7 =>
						--i2cDoesNotAcknowledge <= '1';
						transferDone <= '1'; -- autoreset ## error?!
						i2c_stop <= '1'; -- autoreset
						state_i2c <= s_t0;
						 
					when others => state_i2c <= s_t0;
				end case;
			end if;
		end if;
	end process P10;

end behavior;
