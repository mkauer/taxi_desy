library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.types.all;

entity rs485Interface is
	generic
	(
		numberOfUarts : integer := 8
	);
    port
	(
		rxPin : in std_logic_vector(numberOfUarts-1 downto 0);
      	txPin : out std_logic_vector(numberOfUarts-1 downto 0);
	    registerWrite : in rs485_registerWrite_t;
    	registerRead : out rs485_registerRead_t	
     );
end rs485Interface;

architecture Behavioral of rs485Interface is
	signal int_rxd : std_logic_vector(numberOfUarts-1 downto 0);
begin

	g0: for i in 0 to numberOfUarts-1 generate
		int_rxd(i) <= rxPin(i) and not registerWrite.uarts(i).TX_EN;
	end generate;

	g1: for i in 0 to numberOfUarts-1 generate
		x0: entity work.uart_RxTx_V2
		generic map
		(
			Quarz_Taktfrequenz => 118750000,
			Baudrate => 9600
		)
		port map (
			CLK => registerWrite.uarts(i).CLK,
			RXD => int_rxd(i),
			RX_Fifo_Read_Strobe => registerWrite.uarts(i).RX_Fifo_Read_Strobe,
			RX_Fifo_Clear => registerWrite.uarts(i).RX_Fifo_Clear,
			RX_Fifo_Words => registerRead.uarts(i).RX_Fifo_Words,
			RX_Fifo_Full => registerRead.uarts(i).RX_Fifo_Full,
			
			RX_Data => registerRead.uarts(i).RX_Data,
			RX_Busy => registerRead.uarts(i).RX_Busy,
			TXD => txPin(i),
			TX_Data => registerWrite.uarts(i).TX_Data,
			TX_Start => registerWrite.uarts(i).TX_Start,
			TX_Busy => registerRead.uarts(i).TX_Busy			
		);
	end generate;

end Behavioral;
