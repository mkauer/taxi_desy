----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:59:02 03/27/2017 
-- Design Name: 
-- Module Name:    drs4 - Behavioral 
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

entity drs4 is
	port(
		notReset : out std_logic;
		address : out std_logic_vector(3 downto 0);
		
		denable : out std_logic;
		dwrite : out std_logic;
			
		rsrload : out std_logic;
		miso : in std_logic;
		mosi : out std_logic;
		srclk : out std_logic;
		
		dtap : in std_logic;
		plllck : in std_logic;
		
		--refclk : out std_logic;
		
		stopDrs4 : in std_logic;
		
		drs4Clocks : in drs4Clocks_t;
		
		registerRead : out drs4_registerRead_t;
		registerWrite : in drs4_registerWrite_t	
	);
end drs4;

architecture Behavioral of drs4 is
	constant spiNumberOfBits : integer := 8;
	constant sclkDivisor : unsigned(3 downto 0) := x"2"; -- ((systemClock / spiClock) / 2) ... 2=~29.7MHz@118.75MHz
	constant sclkDefaultLevel : std_logic := '0';
	constant mosiDefaultLevel : std_logic := '0';
	--constant mosiValidEdge : std_logic := '0'; -- '0'=rising, '1'=falling
	--constant mosiMsbinitState : std_logic := '1'; -- '0'=LsbinitState, '1'=MsbinitState

	type stateDrs4Spi_t is (idle, transfer1, transfer2, readRegionOfInterest, transferEnd);
	signal stateDrs4Spi : stateDrs4Spi_t := idle;

	signal txBuffer : std_logic_vector(spiNumberOfBits-1 downto 0);
	signal roiBuffer : std_logic_vector(9 downto 0) := (others=>'0');

	signal busy : std_logic := '0';
	signal spiTransfer : std_logic := '0';
	signal spiTransfer_old : std_logic := '0';
	signal spiCounter : integer range 0 to spiNumberOfBits := 0;
	signal sclkDivisorCounter : unsigned (3 downto 0) := x"0";
	signal sclk_i : std_logic := '0';
	signal sclkEnable : std_logic := '0';
	signal sclkEdgeRising : std_logic := '0';
	signal sclkEdgeFalling : std_logic := '0';
--	type readoutMode_t is (regionOfIntrest,fullReadout,configRegister);
--	signal readoutMode : readoutMode_t := regionOfIntrest;
	type spiTransferMode_t is (sample, transparentMode, standby, regionOfIntrest, fullReadout, readShiftRegister_write, writeShiftRegister_write, configRegister_write);
	signal spiTransferMode : spiTransferMode_t := sample;
	signal bitCounter : integer range 0 to 4095 := 0;--unsigned(15 downto 0) := x"0000";
	signal roiCounter : integer range 0 to 15 := 0;
	signal edgeCounter : integer range 0 to 3 := 0;
	signal spiDone : std_logic := '0';
	
	type state4_t is (init1, init2, init3, init4, init5, drs4start0, drs4start1, startSampling, sampling, readRoi);
	signal state4 : state4_t := init1;
	
--	signal readShiftRegister : std_logic_vector(7 downto 0);
	signal configRegister : std_logic_vector(2 downto 0) := "111";
	 alias configRegister_dmode_bit is configRegister(0);
	 alias configRegister_pllen_bit is configRegister(1);
	 alias configRegister_wsrloop_bit is configRegister(2);
	 --alias configRegister_reserved_bits is configRegister(7 downto 3); -- hast to be 1
	signal writeShiftRegister : std_logic_vector(7 downto 0) := "11111111"; -- 8x1024 samples
	signal writeConfigRegister : std_logic_vector(7 downto 0);
	
	constant address_enableAllOutputs : std_logic_vector(3 downto 0) := "1001";
	constant address_transparentMode : std_logic_vector(3 downto 0) := "1010";
	constant address_readShiftRegister : std_logic_vector(3 downto 0) := "1011";
	constant address_configRegister : std_logic_vector(3 downto 0) := "1100";
	constant address_writeShiftRegister : std_logic_vector(3 downto 0) := "1101";
	constant address_writeConfigRegister : std_logic_vector(3 downto 0) := "1110";
	constant address_stabdby : std_logic_vector(3 downto 0) := "1111";
	
	constant numberOfSamplesToRead : std_logic_vector(11 downto 0) := x"010";
	signal stopDrs4_old :std_logic := '0';
	signal counter1 : integer range 0 to 1023 := 0;
	
begin
	
	rsrload <= sclk_i when ((spiTransferMode = regionOfIntrest) and (edgeCounter < 2)) else sclkDefaultLevel;	
	srclk <= sclk_i when ((spiTransferMode = regionOfIntrest) and (edgeCounter >= 2)) else sclkDefaultLevel;

	P0:process (registerWrite.clock) --drs4Clocks.drs4SamplingClock) -- ~33MHz
	begin
		if rising_edge(registerWrite.clock) then --drs4Clocks.drs4SamplingClock) then
			sclkEdgeRising <= '0'; -- autoreset
			sclkEdgeFalling <= '0'; -- autoreset
			if (registerWrite.reset = '1') then
				sclkDivisorCounter <= to_unsigned(0, sclkDivisorCounter'length);
				sclk_i <= sclkDefaultLevel;
			else
				if (sclkEnable = '1') then
					if (sclkDivisorCounter = sclkDivisor) then
						sclkDivisorCounter <= to_unsigned(0, sclkDivisorCounter'length);
						
						if(edgeCounter /= 3) then
							edgeCounter <= edgeCounter + 1;
						end if;
						
						sclk_i <= not sclk_i;
						if ((sclk_i = '0')) then
							sclkEdgeRising <= '1'; -- autoreset
						end if;
						if ((sclk_i = '1')) then
							sclkEdgeFalling <= '1'; -- autoreset
						end if;
					else
						sclkDivisorCounter <= sclkDivisorCounter + 1;
					end if;
				else
					sclk_i <= sclkDefaultLevel;
					sclkDivisorCounter <= to_unsigned(0, sclkDivisorCounter'length);
					edgeCounter <= 0;
				end if;
			end if;
		end if;
	end process P0;
	
	P1:process (registerWrite.clock)
	begin
		if rising_edge(registerWrite.clock) then
			sclkEnable <= '0'; -- autoreset
			spiDone <= '0'; -- autoreset
			if (registerWrite.reset = '1') then				
				stateDrs4Spi <= idle;
				address <= address_stabdby;
			else
				spiTransfer_old <= spiTransfer;
				case stateDrs4Spi is	
					when idle =>
						if((spiTransfer_old = '0') and (spiTransfer = '1')) then
							if(spiTransferMode = readShiftRegister_write) then
								address <= address_readShiftRegister;
								stateDrs4Spi <= transfer1;
								bitCounter <= 1024;
								txBuffer <= "01000000";
							elsif(spiTransferMode = configRegister_write) then
								address <= address_configRegister;
								stateDrs4Spi <= transfer2;
								bitCounter <= 8;
								txBuffer <= "11111" & configRegister;
							elsif(spiTransferMode = writeShiftRegister_write) then
								address <= address_writeShiftRegister;
								stateDrs4Spi <= transfer2;
								bitCounter <= 8;
								txBuffer <= writeShiftRegister;
							elsif(spiTransferMode = standby) then
								address <= address_stabdby;
								spiDone <= '1'; -- autoreset
							elsif(spiTransferMode = transparentMode) then
								address <= address_transparentMode;
								spiDone <= '1'; -- autoreset
							elsif(spiTransferMode = regionOfIntrest) then
								address <= address_enableAllOutputs;
								stateDrs4Spi <= readRegionOfInterest;
								bitCounter <= to_integer(unsigned(numberOfSamplesToRead));
								roiCounter <= 0;
								txBuffer <= "00000000";
							end if;
						end if;
						
					when transfer1 =>
						sclkEnable <= '1'; -- autoreset
						busy <= '1'; -- autoreset
						if (sclkEdgeRising = '1') then
							if(bitCounter <= 1) then
								txBuffer <= txBuffer(txBuffer'length-2 downto 0) & mosiDefaultLevel;
							end if;
							bitCounter <= bitCounter - 1;
							if (bitCounter = 0) then
								stateDrs4Spi <= transferEnd;
							end if;
						end if;
						
					when transfer2 =>
						sclkEnable <= '1'; -- autoreset
						busy <= '1'; -- autoreset
						if (sclkEdgeRising = '1') then
							if(bitCounter /= 0) then
								txBuffer <= txBuffer(txBuffer'length-2 downto 0) & mosiDefaultLevel;
							end if;
							bitCounter <= bitCounter - 1;
						end if;
						if (bitCounter = 1) then
							stateDrs4Spi <= transferEnd;
						end if;
						
					when readRegionOfInterest =>
						sclkEnable <= '1'; -- autoreset
						busy <= '1'; -- autoreset
						if (sclkEdgeRising = '1') then
							if((roiCounter > 0) and (roiCounter < 9)) then
								roiBuffer <= roiBuffer(roiBuffer'length-2 downto 0) & miso;
							end if;
							
							if(roiCounter < 9) then
								roiCounter <= roiCounter + 1;
							end if;
							
							if(bitCounter > 0) then
								bitCounter <= bitCounter - 1;
							end if;
							
							if((bitCounter = 0) and (roiCounter = 9)) then
								stateDrs4Spi <= transferEnd;
							end if;
						end if;
										
					when transferEnd =>
						busy <= '1'; -- autoreset
						sclkEnable <= '1'; -- autoreset
						if (sclkEdgeRising = '1') then
							registerRead.regionOfInterest <= roiBuffer;
							stateDrs4Spi <= idle;
							txBuffer <= (others=>'0');
							spiDone <= '1'; -- autoreset
						end if;		
						
					when others => null;
				end case;
				
			end if;
		end if;
	end process P1;
	
	mosi <= txBuffer(txBuffer'length-1);
	
	P2:process (registerWrite.clock)
	begin
		if rising_edge(registerWrite.clock) then
			notReset <= '1'; -- autoreset
			spiTransfer <= '0'; -- autoreset
			if (registerWrite.reset = '1') then
				denable <= '0';
				dwrite <= '0';
				
				state4 <= init1;
			else
				stopDrs4_old <= stopDrs4;
				
				if(registerWrite.resetStates = '1') then
					state4 <= init1;
				end if;
				
				case state4 is
					when init1 =>
						counter1 <= 0;
						spiTransferMode <= standby;
						spiTransfer <= '1'; -- autoreset
						if(spiDone = '1') then
							state4 <= init2;
							spiTransfer <= '0'; -- autoreset
						end if;
						
					when init2 =>
						notReset <= '0'; -- autoreset
						counter1 <= counter1 + 1;
						if(counter1 = 10) then
							state4 <= init3;
							counter1 <= 0;
						end if;
					
					when init3 =>
						counter1 <= counter1 + 1;
						if(counter1 = 250) then -- 250 = ~2us
							state4 <= init4;
							counter1 <= 0;
						end if;
						
					when init4 =>
						spiTransferMode <= configRegister_write;
						spiTransfer <= '1'; -- autoreset
						if(spiDone = '1') then
							state4 <= init5;
							spiTransfer <= '0'; -- autoreset
						end if;
						
					when init5 =>
						spiTransferMode <= writeShiftRegister_write;
						spiTransfer <= '1'; -- autoreset
						if(spiDone = '1') then
							state4 <= drs4start0;
							spiTransfer <= '0'; -- autoreset
						end if;
						
					when drs4start0 =>
						counter1 <= 0;
						denable <= '1';
						dwrite <= '1';
						state4 <= drs4start1;
						
					when drs4start1 =>
						counter1 <= counter1 + 1;
						if(counter1 = 125) then -- 125 = ~1us ## ?!?
							state4 <= startSampling;
						end if;
					
					when startSampling =>
						dwrite <= '1';
						spiTransferMode <= transparentMode;
						spiTransfer <= '1'; -- autoreset
						if(spiDone = '1') then
							state4 <= sampling;
							spiTransfer <= '0'; -- autoreset
						end if;
					
					when sampling =>
						if(((stopDrs4_old = '0') and (stopDrs4 = '1')) or (registerWrite.stoftTrigger = '1')) then
							state4 <= readRoi;
							dwrite <= '0';
						end if;
						
					when readRoi =>
						spiTransferMode <= regionOfIntrest;
						spiTransfer <= '1'; -- autoreset
						if(spiDone = '1') then
							state4 <= startSampling;
							spiTransfer <= '0'; -- autoreset
						end if;
						
					when others => state4 <= init1;
				end case;
				
			end if;
		end if;
	end process P2;
	

end Behavioral;

