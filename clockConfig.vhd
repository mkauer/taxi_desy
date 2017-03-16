----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:51:16 03/07/2017 
-- Design Name: 
-- Module Name:    iSerdesPll - Behavioral 
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

library UNISIM;
use UNISIM.VComponents.all;

entity clockConfig is
	port(
		clockPin : in std_logic;
		asyncReset : in std_logic;
		reset : out std_logic;
		serdesDivClock : out std_logic;
		serdesIoClock_1 : out std_logic;
		serdesStrobeBufpll_1 : out std_logic;
		serdesIoClock_2 : out std_logic;
		serdesStrobeBufpll_2 : out std_logic;
		clockValid : out std_logic
--		locked : out std_logic_vector(3 downto 0)
	);
end clockConfig;

architecture Behavioral of clockConfig is

	signal clockBufio2ToDcm : std_logic := '0';
	signal clockDcmToPll : std_logic := '0';
	signal dcmLocked : std_logic := '0';
	signal dcmStatus : std_logic_vector(7 downto 0) := x"00";
	signal dcmClock0 : std_logic := '0';
	signal dcmReset : std_logic := '0';
	signal pllFeedBack : std_logic := '0';
	signal pllReset : std_logic := '0';
	signal pllLocked : std_logic := '0';
	signal serdesFastClock : std_logic := '0';
	signal serdesSlowClock : std_logic := '0';
	signal serdesSlowClockGlobal : std_logic := '0';
	--signal serdesIoClock_1 : std_logic := '0';
	--signal serdesIoClock_2 : std_logic := '0';
	signal bufpllLocked_1 : std_logic := '0';
	signal bufpllLocked_2 : std_logic := '0';
--	signal serdesStrobe_i : std_logic := '0';
	signal reset_i : std_logic_vector(7 downto 0) := x"00";
	signal error : std_logic := '1';
	
begin

	--serdesIoClock <= serdesIoClock_i;
	serdesDivClock <= serdesSlowClockGlobal;
	--serdesStrobe <= serdesStrobe_i;
	
--	locked <= error;
--	locked <= dcmLocked & bufpllLocked_1 & bufpllLocked_2 & pllLocked;
	clockValid <= dcmLocked and bufpllLocked_1 and bufpllLocked_2 and pllLocked;

	BUFIO2_inst : BUFIO2
	generic map(
		DIVIDE => 1,         			-- The DIVCLK divider divide-by value
		DIVIDE_BYPASS => TRUE    		-- DIVCLK output sourced from Divider (FALSE) or from I input, by-passing Divider (TRUE); default TRUE
	)
   port map (
      I => clockPin,						-- from GCLK input pin
      IOCLK => open,						-- Output Clock to IO
      DIVCLK => clockBufio2ToDcm,	-- to PLL/DCM
      SERDESSTROBE => open				-- Output strobe for IOSERDES2
	);

	DCM_SP_inst : DCM_SP
   generic map (
      CLKDV_DIVIDE => 2.0,                   -- CLKDV divide value (1.5,2,2.5,3,3.5,4,4.5,5,5.5,6,6.5,7,7.5,8,9,10,11,12,13,14,15,16).
      CLKFX_DIVIDE => 2,                     -- Divide value on CLKFX outputs - D - (1-32)
      CLKFX_MULTIPLY => 5,                   -- Multiply value on CLKFX outputs - M - (2-32)
      CLKIN_DIVIDE_BY_2 => FALSE,            -- CLKIN divide by two (TRUE/FALSE)
      CLKIN_PERIOD => 100.0,						-- Input clock period specified in nS
      CLKOUT_PHASE_SHIFT => "NONE",          -- Output phase shift (NONE, FIXED, VARIABLE)
      CLK_FEEDBACK => "1X",                  -- Feedback source (NONE, 1X, 2X)
      DESKEW_ADJUST => "SOURCE_SYNCHRONOUS", -- SYSTEM_SYNCHRNOUS or SOURCE_SYNCHRONOUS
      PHASE_SHIFT => 0,                      -- Amount of fixed phase shift (-255 to 255)
      STARTUP_WAIT => FALSE                  -- Delay config DONE until DCM_SP LOCKED (TRUE/FALSE)
   )
   port map (
      CLK0 => dcmClock0,			-- 1-bit output: 0 degree clock output
      CLK180 => open,     			-- 1-bit output: 180 degree clock output
      CLK270 => open,     			-- 1-bit output: 270 degree clock output
      CLK2X => open,       		-- 1-bit output: 2X clock frequency clock output
      CLK2X180 => open, 			-- 1-bit output: 2X clock frequency, 180 degree clock output
      CLK90 => open,       		-- 1-bit output: 90 degree clock output
      CLKDV => open,      			-- 1-bit output: Divided clock output
      CLKFX => clockDcmToPll,   	-- 1-bit output: Digital Frequency Synthesizer output (DFS)
      CLKFX180 => open, 			-- 1-bit output: 180 degree CLKFX output
      LOCKED => dcmLocked,   		-- 1-bit output: DCM_SP Lock Output
      PSDONE => open,     			-- 1-bit output: Phase shift done output
      STATUS => dcmStatus,	   	-- 8-bit output: DCM_SP status output
      CLKFB => dcmClock0,   		-- 1-bit input: Clock feedback input
      CLKIN => clockBufio2ToDcm,	-- 1-bit input: Clock input
      DSSEN => '0',       			-- 1-bit input: Unsupported, specify to GND.
      PSCLK => '0',       			-- 1-bit input: Phase shift clock input
      PSEN => '0',         		-- 1-bit input: Phase shift enable
      PSINCDEC => '0', 				-- 1-bit input: Phase shift increment/decrement input
      RST => dcmReset        		-- 1-bit input: Active high reset input
   );

	pll_base_inst : PLL_BASE
	generic map (
        BANDWIDTH            => "OPTIMIZED",
        CLK_FEEDBACK         => "CLKFBOUT",
        COMPENSATION         => "DCM2PLL",
		  CLKIN_PERIOD         => 40.000,
        REF_JITTER           => 0.100,
        DIVCLK_DIVIDE        => 1,
        CLKFBOUT_MULT        => 38,
        CLKFBOUT_PHASE       => 0.000,
        CLKOUT0_DIVIDE       => 1,
        CLKOUT0_PHASE        => 0.000,
        CLKOUT0_DUTY_CYCLE   => 0.500,
        CLKOUT1_DIVIDE       => 1,
        CLKOUT1_PHASE        => 0.000,
        CLKOUT1_DUTY_CYCLE   => 0.500,
        CLKOUT2_DIVIDE       => 8,
        CLKOUT2_PHASE        => 0.000,
        CLKOUT2_DUTY_CYCLE   => 0.500,
        CLKOUT3_DIVIDE       => 1,
        CLKOUT3_PHASE        => 0.000,
        CLKOUT3_DUTY_CYCLE   => 0.500,
		  CLKOUT4_DIVIDE       => 1,
        CLKOUT4_PHASE        => 0.000,
        CLKOUT4_DUTY_CYCLE   => 0.500,
		  CLKOUT5_DIVIDE       => 1,
        CLKOUT5_PHASE        => 0.000,
        CLKOUT5_DUTY_CYCLE   => 0.500
    )
    port map (
        CLKFBOUT            => pllFeedBack,
        CLKOUT0             => serdesFastClock,
        CLKOUT1             => open,
        CLKOUT2             => serdesSlowClock,
        CLKOUT3             => open,
        CLKOUT4             => open,
        CLKOUT5             => open,
        LOCKED              => pllLocked,
        RST                 => pllReset,
        CLKFBIN             => pllFeedBack,
        CLKIN               => clockDcmToPll
    );

	bufg_inst: BUFG port map (I => serdesSlowClock, O => serdesSlowClockGlobal);
	
	bufpll_inst1 : BUFPLL
	generic map (
		DIVIDE => 8
	)
	port map (
      PLLIN				=> serdesFastClock,			-- PLL Clock input
      GCLK				=> serdesSlowClockGlobal, 	-- Global Clock input
      LOCKED			=> pllLocked,					-- Clock0 locked input
      IOCLK				=> serdesIoClock_1, 			-- Output PLL Clock
      LOCK				=> bufpllLocked_1,        	-- BUFPLL Clock and strobe locked
      serdesstrobe	=> serdesStrobeBufpll_1	 	-- Output SERDES strobe
	);
	
	bufpll_inst2 : BUFPLL
	generic map (
		DIVIDE => 8
	)
	port map (
      PLLIN				=> serdesFastClock,			-- PLL Clock input
      GCLK				=> serdesSlowClockGlobal, 	-- Global Clock input
      LOCKED			=> pllLocked,					-- Clock0 locked input
      IOCLK				=> serdesIoClock_2, 			-- Output PLL Clock
      LOCK				=> bufpllLocked_2,        	-- BUFPLL Clock and strobe locked
      serdesstrobe	=> serdesStrobeBufpll_2	 	-- Output SERDES strobe
	);
	
	dcmReset <= ((not(dcmLocked) and  dcmStatus(2)) or asyncReset);
	
--	p1: process(clockDcmToPll)
--		variable dcmResetCounter : integer range 0 to 65535 := 0; -- time to lock is 5 ms max. !!!
--	begin
--		if(rising_edge(dcmClock0)) then
--			if(((dcmStatus(2 downto 1) /= "00") or (dcmLocked = '0')) and (dcmResetCounter = 0)) then
--				dcmResetCounter := 65535;
--				dcmReset <= '1'; -- active for 3 clock cycles min.
--         elsif(dcmResetCounter /= 0) then  
--				dcmResetCounter := dcmResetCounter - 1;
--				if(dcmResetCounter = 65525) then 
--					dcmReset <= '0';
--				end if;  
--			end if;
--		end if;
--	end process;
	
	error <= '1' when ((dcmLocked = '0') or (bufpllLocked_1 = '0') or (bufpllLocked_2 = '0') or (pllLocked = '0')) else '0';
	reset <= reset_i(reset_i'length-1);
	
	p2: process(serdesSlowClockGlobal, error)
	begin
		if(rising_edge(clockDcmToPll)) then
			reset_i <= reset_i(reset_i'length-2 downto 0) & '0';
		end if;
		if(error = '1') then
			reset_i(reset_i'length-2 downto 0) <= (others => '1');
		end if;
	end process;

end Behavioral;