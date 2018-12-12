-------------------------------------------------------------------------------
-- Design Name : sync_reset_gen
-- File Name   : sync_reset_gen.vhd
-- Device      : Spartan 6, XC6SLX9-2TQG144C
-- Function    : generate synchronous resets after power on
-- Coder       : K.-H. Sulanke, DESY, 2018-11-13
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all ;

library unisim ;
use unisim.vcomponents.all ;

ENTITY sync_reset_gen IS
	PORT
	(
		clk         : in  STD_LOGIC; --  60 MHz, system clock
		com_clk     : in  STD_LOGIC; --  60 Mhz, communication clock
		reset       : OUT STD_LOGIC; --  communication reset, synchronous to clk
		com_reset   : OUT STD_LOGIC  --  synchronous to com_clk
	);
END sync_reset_gen;

Architecture sync_reset_gen_arch of sync_reset_gen is

	--  signal pll_locked    : std_logic;    -- active high pll lock signal
	signal pll_reset_ct  : std_logic_vector(3 downto 0) := X"0"; 
	signal reset_ct      : std_logic_vector(3 downto 0) := X"0";  -- synchronous to clk
																  --  signal reset_nd      : std_logic;    -- 
																  --  signal com_reset_nd  : std_logic;    --
	signal com_reset_ct  : std_logic_vector(3 downto 0) := X"0";  -- synchronous to com_clk

begin

	SYNC_SYS_RESET: process (clk)
	begin                           -- do power on reset, just once !
		if rising_edge(clk) then   
			--if (pll_locked ='1') then
			if reset_ct /= B"1111" then
				reset_ct <= reset_ct + '1';
			end if;
			if (reset_ct = B"1110") then
				reset <= '1';
			else
				reset <= '0';
			end if;
		---end if; -- (pll_locked ='1') 
		end if; -- rising_edge(clk)
	end process SYNC_SYS_RESET;      


	SYNC_COM_RESET: process (com_clk)
	begin                           -- do power on reset, just once !
		if rising_edge(com_clk) then   
			--if (pll_locked ='1') then
			if com_reset_ct /= B"1111" then
				com_reset_ct <= com_reset_ct + '1';
			end if;
			if (com_reset_ct = B"1110") then
				com_reset <= '1';
			else
				com_reset <= '0';
			end if;
		--end if; -- (pll_locked ='1') 
		end if; -- rising_edge(com_clk)
	end process SYNC_COM_RESET;      

--  reset      <= reset_nd;
--  com_reset  <= com_reset_nd;


END sync_reset_gen_arch;
