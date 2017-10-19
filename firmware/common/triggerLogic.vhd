----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    20:09:33 03/08/2017 
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

entity triggerLogic is
generic(
--	serdesFactor : integer := 8;
	numberOfChannels : integer := 8
	);
port(
	triggerPixelIn : in std_logic_vector(8*numberOfChannels-1 downto 0);
	--triggerOutNoDelay : out std_logic; -- serdesDivClock clock domain...
	--triggerSerdesDelayed : out std_logic_vector(7 downto 0);
	trigger : out triggerLogic_t;
	registerRead : out triggerLogic_registerRead_t;
	registerWrite : in triggerLogic_registerWrite_t	
	);
end triggerLogic;

architecture Behavioral of triggerLogic is
	
	signal triggerSerdesNotDelayed : std_logic_vector(7 downto 0) := (others=>'0');
	signal triggerSerdesDelayed : std_logic_vector(7 downto 0) := (others=>'0');
	--variable triggerOutSerdes_v : std_logic_vector(7 downto 0) := (others=>'0');
	signal triggerMasked : data8x8Bit_t := (others=>(others=>'0'));
	
	signal fifoClear : std_logic := '0';
	signal fifoWrite : std_logic := '0';
	signal fifoRead : std_logic := '0';
	type stateDelay_t is (init1, init2, run);
	signal stateDelay : stateDelay_t := init1;
	signal delayCounter : integer range 0 to 2047 := 0;
	
	signal registerSoftTrigger_old : std_logic := '0';
	signal softTrigger : std_logic := '0';
	signal triggerDisabled : std_logic := '0';
	signal singleSeq_old : std_logic := '0';
	signal triggerNotDelayed : std_logic := '0';
	signal triggerDelayed : std_logic := '0';
	
	signal triggerGeneratorCounter : unsigned(31 downto 0) := (others=>'0');
	signal triggerGeneratorTrigger : std_logic := '0';

begin

	registerRead.triggerSerdesDelay <= registerWrite.triggerSerdesDelay;
	registerRead.triggerMask <= registerWrite.triggerMask;
	registerRead.triggerGeneratorEnabled <= registerWrite.triggerGeneratorEnabled;
	registerRead.triggerGeneratorPeriod <= registerWrite.triggerGeneratorPeriod;

	registerRead.trigger.triggerNotDelayed <= triggerNotDelayed;
	registerRead.trigger.triggerDelayed <= triggerDelayed;
	registerRead.trigger.triggerSerdesNotDelayed <= triggerSerdesNotDelayed;
	registerRead.trigger.triggerSerdesDelayed <= triggerSerdesDelayed;
	
	trigger.triggerNotDelayed <= triggerNotDelayed;
	trigger.triggerDelayed <= triggerDelayed;
	trigger.triggerSerdesNotDelayed <= triggerSerdesNotDelayed;
	trigger.triggerSerdesDelayed <= triggerSerdesDelayed;
	trigger.softTrigger <= softTrigger or triggerGeneratorTrigger;
	--triggerNotDelayed <= '1' when (((triggerPixelIn /= (triggerPixelIn'range => '0')) or (softTrigger = '1')) and (triggerDisabled = '0')) else '0';
	triggerNotDelayed <= '1' when (triggerSerdesNotDelayed /= x"00") else '0';
	triggerDelayed <= '1' when (triggerSerdesDelayed /= x"00") else '0';

	g0: for i in 0 to numberOfChannels-1 generate
		triggerMasked(i) <= triggerPixelIn(8*i+7 downto 8*i+0) when ((registerWrite.triggerMask(i) = '0') and (triggerDisabled = '0')) else x"00";
	end generate;
		
	--triggerSerdesNotDelayed <= triggerPixelIn(7 downto 0) or triggerPixelIn(15 downto 8) or triggerPixelIn(23 downto 16) or triggerPixelIn(31 downto 24) or triggerPixelIn(39 downto 32) or triggerPixelIn(47 downto 40) or triggerPixelIn(55 downto 48) or triggerPixelIn(63 downto 56);
	triggerSerdesNotDelayed <= triggerMasked(0) or triggerMasked(1) or triggerMasked(2) or triggerMasked(3) or triggerMasked(4) or triggerMasked(5) or triggerMasked(6) or triggerMasked(7);
	
	e0: entity work.triggerLogicDelayFifo port map(registerWrite.clock, fifoClear, triggerSerdesNotDelayed, fifoWrite, fifoRead, triggerSerdesDelayed, open, open);

	
	P0:process (registerWrite.clock)
	begin
		if rising_edge(registerWrite.clock) then
			fifoClear <= '0'; -- autoreset	
			fifoWrite <= '1'; -- autoreset
			fifoRead <= '1'; -- autoreset
			softTrigger <= '0'; -- autoreset
			if (registerWrite.reset = '1') then
				fifoClear <= '1'; -- autoreset
				stateDelay <= init1;
				singleSeq_old <= '0';
				triggerDisabled <= '0';
			else
				singleSeq_old <= registerWrite.singleSeq;
				if((registerWrite.singleSeq = '1') and (singleSeq_old = '0')) then
					triggerDisabled <= '0';
					registerRead.singleSeq <= '1';
				end if;
				if((registerWrite.singleSeq = '1') and (triggerNotDelayed = '1')) then
					triggerDisabled <= '1';
					registerRead.singleSeq <= '0';
				end if;

				registerSoftTrigger_old <= registerWrite.softTrigger;
				if((registerSoftTrigger_old = '0') and (registerWrite.softTrigger = '1')) then
					softTrigger <= '1'; -- autoreset
				end if;

				case stateDelay is
					when init1 =>
						fifoClear <= '1'; -- autoreset
						fifoWrite <= '0'; -- autoreset
						fifoRead <= '0'; -- autoreset
						stateDelay <= init2;
						delayCounter <= 0;

					when init2 =>
						fifoRead <= '0'; -- autoreset
						delayCounter <= delayCounter + 1;
						if(delayCounter >= to_integer(unsigned(registerWrite.triggerSerdesDelay))) then
							stateDelay <= run;
						end if;
						
					when run =>
						if(registerWrite.triggerSerdesDelayInit = '1') then
							stateDelay <= init1;
						end if;

					when others => stateDelay <= init1;
				end case;
			end if;
		end if;
	end process P0;

	P1:process (registerWrite.clock)
	begin
		if rising_edge(registerWrite.clock) then
			triggerGeneratorTrigger <= '0'; -- autoreset
			if (registerWrite.reset = '1') then
				triggerGeneratorCounter <= (others=>'0');
			else
				if(registerWrite.triggerGeneratorEnabled = '1') then
					triggerGeneratorCounter <= triggerGeneratorCounter + 1;
					if(triggerGeneratorCounter >= unsigned(registerWrite.triggerGeneratorPeriod)) then
						triggerGeneratorCounter <= (others=>'0');
						triggerGeneratorTrigger <= '1'; -- autoreset
					end if;
				end if;
			end if;
		end if;
	end process P1;


end Behavioral;

