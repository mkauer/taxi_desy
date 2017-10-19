----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:49:38 06/23/2017 
-- Design Name: 
-- Module Name:    triggerSystem - Behavioral 
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

entity iceTad is
	generic(
		numberOfUarts : integer := 8
	);
	port(
		nP24VOn : out std_logic_vector(7 downto 0);
		nP24VOnTristate : out std_logic_vector(7 downto 0);
		rs485In : in std_logic_vector(7 downto 0);
		rs485Out : out std_logic_vector(7 downto 0);
		rs485DataTristate : out std_logic_vector(7 downto 0);
		rs485DataEnable : out std_logic_vector(7 downto 0);
		registerRead : out iceTad_registerRead_t;
		registerWrite : in iceTad_registerWrite_t	
	);
end iceTad;

architecture Behavioral of iceTad is

	signal rs485DataIn_intern : std_logic_vector(numberOfUarts-1 downto 0);
	signal rs485DataEnable_intern : std_logic_vector(numberOfUarts-1 downto 0);
	signal txBusy : std_logic_vector(7 downto 0) := (others=>'0');
	signal rxBusy : std_logic_vector(7 downto 0) := (others=>'0');

begin

	registerRead.powerOn <= registerWrite.powerOn;

	nP24VOn <= (others=>'0');
	registerRead.rs485RxBusy <= rxBusy;
	registerRead.rs485TxBusy <= txBusy;

	g1: for i in 0 to numberOfUarts-1 generate
		rs485DataIn_intern(i) <= rs485In(i) and not(rs485DataEnable_intern(i));
		x0: entity work.uart_RxTx_V2
		generic map(
			Quarz_Taktfrequenz => 118750000,
			Baudrate => 9600
		)
		port map(
			CLK => registerWrite.clock,
			RXD => rs485DataIn_intern(i),
			TXD => rs485Out(i),
			RX_Data => registerRead.rs485Data(i),
			TX_Data => registerWrite.rs485Data(i),
			RX_Busy => rxBusy(i),
			TX_Busy => txBusy(i),
			TX_Start => registerWrite.rs485TxStart(i)
		);
		
		rs485DataTristate(i) <= not(txBusy(i));
		rs485DataEnable(i) <= txBusy(i);
	end generate;

	g2: if(numberOfUarts < 8) generate
		rs485DataTristate(7 downto numberOfUarts) <= (others=>'1');
		rs485DataEnable(7 downto numberOfUarts) <= (others=>'0');
	end generate;

	P1:process (registerWrite.clock)
	begin
		if rising_edge(registerWrite.clock) then
			if (registerWrite.reset = '1') then
				nP24VOnTristate <= (others=>'1');
			else
				q:for i in 0 to registerWrite.powerOn'length-1 loop
					if(registerWrite.powerOn(i) = '1') then
						nP24VOnTristate(i) <= '0';
					else
						nP24VOnTristate(i) <= '1';
					end if;
				end loop;

				-- rs485 fifo goes here...

			end if;
		end if;
	end process P1;

end Behavioral;

