library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
use work.hess1u_bus_types.all;

entity als is 
generic
	(
	subAddress : std_logic_vector(15 downto 0) := x"0000";
	subAddressMask : std_logic_vector(15 downto 0)  := x"0000"
	);

port(
	addressAndControlBus : in std_logic_vector(31 downto 0);
	dataBus : inout std_logic_vector(15 downto 0);
	
	i2c_sda : inout std_logic;
	i2c_scl : inout std_logic;

	alsTresholdExceeded : out std_logic
	);
end als;

architecture behaviour of als is

	signal sda_inAsync : std_logic;
	signal sda_in : std_logic;
	signal sda_out : std_logic;
	signal scl_out : std_logic;
	signal in_out : std_logic;

	component alt_iobuf
	port(
        i  : in std_logic;
        oe : in std_logic;
        io : inout std_logic;
        o  : out std_logic
		  );
	end component;

	component i2c_master_v01 
		generic
		(
			CLK_FREQ : natural;
      		BAUD : natural
		);
		port
		(
			sys_clk : IN std_logic;
			sys_rst : IN std_logic;
			start : IN std_logic;
			stop : IN std_logic;
			read : IN std_logic;
			write : IN std_logic;
			send_ack : IN std_logic;
			mstr_din : IN std_logic_vector (7 DOWNTO 0);
			--sda : INOUT std_logic;
			--scl : INOUT std_logic;
			free : OUT std_logic;
			rec_ack : OUT std_logic;
			ready : OUT std_logic;
			core_state : OUT std_logic_vector (5 DOWNTO 0);  --for debug purpose
			mstr_dout : OUT std_logic_vector (7 DOWNTO 0);
			--
			sda_in		: in    std_logic;
			sda_out		: out   std_logic;
			scl_out		: out   std_logic;
			in_out		: out   std_logic
		);
	end component;

	signal chipSelectInternal : std_logic;
	signal readDataBuffer : std_logic_vector(15 downto 0);

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

	signal register_alsLux : std_logic_vector(15 downto 0) := x"0000";
	signal register_alsLuxTreshold : std_logic_vector(15 downto 0) := x"0001";
	signal register_alsStatus : std_logic := '0';
	signal register_alsStatus_latched : std_logic := '0';
	signal register_alsConversionTime : unsigned(15 downto 0) := x"bebc";
	signal als_start : std_logic := '0';
	signal als_busy : std_logic := '0';
	signal clearStatusLatchRequest : std_logic := '0';
	signal clearStatusLatchRequest_reset : std_logic := '0';
	signal register_alsAutomaticReenableMode : std_logic_vector(1 downto 0) := "00";
		alias register_alsAutomaticReenableIfDarkAgain_bit is register_alsAutomaticReenableMode(0);
		alias register_alsDarknesResetsErrorLatch_bit is register_alsAutomaticReenableMode(1);
	
	type state_i2c_t is (s_t0, s_t1, s_t2, s_t3, s_t4, s_t5, s_t6, s_t7, s_t30, s_t40);
	signal state_i2c : state_i2c_t := s_t0;
	--type state_data_t is (s_1, s_2, s_3, s_4, s_5, s_6, s_7, s_8, s_9, s_10, s_11, s_12, s_13, s_14, s_w1, s_w2);
	type state_data_t is (s_0, s_1, s_2, s_3, s_4, s_5, s_11, s_12, s_13, s_14, s_15, s_detect1, s_detect2, s_detect3, s_detect4);
	signal state_data : state_data_t := s_0;
	
	signal counterEnable : std_logic := '0';
	signal counter : unsigned(23 downto 0) := x"000000";

	signal controlBus : hess1u_bus;
	
	signal i2c_reset : std_logic := '0';
	signal i2c_package : i2c_message_t;
	signal i2c_startTransfer : std_logic := '0';
	signal i2c_transferDone : std_logic := '0';
	signal busy : std_logic := '0';
	
	constant sfh5712_address : std_logic_vector(7 downto 0) := x"29";
	constant sfh5712_address_read : std_logic_vector(7 downto 0) := sfh5712_address(6 downto 0) & i2c_direction_read_c;
	alias ad5_r is sfh5712_address_read;
	constant sfh5712_address_write : std_logic_vector(7 downto 0) := sfh5712_address(6 downto 0) & i2c_direction_write_c;
	alias ad5_w is sfh5712_address_write;
	type sfh5712_packages_t is array(0 to 10) of i2c_message_t;
	constant sfh5712_packages : sfh5712_packages_t := (
		(direction => i2c_direction_write_c, sendStartBeforeData => '1', data => ad5_w, waitForAckAfterData => '1', sendStopAfterData => '0'),	
		(direction => i2c_direction_write_c, sendStartBeforeData => '0', data => x"80", waitForAckAfterData => '1', sendStopAfterData => '0'),
		(direction => i2c_direction_write_c, sendStartBeforeData => '0', data => x"03", waitForAckAfterData => '1', sendStopAfterData => '1'),
		
		(direction => i2c_direction_write_c, sendStartBeforeData => '1', data => ad5_w, waitForAckAfterData => '1', sendStopAfterData => '0'),
		(direction => i2c_direction_write_c, sendStartBeforeData => '0', data => x"8c", waitForAckAfterData => '1', sendStopAfterData => '1'),
		(direction => i2c_direction_write_c, sendStartBeforeData => '1', data => ad5_r, waitForAckAfterData => '1', sendStopAfterData => '0'),		
		(direction => i2c_direction_read_c, sendStartBeforeData => '0', data => x"cd", waitForAckAfterData => '0', sendStopAfterData => '1'),
		
		(direction => i2c_direction_write_c, sendStartBeforeData => '1', data => ad5_w, waitForAckAfterData => '1', sendStopAfterData => '0'),
		(direction => i2c_direction_write_c, sendStartBeforeData => '0', data => x"8d", waitForAckAfterData => '1', sendStopAfterData => '1'),
		(direction => i2c_direction_write_c, sendStartBeforeData => '1', data => ad5_r, waitForAckAfterData => '1', sendStopAfterData => '0'),
		(direction => i2c_direction_read_c, sendStartBeforeData => '0', data => x"ab", waitForAckAfterData => '0', sendStopAfterData => '1'));
	signal i : integer range 0 to sfh5712_packages'length-1 := 0;
	
	constant sfh7771_address : std_logic_vector(7 downto 0) := x"38";
	constant sfh7771_address_read : std_logic_vector(7 downto 0) := sfh7771_address(6 downto 0) & i2c_direction_read_c;
	alias ad7_r is sfh7771_address_read;
	constant sfh7771_address_write : std_logic_vector(7 downto 0) := sfh7771_address(6 downto 0) & i2c_direction_write_c;
	alias ad7_w is sfh7771_address_write;
	type sfh7771_packages_t is array(0 to 13) of i2c_message_t;
	constant sfh7771_packages : sfh7771_packages_t := (
		(direction => i2c_direction_write_c, sendStartBeforeData => '1', data => ad7_w, waitForAckAfterData => '1', sendStopAfterData => '0'),	
		(direction => i2c_direction_write_c, sendStartBeforeData => '0', data => x"41", waitForAckAfterData => '1', sendStopAfterData => '0'),
		(direction => i2c_direction_write_c, sendStartBeforeData => '0', data => x"05", waitForAckAfterData => '1', sendStopAfterData => '1'), -- 0x05 => ps: off, als: 100ms
		
		(direction => i2c_direction_write_c, sendStartBeforeData => '1', data => ad7_w, waitForAckAfterData => '1', sendStopAfterData => '0'),	
		(direction => i2c_direction_write_c, sendStartBeforeData => '0', data => x"42", waitForAckAfterData => '1', sendStopAfterData => '0'),
		(direction => i2c_direction_write_c, sendStartBeforeData => '0', data => x"00", waitForAckAfterData => '1', sendStopAfterData => '1'), -- 0x00 => als_gain: 1, led_current: 25mA
		
		(direction => i2c_direction_write_c, sendStartBeforeData => '1', data => ad7_w, waitForAckAfterData => '1', sendStopAfterData => '0'),
		(direction => i2c_direction_write_c, sendStartBeforeData => '0', data => x"46", waitForAckAfterData => '1', sendStopAfterData => '1'),
		(direction => i2c_direction_write_c, sendStartBeforeData => '1', data => ad7_r, waitForAckAfterData => '1', sendStopAfterData => '0'),
		(direction => i2c_direction_read_c, sendStartBeforeData => '0', data => x"cd", waitForAckAfterData => '0', sendStopAfterData => '1'),
		
		(direction => i2c_direction_write_c, sendStartBeforeData => '1', data => ad7_w, waitForAckAfterData => '1', sendStopAfterData => '0'),
		(direction => i2c_direction_write_c, sendStartBeforeData => '0', data => x"47", waitForAckAfterData => '1', sendStopAfterData => '1'),
		(direction => i2c_direction_write_c, sendStartBeforeData => '1', data => ad7_r, waitForAckAfterData => '1', sendStopAfterData => '0'),
		(direction => i2c_direction_read_c, sendStartBeforeData => '0', data => x"ab", waitForAckAfterData => '0', sendStopAfterData => '1'));
	signal k : integer range 0 to sfh7771_packages'length-1 := 0;
	signal i2cDoesNotAcknowledge : std_logic := '0';
	signal i2c_reset_pm : std_logic;
	
	signal register_sfh7771_gain : std_logic_vector(1 downto 0) := "11";
	signal register_sfh7771_gain_value : std_logic_vector(7 downto 0) := "00000000";
	
	signal alsType : std_logic_vector(1 downto 0) := "00";
	
begin
	scl_out_buffer: alt_iobuf
	port map
	(
		scl_out,
		'1',
		i2c_scl,
		open
	);
	
	y: alt_iobuf
	port map
	(
		sda_out,
		in_out,
		i2c_sda,
		sda_inAsync
	);
	
	i2c_reset_pm <= controlBus.reset or i2c_reset;
	i2c_master_1 : i2c_master_v01
	generic map 
	(
		CLK_FREQ => 125000000,
		BAUD => 100000
	)
	port map
	(
		controlBus.clock,
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

	controlBus <= hess1u_vectorToBus(addressAndControlBus);
	chipSelectInternal <= '1' when ((controlBus.chipSelect = '1') and ((controlBus.address(15 downto 0) and subAddressMask) = subAddress)) else '0';
	dataBus <= readDataBuffer when ((chipSelectInternal = '1') and (controlBus.read = '1')) else (others => 'Z');

	with register_sfh7771_gain select register_sfh7771_gain_value <=
		"00000000" when "00",
		"00010100" when "01",
		"00101000" when "10",
		"00111100" when "11";
	
	P0:process (controlBus.clock)
	begin
		if rising_edge(controlBus.clock) then
			sda_in <= sda_inAsync;
		end if;
	end process P0;
	
	P1:process (controlBus.clock)
	begin
		if rising_edge(controlBus.clock) then
			i2c_reset <= '0'; -- autoreset
			if(clearStatusLatchRequest_reset = '1') then
				clearStatusLatchRequest <= '0';
			end if;
			if (controlBus.reset = '1') then
				register_alsLuxTreshold <= x"0001";
				register_alsAutomaticReenableMode <= (others => '0');
				register_alsConversionTime <= x"bebc";
				register_sfh7771_gain <= "11";
			else
				if ((controlBus.writeStrobe = '1') and (controlBus.readStrobe = '0') and (chipSelectInternal = '1')) then
					case (controlBus.address(15 downto 0) and not(subAddressMask)) is
						when x"0002" => register_alsLuxTreshold <= dataBus;
						when x"0004" => clearStatusLatchRequest <= '1'; -- autoreset
						when x"0006" => register_alsConversionTime <= unsigned(dataBus);
						when x"0008" => register_alsAutomaticReenableMode <= dataBus(1 downto 0); -- autoreset
						when x"000a" => register_sfh7771_gain <= dataBus(1 downto 0);
							i2c_reset <= '1'; -- autoreset
						--when x"000c" =>
						when others => NULL;
					end case;
				elsif ((controlBus.readStrobe = '1') and (controlBus.writeStrobe = '0') and (chipSelectInternal = '1')) then	
					case (controlBus.address(15 downto 0) and not(subAddressMask)) is
						when x"0000" => readDataBuffer <= register_alsLux;
						when x"0002" => readDataBuffer <= register_alsLuxTreshold;
						when x"0004" => readDataBuffer <= x"000" & "00" & register_alsStatus & register_alsStatus_latched; -- values not affected by reset
						when x"0006" => readDataBuffer <= std_logic_vector(register_alsConversionTime);
						when x"0008" => readDataBuffer <= x"000" & "00" & register_alsAutomaticReenableMode;
						when x"000a" => readDataBuffer <= x"000" & "00" & register_sfh7771_gain;
						when x"000c" => readDataBuffer <= x"000" & "00" & alsType;
						when others  => readDataBuffer <= (others => '0');
					end case;
				end if;
			end if;
		end if;
	end process P1;

	alsTresholdExceeded <= register_alsStatus_latched;
	P10:process (controlBus.clock)
	begin
		if rising_edge(controlBus.clock) then
			i2c_read <= '0'; --autoreset
			i2c_write <= '0'; --autoreset
			i2c_start <= '0'; --autoreset
			i2c_stop <= '0'; --autoreset
			clearStatusLatchRequest_reset <= '0'; -- autoreset
			i2c_startTransfer <= '0'; -- autoreset
			i2c_transferDone <= '0'; -- autoreset			
			if(controlBus.reset = '1' or i2c_reset = '1') then
				state_i2c <= s_t0;
				state_data <= s_0;
				i2cDoesNotAcknowledge <= '0';
				alsType <= "00";
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
						i2cDoesNotAcknowledge <= '1';
						i2c_stop <= '1'; -- autoreset
						state_i2c <= s_t0;
						 
					when others => state_i2c <= s_t0;
				end case;
				
--------------------------------------------------------------------------------
				case state_data is
					when s_0 => 
						i <= 0;
						k <= 0;
						alsType <= "00";
						if (busy = '0') then
							state_data <= s_detect1;
							i2cDoesNotAcknowledge <= '0';
						end if;
					
					when s_detect1 =>
						if (busy = '0') then
							i2c_package <= sfh5712_packages(0);
							i2c_startTransfer <= '1'; -- autoreset
							state_data <= s_detect2;
						end if;
					
					when s_detect2 =>
						if(i2cDoesNotAcknowledge = '1') then
							i2cDoesNotAcknowledge <= '0';
							state_data <= s_detect3;
						else
							if(i2c_transferDone = '1') then
								i <= 1;
								state_data <= s_1;
								alsType <= "01";
							end if;
						end if;
				
					when s_detect3 =>
						if (busy = '0') then
							i2c_package <= sfh7771_packages(0);
							i2c_startTransfer <= '1'; -- autoreset
							state_data <= s_detect4;
						end if;
					
					when s_detect4 =>
						if(i2cDoesNotAcknowledge = '1') then
							i2cDoesNotAcknowledge <= '0';
							state_data <= s_0;
						else
							if(i2c_transferDone = '1') then
								k <= 1;
								alsType <= "10";
								state_data <= s_11;
							end if;
						end if;
						
					when s_1 =>
						if (busy = '0') then
							i2c_package <= sfh5712_packages(i);
							i2c_startTransfer <= '1'; -- autoreset
							state_data <= s_2;
						end if;
						
					when s_2 =>
						if(i2c_transferDone = '1') then
							i <= i + 1;
							if(i = 2) then
								state_data <= s_3;
							elsif(i = 6) then
								register_alsLux(7 downto 0) <= i2c_miso;--i2c_package.data;
								state_data <= s_1;
							elsif(i = 10) then
								register_alsLux(15 downto 8) <= i2c_miso;--i2c_package.data;
								state_data <= s_5;
							else
								state_data <= s_1;
							end if;
							
							if(i >= sfh5712_packages'length-1) then
								i <= 3;
							end if;
						end if;
					
					when s_3 =>
							counterEnable <= '0';
							state_data <= s_4;
							
					when s_4 =>
						counterEnable <= '1';
						if(counter(23 downto 8) >= register_alsConversionTime) then
							counterEnable <= '0';
							state_data <= s_1;
						end if;
						
					when s_5 =>
						if(register_alsLux > register_alsLuxTreshold) then
							register_alsStatus <= '1';
							register_alsStatus_latched <= '1'; -- not affected by reset	
							if(register_alsAutomaticReenableIfDarkAgain_bit = '0') then
								clearStatusLatchRequest_reset <= '1'; -- autoreset
							end if;
						else
							register_alsStatus <= '0';
							
							if(register_alsDarknesResetsErrorLatch_bit = '1') then
								register_alsStatus_latched <= '0'; -- not affected by reset
							end if;
														
							if(clearStatusLatchRequest = '1') then
								clearStatusLatchRequest_reset <= '1'; -- autoreset
								register_alsStatus_latched <= '0'; -- not affected by reset
							end if;		
						end if;
						state_data <= s_3;
						
						---------------
					when s_11 =>
						if (busy = '0') then
							i2c_package <= sfh7771_packages(k);
							if(k = 5) then
								i2c_package.data <= register_sfh7771_gain_value;
							end if;
							i2c_startTransfer <= '1'; -- autoreset
							state_data <= s_12;
						end if;
						
					when s_12 =>
						if(i2c_transferDone = '1') then
							k <= k + 1;
							if(k = 5) then
								state_data <= s_13;
							elsif(k = 9) then
								register_alsLux(7 downto 0) <= i2c_miso;--i2c_package.data;
								state_data <= s_11;
							elsif(k = 13) then
								register_alsLux(15 downto 8) <= i2c_miso;--i2c_package.data;
								state_data <= s_15;
							else
								state_data <= s_11;
							end if;
							
							if(k >= sfh7771_packages'length-1) then
								k <= 6;
							end if;
						end if;
					
					when s_13 =>
							counterEnable <= '0';
							state_data <= s_14;
							
					when s_14 =>
						counterEnable <= '1';
						if(counter(23 downto 8) >= register_alsConversionTime) then
							counterEnable <= '0';
							state_data <= s_11;
						end if;
						
					when s_15 =>
						if(register_alsLux > register_alsLuxTreshold) then
							register_alsStatus <= '1';
							register_alsStatus_latched <= '1'; -- not affected by reset	
							if(register_alsAutomaticReenableIfDarkAgain_bit = '0') then
								clearStatusLatchRequest_reset <= '1'; -- autoreset
							end if;
						else
							register_alsStatus <= '0';
							
							if(register_alsDarknesResetsErrorLatch_bit = '1') then
								register_alsStatus_latched <= '0'; -- not affected by reset
							end if;
														
							if(clearStatusLatchRequest = '1') then
								clearStatusLatchRequest_reset <= '1'; -- autoreset
								register_alsStatus_latched <= '0'; -- not affected by reset
							end if;		
						end if;
						state_data <= s_13;	
					
					when others => state_data <= s_0;
				end case;
			end if;
		end if;
	end process P10;

	P11:process (controlBus.clock)
	begin
		if rising_edge(controlBus.clock) then
			if (counterEnable = '1') then
				counter <= counter + 1;
			else
				counter <= to_unsigned(0,counter'length);
			end if;
		end if;
	end process P11;

end behaviour;
