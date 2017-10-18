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
use IEEE.NUMERIC_STD.ALL;
use work.types.all;

library UNISIM;
use UNISIM.VComponents.all;

entity clockConfig is
	port(
		clockPin : in std_logic;
		asyncReset : in std_logic;
		reset : out std_logic;
		triggerSerdesClocks : out triggerSerdesClocks_t;
		drs4Clocks : out drs4Clocks_t;
		adcClocks : out adcClocks_t;
		clockValid : out std_logic;
		debug : in clockConfig_debug_t
--		locked : out std_logic_vector(3 downto 0)
	);
end clockConfig;

architecture Behavioral of clockConfig is

	signal clockBufio2ToDcm : std_logic := '0';
	signal clockDcm1ToPll : std_logic := '0';
	signal dcm1Locked : std_logic := '0';
	signal dcm1Status : std_logic_vector(7 downto 0) := x"00";
	signal dcm1Clock0 : std_logic := '0';
	signal dcm1Reset : std_logic := '0';
	signal pllFeedBack1 : std_logic := '0';
	--signal pllReset1 : std_logic := '0';
	signal pllLocked1 : std_logic := '0';
	signal discriminatorSerdesFastClock : std_logic := '0';
	signal discriminatorSerdesSlowClock : std_logic := '0';
	signal discriminatorSerdesSlowClockGlobal : std_logic := '0';
	signal clockDcm3ToPll : std_logic := '0';
	signal dcm3Locked : std_logic := '0';
	signal dcm3Status : std_logic_vector(7 downto 0) := x"00";
	signal dcm3Clock0 : std_logic := '0';
	signal dcm3Reset : std_logic := '0';
	signal pllFeedBack3 : std_logic := '0';
	--signal pllReset3 : std_logic := '0';
	signal pllLocked3 : std_logic := '0';
	signal adcSerdesFastClock : std_logic := '0';
	signal adcSerdesSlowClock : std_logic := '0';
	signal adcSerdesSlowClockPhase : std_logic := '0';
	signal adcSerdesSlowClockGlobal : std_logic := '0';
	
	signal bufpllLocked1 : std_logic := '0';
	signal bufpllLocked3 : std_logic := '0';
--	signal serdesStrobe_i : std_logic := '0';
	signal reset_i : std_logic_vector(7 downto 0) := x"00";
	signal error : std_logic := '1';
	
--	signal pllFeedBack2 : std_logic := '0';
--	signal pllReset2 : std_logic := '0';
--	signal pllLocked2 : std_logic := '0';
	
	signal dcm2Locked : std_logic := '0';
	signal dcm2Status : std_logic_vector(7 downto 0) := x"00";
	signal dcm2Clock0 : std_logic := '0';
	--signal dcm2Reset : std_logic := '0';
	signal dcm2FxClock : std_logic := '0';

	--signal refClockCounter : integer range 0 to 255 := 0;
	signal refClockCounter : unsigned(7 downto 0) := x"00";
	signal refClock : std_logic := '0';

	signal debugSync1 : clockConfig_debug_t;
	signal debugSync2 : clockConfig_debug_t;
	
begin

	--drs4Clocks <= (others=>'0');
	drs4Clocks.drs4Clock_125MHz <= dcm2FxClock;
	drs4Clocks.drs4RefClock <= refClock;
	--drs4Clocks.adcSerdesDivClockPhase <= adcSerdesSlowClockGlobal;
	drs4Clocks.adcSerdesDivClockPhase <= adcSerdesSlowClockPhase;
	
--	locked <= error;
--	locked <= dcm1Locked & bufpllLocked1_1 & bufpllLocked1_2 & pllLocked1;
	clockValid <= dcm1Locked and bufpllLocked1 and pllLocked1;

	BUFIO2_inst : BUFIO2
	generic map(
		DIVIDE => 1,         	-- The DIVCLK divider divide-by value
		DIVIDE_BYPASS => TRUE  	-- DIVCLK output sourced from Divider (FALSE) or from I input, by-passing Divider (TRUE); default TRUE
	)
   port map (
      I => clockPin,				-- from GCLK input pin
      IOCLK => open,				-- Output Clock to IO
      DIVCLK => clockBufio2ToDcm,	-- to PLL/DCM
      SERDESSTROBE => open			-- Output strobe for IOSERDES2
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
      CLK0 => dcm1Clock0,			-- 1-bit output: 0 degree clock output
      CLK180 => open,     			-- 1-bit output: 180 degree clock output
      CLK270 => open,     			-- 1-bit output: 270 degree clock output
      CLK2X => open,       		-- 1-bit output: 2X clock frequency clock output
      CLK2X180 => open, 			-- 1-bit output: 2X clock frequency, 180 degree clock output
      CLK90 => open,       		-- 1-bit output: 90 degree clock output
      CLKDV => open,      			-- 1-bit output: Divided clock output
      CLKFX => clockDcm1ToPll,   	-- 1-bit output: Digital Frequency Synthesizer output (DFS)
      CLKFX180 => open, 			-- 1-bit output: 180 degree CLKFX output
      LOCKED => dcm1Locked,   		-- 1-bit output: DCM_SP Lock Output
      PSDONE => open,     			-- 1-bit output: Phase shift done output
      STATUS => dcm1Status,	   	-- 8-bit output: DCM_SP status output
      CLKFB => dcm1Clock0,   		-- 1-bit input: Clock feedback input
      CLKIN => clockBufio2ToDcm,	-- 1-bit input: Clock input
      DSSEN => '0',       			-- 1-bit input: Unsupported, specify to GND.
      PSCLK => '0',       			-- 1-bit input: Phase shift clock input
      PSEN => '0',         		-- 1-bit input: Phase shift enable
      PSINCDEC => '0', 				-- 1-bit input: Phase shift increment/decrement input
      RST => dcm1Reset        		-- 1-bit input: Active high reset input
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
        CLKFBOUT            => pllFeedBack1,
        CLKOUT0             => discriminatorSerdesFastClock,
        CLKOUT1             => open,
        CLKOUT2             => discriminatorSerdesSlowClock,
        CLKOUT3             => open,
        CLKOUT4             => open,
        CLKOUT5             => open,
        LOCKED              => pllLocked1,
        RST                 => '0', --pllReset1,
        CLKFBIN             => pllFeedBack1,
        CLKIN               => clockDcm1ToPll
    );

	bufg_inst1: BUFG port map (I => discriminatorSerdesSlowClock, O => discriminatorSerdesSlowClockGlobal);
	
	bufpll_inst1 : BUFPLL
	generic map (
		DIVIDE => 8
	)
	port map (
      PLLIN				=> discriminatorSerdesFastClock,			-- PLL Clock input
      GCLK				=> discriminatorSerdesSlowClockGlobal, 	-- Global Clock input
      LOCKED			=> pllLocked1,					-- Clock0 locked input
      IOCLK				=> triggerSerdesClocks.serdesIoClock, 			-- Output PLL Clock
      LOCK				=> bufpllLocked1,        	-- BUFPLL Clock and strobe locked
      serdesstrobe		=> triggerSerdesClocks.serdesStrobe	 	-- Output SERDES strobe
	);
	
	triggerSerdesClocks.serdesDivClock <= discriminatorSerdesSlowClockGlobal;
	dcm1Reset <= ((not(dcm1Locked) and  dcm1Status(2)) or asyncReset);
	
--	p1: process(clockDcm1ToPll)
--		variable dcmResetCounter : integer range 0 to 65535 := 0; -- time to lock is 5 ms max. !!!
--	begin
--		if(rising_edge(dcm1Clock0)) then
--			if(((dcm1Status(2 downto 1) /= "00") or (dcm1Locked = '0')) and (dcmResetCounter = 0)) then
--				dcmResetCounter := 65535;
--				dcm1Reset <= '1'; -- active for 3 clock cycles min.
--         elsif(dcmResetCounter /= 0) then  
--				dcmResetCounter := dcmResetCounter - 1;
--				if(dcmResetCounter = 65525) then 
--					dcm1Reset <= '0';
--				end if;  
--			end if;
--		end if;
--	end process;
	
	error <= '1' when ((dcm1Locked = '0') or (dcm2Locked = '0') or (dcm3Locked = '0') or (bufpllLocked1 = '0') or (pllLocked1 = '0') or (bufpllLocked3 = '0') or (pllLocked3 = '0')) else '0';
--	error <= '1' when ((dcm1Locked = '0') or (bufpllLocked1 = '0') or (bufpllLocked2 = '0') or (pllLocked1 = '0') or (pllLocked2 = '0')) else '0';
	reset <= reset_i(reset_i'length-1);
	
	p2: process(discriminatorSerdesSlowClockGlobal, error)
	begin
		if(rising_edge(clockDcm1ToPll)) then
			reset_i <= reset_i(reset_i'length-2 downto 0) & '0';
		end if;
		if(error = '1') then
			reset_i(reset_i'length-2 downto 0) <= (others => '1');
		end if;
	end process;
	
-------------------------------------------------------------------------------

DCM_SP_inst3 : DCM_SP
    generic map (
      CLKDV_DIVIDE => 2.0,                   -- CLKDV divide value (1.5,2,2.5,3,3.5,4,4.5,5,5.5,6,6.5,7,7.5,8,9,10,11,12,13,14,15,16).
      CLKFX_DIVIDE => 1,                     -- Divide value on CLKFX outputs - D - (1-32)
      CLKFX_MULTIPLY => 3,                   -- Multiply value on CLKFX outputs - M - (2-32)
      CLKIN_DIVIDE_BY_2 => FALSE,            -- CLKIN divide by two (TRUE/FALSE)
      CLKIN_PERIOD => 100.0,						-- Input clock period specified in nS
      CLKOUT_PHASE_SHIFT => "NONE",          -- Output phase shift (NONE, FIXED, VARIABLE)
      CLK_FEEDBACK => "1X",                  -- Feedback source (NONE, 1X, 2X)
      DESKEW_ADJUST => "SOURCE_SYNCHRONOUS", -- SYSTEM_SYNCHRNOUS or SOURCE_SYNCHRONOUS
      PHASE_SHIFT => 0,                      -- Amount of fixed phase shift (-255 to 255)
      STARTUP_WAIT => FALSE                  -- Delay config DONE until DCM_SP LOCKED (TRUE/FALSE)
   )
   port map (
      CLK0 => dcm3Clock0,			-- 1-bit output: 0 degree clock output
      CLK180 => open,     			-- 1-bit output: 180 degree clock output
      CLK270 => open,     			-- 1-bit output: 270 degree clock output
      CLK2X => open,       		-- 1-bit output: 2X clock frequency clock output
      CLK2X180 => open, 			-- 1-bit output: 2X clock frequency, 180 degree clock output
      CLK90 => open,       		-- 1-bit output: 90 degree clock output
      CLKDV => open,      			-- 1-bit output: Divided clock output
      CLKFX => clockDcm3ToPll,   	-- 1-bit output: Digital Frequency Synthesizer output (DFS)
      CLKFX180 => open, 			-- 1-bit output: 180 degree CLKFX output
      LOCKED => dcm3Locked,   		-- 1-bit output: DCM_SP Lock Output
      PSDONE => open,     			-- 1-bit output: Phase shift done output
      STATUS => dcm3Status,	   	-- 8-bit output: DCM_SP status output
      CLKFB => dcm3Clock0,   		-- 1-bit input: Clock feedback input
      CLKIN => clockBufio2ToDcm,	-- 1-bit input: Clock input
      DSSEN => '0',       			-- 1-bit input: Unsupported, specify to GND.
      PSCLK => '0',       			-- 1-bit input: Phase shift clock input
      PSEN => '0',         		-- 1-bit input: Phase shift enable
      PSINCDEC => '0', 				-- 1-bit input: Phase shift increment/decrement input
      RST => dcm3Reset        		-- 1-bit input: Active high reset input
   );

	pll_base_inst3 : PLL_BASE
	generic map (
        BANDWIDTH            => "OPTIMIZED",
        CLK_FEEDBACK         => "CLKFBOUT",
        COMPENSATION         => "DCM2PLL",
        CLKIN_PERIOD         => 33.333,
        REF_JITTER           => 0.100,
        DIVCLK_DIVIDE        => 1,
        CLKFBOUT_MULT        => 14,
        CLKFBOUT_PHASE       => 0.000,
        CLKOUT0_DIVIDE       => 1,
        CLKOUT0_PHASE        => 0.000,
        CLKOUT0_DUTY_CYCLE   => 0.500,
        CLKOUT1_DIVIDE       => 1,
        CLKOUT1_PHASE        => 0.000,
        CLKOUT1_DUTY_CYCLE   => 0.500,
        CLKOUT2_DIVIDE       => 7,
        CLKOUT2_PHASE        => 0.000,
        CLKOUT2_DUTY_CYCLE   => 0.500,
        CLKOUT3_DIVIDE       => 7,
        CLKOUT3_PHASE        => 0.000, --
        CLKOUT3_DUTY_CYCLE   => 0.500,
        CLKOUT4_DIVIDE       => 1,
        CLKOUT4_PHASE        => 0.000,
        CLKOUT4_DUTY_CYCLE   => 0.500,
        CLKOUT5_DIVIDE       => 1,
        CLKOUT5_PHASE        => 0.000,
        CLKOUT5_DUTY_CYCLE   => 0.500
    )
    port map (
        CLKFBOUT            => pllFeedBack3,
        CLKOUT0             => adcSerdesFastClock,
        CLKOUT1             => open,
        CLKOUT2             => adcSerdesSlowClock,
        CLKOUT3             => adcSerdesSlowClockPhase,
        CLKOUT4             => open,
        CLKOUT5             => open,
        LOCKED              => pllLocked3,
        RST                 => '0', --pllReset3,
        CLKFBIN             => pllFeedBack3,
        CLKIN               => clockDcm3ToPll
    );

	bufg_inst3: BUFG port map (I => adcSerdesSlowClock, O => adcSerdesSlowClockGlobal);
	
	bufpll_inst3 : BUFPLL
	generic map (
		DIVIDE => 7
	)
	port map (
      PLLIN				=> adcSerdesFastClock,			-- PLL Clock input
      GCLK				=> adcSerdesSlowClockGlobal, 	-- Global Clock input
      LOCKED			=> pllLocked3,					-- Clock0 locked input
      IOCLK				=> adcClocks.serdesIoClock,		-- Output PLL Clock
      LOCK				=> bufpllLocked3,        		-- BUFPLL Clock and strobe locked
      serdesstrobe		=> adcClocks.serdesStrobe	 	-- Output SERDES strobe
	);
	
	adcClocks.serdesDivClock <= adcSerdesSlowClockGlobal;
	adcClocks.serdesDivClockPhase <= adcSerdesSlowClockPhase;
	dcm3Reset <= ((not(dcm3Locked) and  dcm3Status(2)) or asyncReset);

-------------------------------------------------------------------------------

	DCM_SP_inst_2 : DCM_SP
   generic map (
      CLKDV_DIVIDE => 2.0,                   -- CLKDV divide value (1.5,2,2.5,3,3.5,4,4.5,5,5.5,6,6.5,7,7.5,8,9,10,11,12,13,14,15,16).
      CLKFX_DIVIDE => 2,                     -- Divide value on CLKFX outputs - D - (1-32)
      CLKFX_MULTIPLY => 25,                   -- Multiply value on CLKFX outputs - M - (2-32)
      CLKIN_DIVIDE_BY_2 => FALSE,            -- CLKIN divide by two (TRUE/FALSE)
      CLKIN_PERIOD => 100.0,						-- Input clock period specified in nS
      CLKOUT_PHASE_SHIFT => "NONE",          -- Output phase shift (NONE, FIXED, VARIABLE)
      CLK_FEEDBACK => "1X",                  -- Feedback source (NONE, 1X, 2X)
      DESKEW_ADJUST => "SOURCE_SYNCHRONOUS", -- SYSTEM_SYNCHRNOUS or SOURCE_SYNCHRONOUS
      PHASE_SHIFT => 0,                      -- Amount of fixed phase shift (-255 to 255)
      STARTUP_WAIT => FALSE                  -- Delay config DONE until DCM_SP LOCKED (TRUE/FALSE)
   )
   port map (
      CLK0 => dcm2Clock0,			-- 1-bit output: 0 degree clock output
      CLK180 => open,     			-- 1-bit output: 180 degree clock output
      CLK270 => open,     			-- 1-bit output: 270 degree clock output
      CLK2X => open,       		-- 1-bit output: 2X clock frequency clock output
      CLK2X180 => open, 			-- 1-bit output: 2X clock frequency, 180 degree clock output
      CLK90 => open,       		-- 1-bit output: 90 degree clock output
      CLKDV => open,      			-- 1-bit output: Divided clock output
      CLKFX => dcm2FxClock,   	-- 1-bit output: Digital Frequency Synthesizer output (DFS)
      CLKFX180 => open, 			-- 1-bit output: 180 degree CLKFX output
      LOCKED => dcm2Locked,   		-- 1-bit output: DCM_SP Lock Output
      PSDONE => open,     			-- 1-bit output: Phase shift done output
      STATUS => dcm2Status,	   	-- 8-bit output: DCM_SP status output
      CLKFB => dcm2Clock0,   		-- 1-bit input: Clock feedback input
      CLKIN => clockBufio2ToDcm,	-- 1-bit input: Clock input
      DSSEN => '0',       			-- 1-bit input: Unsupported, specify to GND.
      PSCLK => '0',       			-- 1-bit input: Phase shift clock input
      PSEN => '0',         		-- 1-bit input: Phase shift enable
      PSINCDEC => '0', 				-- 1-bit input: Phase shift increment/decrement input
      RST => '0' --dcm2Reset        		-- 1-bit input: Active high reset input
   );

   	p3: process(dcm2FxClock)
	begin
		if(rising_edge(dcm2FxClock)) then
			debugSync1 <= debug;
			debugSync2 <= debugSync1;
			if(error = '0') then
				refClockCounter <= refClockCounter + 1;
				--if(refClockCounter >= 127) then
				if(refClockCounter >= unsigned(debugSync2.drs4RefClockPeriod)) then
					refClockCounter <= x"00";
					refClock <= not(refClock); -- from 125MHz: refClock will be 488.28125 kHz to get 1.000GS 	
				end if;
			else
				refClockCounter <= x"00";
				refClock <= '0';
			end if;
		end if;
	end process;

end Behavioral;
