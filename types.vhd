--
--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 
--
--   To use any of the example code shown below, uncomment the lines and modify as necessary
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;

package types is

	type smc_bus is record
		clock : std_logic;
		reset : std_logic;
		chipSelect : std_logic;
		address : std_logic_vector(23 downto 0);
		read : std_logic;
		--write : std_logic;
		readStrobe : std_logic;
		writeStrobe : std_logic;
	end record;
	function smc_vectorToBus(inputVector : std_logic_vector) return smc_bus;
	function smc_busToVector(inputBus : smc_bus) return std_logic_vector;
--	function smc_replaceCs(inputBus : smc_bus; cs_new : std_logic) return smc_bus;
	
	type smc_asyncBus is record
		chipSelect : std_logic;
		address : std_logic_vector(23 downto 0);
		read : std_logic;
		write : std_logic;
		asyncReset : std_logic;
	end record;
	function smc_asyncVectorToBus(inputVector : std_logic_vector) return smc_asyncBus;
	function smc_busToAsyncVector(inputBus : smc_asyncBus) return std_logic_vector;
	
	type adc4channel_r is record
		data : std_logic_vector(3 downto 0);
		frame : std_logic;
		clock : std_logic;
	end record;
		
	function countZerosFromLeft8(patternIn : std_logic_vector) return unsigned;
	function countZerosFromRight8(patternIn : std_logic_vector) return unsigned;
	
	type smc_registerMap is record
		reg0 : std_logic_vector(15 downto 0);
		reg1 : std_logic_vector(15 downto 0);
		reg2 : std_logic_vector(15 downto 0);
		reg3 : std_logic_vector(15 downto 0);
		reg4 : std_logic_vector(15 downto 0);
		reg5 : std_logic_vector(15 downto 0);
		reg6 : std_logic_vector(15 downto 0);
		reg7 : std_logic_vector(15 downto 0);
		reg8 : std_logic_vector(15 downto 0);
		reg9 : std_logic_vector(15 downto 0);
		reg10 : std_logic_vector(15 downto 0);
		reg11 : std_logic_vector(15 downto 0);
		reg12 : std_logic_vector(15 downto 0);
		reg13 : std_logic_vector(15 downto 0);
		reg14 : std_logic_vector(15 downto 0);
		reg15 : std_logic_vector(15 downto 0);
		eventFifoNextWord : std_logic;
	end record;
	function smc_vectorToRegisterMap(inputVector : std_logic_vector) return smc_registerMap;
	function smc_RegisterMapToVector(inputRegister : smc_registerMap) return std_logic_vector;
		
	type triggerTiming_t is record
		ch0 : std_logic_vector(15 downto 0);
		ch1 : std_logic_vector(15 downto 0);
		ch2 : std_logic_vector(15 downto 0);
		ch3 : std_logic_vector(15 downto 0);
		ch4 : std_logic_vector(15 downto 0);
		ch5 : std_logic_vector(15 downto 0);
		ch6 : std_logic_vector(15 downto 0);
		ch7 : std_logic_vector(15 downto 0);
		newData : std_logic;
	end record;
	
	type dsr4Timing_t is record
		ch0 : std_logic_vector(15 downto 0);
		ch1 : std_logic_vector(15 downto 0);
		ch2 : std_logic_vector(15 downto 0);
		ch3 : std_logic_vector(15 downto 0);
		ch4 : std_logic_vector(15 downto 0);
		ch5 : std_logic_vector(15 downto 0);
		ch6 : std_logic_vector(15 downto 0);
		ch7 : std_logic_vector(15 downto 0);
		newData : std_logic;
		timingDone : std_logic;
	end record;
	
	type dsr4Sampling_t is record
		ch0 : std_logic_vector(15 downto 0);
		ch1 : std_logic_vector(15 downto 0);
		ch2 : std_logic_vector(15 downto 0);
		ch3 : std_logic_vector(15 downto 0);
		ch4 : std_logic_vector(15 downto 0);
		ch5 : std_logic_vector(15 downto 0);
		ch6 : std_logic_vector(15 downto 0);
		ch7 : std_logic_vector(15 downto 0);
		newData : std_logic;
		samplingDone : std_logic;
	end record;
	
	type dsr4Charge_t is record
		ch0 : std_logic_vector(15 downto 0);
		ch1 : std_logic_vector(15 downto 0);
		ch2 : std_logic_vector(15 downto 0);
		ch3 : std_logic_vector(15 downto 0);
		ch4 : std_logic_vector(15 downto 0);
		ch5 : std_logic_vector(15 downto 0);
		ch6 : std_logic_vector(15 downto 0);
		ch7 : std_logic_vector(15 downto 0);
		newData : std_logic;
		chargeDone : std_logic;
	end record;
	
	type eventFifoSystem_registerRead_t is record
		dmaBuffer : std_logic_vector(15 downto 0);
		eventFifoWordsDma : std_logic_vector(15 downto 0);
		eventFifoFullCounter : std_logic_vector(15 downto 0);
		eventFifoOverflowCounter : std_logic_vector(15 downto 0);
		eventFifoUnderflowCounter : std_logic_vector(15 downto 0);
		eventFifoErrorCounter : std_logic_vector(15 downto 0);
		eventFifoWords : std_logic_vector(15 downto 0);
		eventFifoFlags : std_logic_vector(15 downto 0);
		packetConfig : std_logic_vector(15 downto 0);
	end record;
	type eventFifoSystem_registerWrite_t is record
		clock : std_logic;
		reset : std_logic;
		nextWord : std_logic;
		eventFifoClear : std_logic;
		packetConfig : std_logic_vector(15 downto 0);
	end record;
	
	type triggerTimeToRisingEdge_registerRead_t is record
		ch0 : std_logic_vector(15 downto 0);
		ch1 : std_logic_vector(15 downto 0);
		ch2 : std_logic_vector(15 downto 0);
		ch3 : std_logic_vector(15 downto 0);
		ch4 : std_logic_vector(15 downto 0);
		ch5 : std_logic_vector(15 downto 0);
		ch6 : std_logic_vector(15 downto 0);
		ch7 : std_logic_vector(15 downto 0);
	end record;
	type triggerTimeToRisingEdge_registerWrite_t is record
		clock : std_logic;
		reset : std_logic;
	end record;
	
	type triggerDataDelay_registerRead_t is record
		numberOfDelayCycles : std_logic_vector(15 downto 0);
	end record;
	type triggerDataDelay_registerWrite_t is record
		clock : std_logic;
		reset : std_logic;
		numberOfDelayCycles : std_logic_vector(15 downto 0);
		resetDelay : std_logic;
	end record;
	
	type pixelRateCounter_registerRead_t is record
		ch0 : std_logic_vector(15 downto 0);
		ch1 : std_logic_vector(15 downto 0);
		ch2 : std_logic_vector(15 downto 0);
		ch3 : std_logic_vector(15 downto 0);
		ch4 : std_logic_vector(15 downto 0);
		ch5 : std_logic_vector(15 downto 0);
		ch6 : std_logic_vector(15 downto 0);
		ch7 : std_logic_vector(15 downto 0);
	end record;
	type pixelRateCounter_registerWrite_t is record
		clock : std_logic;
		reset : std_logic;
		resetCounter : std_logic_vector(15 downto 0);
	end record;
	
	type dac088s085_x3_registerRead_t is record
		discriminatorThesholdChannel0 : std_logic_vector(7 downto 0);
		discriminatorThesholdChannel1 : std_logic_vector(7 downto 0);
		discriminatorThesholdChannel2 : std_logic_vector(7 downto 0);
		discriminatorThesholdChannel3 : std_logic_vector(7 downto 0);
		discriminatorThesholdChannel4 : std_logic_vector(7 downto 0);
		discriminatorThesholdChannel5 : std_logic_vector(7 downto 0);
		discriminatorThesholdChannel6 : std_logic_vector(7 downto 0);
		discriminatorThesholdChannel7 : std_logic_vector(7 downto 0);
		discriminatorOffsetChannel0n : std_logic_vector(7 downto 0);
		discriminatorOffsetChannel0p : std_logic_vector(7 downto 0);
		discriminatorOffsetChannel1n : std_logic_vector(7 downto 0);
		discriminatorOffsetChannel1p : std_logic_vector(7 downto 0);
		discriminatorOffsetChannel2n : std_logic_vector(7 downto 0);
		discriminatorOffsetChannel2p : std_logic_vector(7 downto 0);
		discriminatorOffsetChannel3n : std_logic_vector(7 downto 0);
		discriminatorOffsetChannel3p : std_logic_vector(7 downto 0);
		discriminatorOffsetChannel4n : std_logic_vector(7 downto 0);
		discriminatorOffsetChannel4p : std_logic_vector(7 downto 0);
		discriminatorOffsetChannel5n : std_logic_vector(7 downto 0);
		discriminatorOffsetChannel5p : std_logic_vector(7 downto 0);
		discriminatorOffsetChannel6n : std_logic_vector(7 downto 0);
		discriminatorOffsetChannel6p : std_logic_vector(7 downto 0);
		discriminatorOffsetChannel7n : std_logic_vector(7 downto 0);
		discriminatorOffsetChannel7p : std_logic_vector(7 downto 0);	
		valuesChangedChip0 : std_logic_vector(7 downto 0);
		valuesChangedChip1 : std_logic_vector(7 downto 0);
		valuesChangedChip2 : std_logic_vector(7 downto 0);
	end record;
	type dac088s085_x3_registerWrite_t is record
		clock : std_logic;
		reset : std_logic;
		resetCounter : std_logic_vector(15 downto 0);
	end record;
	
	
	
end types;

package body types is

	function smc_vectorToBus(inputVector : std_logic_vector) return smc_bus is
		variable temp : smc_bus;
	begin
		temp.address := inputVector(23 downto 0);
	--	temp.write := inputVector(24);
		temp.writeStrobe := inputVector(25);
		temp.read := inputVector(26);
		temp.readStrobe := inputVector(27);
		temp.chipSelect := inputVector(28);
		temp.reset := inputVector(29);
		temp.clock := inputVector(30);
		return temp;
	end;
	
	function smc_busToVector(inputBus : smc_bus) return std_logic_vector is
		variable temp : std_logic_vector(31 downto 0);
	begin
		temp(23 downto 0) := inputBus.address;
	--	temp(24) := inputBus.write;
		temp(25) := inputBus.writeStrobe;
		temp(26) := inputBus.read;
		temp(27) := inputBus.readStrobe;
		temp(28) := inputBus.chipSelect;
		temp(29) := inputBus.reset;
		temp(30) := inputBus.clock;
		return temp;
	end;

	function smc_replaceCs(inputBus : smc_bus; cs_new : std_logic) return smc_bus is
		variable temp : smc_bus;
	begin
		temp.clock := inputBus.clock;
		temp.reset := inputBus.reset;
		temp.chipSelect := cs_new;
		temp.address := inputBus.address;
		temp.read := inputBus.read;
		temp.readStrobe := inputBus.readStrobe;
	--	temp.write := inputBus.write;
		temp.writeStrobe := inputBus.writeStrobe;
		return temp;
	end;
	
	function smc_asyncVectorToBus(inputVector : std_logic_vector) return smc_asyncBus is
		variable temp : smc_asyncBus;
	begin
		temp.address := inputVector(23 downto 0);
		temp.write := inputVector(24);
		temp.read := inputVector(25);
		temp.chipSelect := inputVector(26);
		temp.asyncReset := inputVector(27);
		return temp;
	end;

	function smc_busToAsyncVector(inputBus : smc_asyncBus) return std_logic_vector is
		variable temp : std_logic_vector(27 downto 0);
	begin
		temp(23 downto 0) := inputBus.address;
		temp(24) := inputBus.write;
		temp(25) := inputBus.read;
		temp(26) := inputBus.chipSelect;
		temp(27) := inputBus.asyncReset;
		return temp;
	end;

	function countZerosFromLeft8(patternIn : std_logic_vector) return unsigned is
		variable temp : unsigned(3 downto 0) := "0000";
	begin
		if(std_match(patternIn, "1-------")) then
			temp := "0000";
		elsif(std_match(patternIn, "01------")) then
			temp := "0001";
		elsif(std_match(patternIn, "001-----")) then
			temp := "0010";
		elsif(std_match(patternIn, "0001----")) then
			temp := "0011";
		elsif(std_match(patternIn, "00001---")) then
			temp := "0100";
		elsif(std_match(patternIn, "000001--")) then
			temp := "0101";
		elsif(std_match(patternIn, "0000001-")) then
			temp := "0110";
		elsif(std_match(patternIn, "00000001")) then
			temp := "0111";
		elsif(std_match(patternIn, "00000000")) then
			temp := "1000";
		else
			temp := "0000";
		end if;
		return temp;
	end;

	function countZerosFromRight8(patternIn : std_logic_vector) return unsigned is
		variable temp : unsigned(3 downto 0) := "0000";
	begin
		if(std_match(patternIn, "-------1")) then
			temp := "0000";
		elsif(std_match(patternIn, "------10")) then
			temp := "0001";
		elsif(std_match(patternIn, "-----100")) then
			temp := "0010";
		elsif(std_match(patternIn, "----1000")) then
			temp := "0011";
		elsif(std_match(patternIn, "---10000")) then
			temp := "0100";
		elsif(std_match(patternIn, "--100000")) then
			temp := "0101";
		elsif(std_match(patternIn, "-1000000")) then
			temp := "0110";
		elsif(std_match(patternIn, "10000000")) then
			temp := "0111";
		elsif(std_match(patternIn, "00000000")) then
			temp := "1000";
		else
			temp := "0000";
		end if;
		return temp;
	end;

	function smc_vectorToRegisterMap(inputVector : std_logic_vector) return smc_registerMap is
		variable temp : smc_registerMap;
	begin
		temp.reg0 := inputVector(0*16+15 downto 0*16+0);
		temp.reg1 := inputVector(1*16+15 downto 1*16+0);
		temp.reg2 := inputVector(2*16+15 downto 2*16+0);
		temp.reg3 := inputVector(3*16+15 downto 3*16+0);
		temp.reg4 := inputVector(4*16+15 downto 4*16+0);
		temp.reg5 := inputVector(5*16+15 downto 5*16+0);
		temp.reg6 := inputVector(6*16+15 downto 6*16+0);
		temp.reg7 := inputVector(7*16+15 downto 7*16+0);
		temp.reg8 := inputVector(8*16+15 downto 8*16+0);
		temp.reg9 := inputVector(9*16+15 downto 9*16+0);
		temp.reg10 := inputVector(10*16+15 downto 10*16+0);
		temp.reg11 := inputVector(11*16+15 downto 11*16+0);
		temp.reg12 := inputVector(12*16+15 downto 12*16+0);
		temp.reg13 := inputVector(13*16+15 downto 13*16+0);
		temp.reg14 := inputVector(14*16+15 downto 14*16+0);
		temp.reg15 := inputVector(15*16+15 downto 15*16+0);
		
		return temp;
	end;
	
	function smc_RegisterMapToVector(inputRegister : smc_registerMap) return std_logic_vector is
		variable temp : std_logic_vector(16*16-1 downto 0);
	begin
		temp(0*16+15 downto 0*16+0) := inputRegister.reg0;
		temp(1*16+15 downto 1*16+0) := inputRegister.reg1;
		temp(2*16+15 downto 2*16+0) := inputRegister.reg2;
		temp(3*16+15 downto 3*16+0) := inputRegister.reg3;
		temp(4*16+15 downto 4*16+0) := inputRegister.reg4;
		temp(5*16+15 downto 5*16+0) := inputRegister.reg5;
		temp(6*16+15 downto 6*16+0) := inputRegister.reg6;
		temp(7*16+15 downto 7*16+0) := inputRegister.reg7;
		temp(8*16+15 downto 8*16+0) := inputRegister.reg8;
		temp(9*16+15 downto 9*16+0) := inputRegister.reg9;
		temp(10*16+15 downto 10*16+0) := inputRegister.reg10;
		temp(11*16+15 downto 11*16+0) := inputRegister.reg11;
		temp(12*16+15 downto 12*16+0) := inputRegister.reg12;
		temp(13*16+15 downto 13*16+0) := inputRegister.reg13;
		temp(14*16+15 downto 14*16+0) := inputRegister.reg14;
		temp(15*16+15 downto 15*16+0) := inputRegister.reg15;
		return temp;
	end;
	
---- Example 1
--  function <function_name>  (signal <signal_name> : in <type_declaration>  ) return <type_declaration> is
--    variable <variable_name>     : <type_declaration>;
--  begin
--    <variable_name> := <signal_name> xor <signal_name>;
--    return <variable_name>; 
--  end <function_name>;

---- Example 2
--  function <function_name>  (signal <signal_name> : in <type_declaration>;
--                         signal <signal_name>   : in <type_declaration>  ) return <type_declaration> is
--  begin
--    if (<signal_name> = '1') then
--      return <signal_name>;
--    else
--      return 'Z';
--    end if;
--  end <function_name>;

---- Procedure Example
--  procedure <procedure_name>  (<type_declaration> <constant_name>  : in <type_declaration>) is
--    
--  begin
--    
--  end <procedure_name>;
 
end types;



-------------------------------------------------------------------------------



--library IEEE;
--use IEEE.STD_LOGIC_1164.all;
--use IEEE.numeric_std.all;
--
--package registerTypeBase is
--	generic(type registerType)
--	
--	type smc_registerMap is record
--		reg0 : std_logic_vector(15 downto 0);
--		reg1 : std_logic_vector(15 downto 0);
--		reg2 : std_logic_vector(15 downto 0);
--		reg3 : std_logic_vector(15 downto 0);
--		reg4 : std_logic_vector(15 downto 0);
--	end record;
--	function smc_vectorToRegisterMap(inputVector : std_logic_vector) return smc_registerMap;
--	function smc_RegisterMapToVector(inputRegister : smc_registerMap) return std_logic_vector;
--	
--end registerTypeBase;
--
--package body registerTypeBase is
--
--	function smc_vectorToRegisterMap(inputVector : std_logic_vector) return smc_registerMap is
--		variable temp : smc_registerMap;
--	begin
--		inputVector.reg0 := temp(0*16+15 downto 0*16+0);
--		inputVector.reg1 := temp(1*16+15 downto 1*16+0);
--		inputVector.reg2 := temp(2*16+15 downto 2*16+0);
--		inputVector.reg3 := temp(3*16+15 downto 3*16+0);
--		inputVector.reg4 := temp(4*16+15 downto 4*16+0);
--		inputVector.reg5 := temp(5*16+15 downto 5*16+0);
--		inputVector.reg6 := temp(6*16+15 downto 6*16+0);
--		inputVector.reg7 := temp(7*16+15 downto 7*16+0);
--		inputVector.reg8 := temp(8*16+15 downto 8*16+0);
--		inputVector.reg9 := temp(9*16+15 downto 9*16+0);
--		inputVector.reg10 := temp(10*16+15 downto 10*16+0);
--		inputVector.reg11 := temp(11*16+15 downto 11*16+0);
--		inputVector.reg12 := temp(12*16+15 downto 12*16+0);
--		inputVector.reg13 := temp(13*16+15 downto 13*16+0);
--		inputVector.reg14 := temp(14*16+15 downto 14*16+0);
--		inputVector.reg15 := temp(15*16+15 downto 15*16+0);
--		
--		return temp;
--	end;
--	
--	function smc_RegisterMapToVector(inputRegister : smc_registerMap) return std_logic_vector is
--		variable temp : std_logic_vector(16*16-1 downto 0);
--	begin
--		temp(0*16+15 downto 0*16+0) := inputVector.reg0;
--		temp(1*16+15 downto 1*16+0) := inputVector.reg1;
--		temp(2*16+15 downto 2*16+0) := inputVector.reg2;
--		temp(3*16+15 downto 3*16+0) := inputVector.reg3;
--		temp(4*16+15 downto 4*16+0) := inputVector.reg4;
--		temp(5*16+15 downto 5*16+0) := inputVector.reg5;
--		temp(6*16+15 downto 6*16+0) := inputVector.reg6;
--		temp(7*16+15 downto 7*16+0) := inputVector.reg7;
--		temp(8*16+15 downto 8*16+0) := inputVector.reg8;
--		temp(9*16+15 downto 9*16+0) := inputVector.reg9;
--		temp(10*16+15 downto 10*16+0) := inputVector.reg10;
--		temp(11*16+15 downto 11*16+0) := inputVector.reg11;
--		temp(12*16+15 downto 12*16+0) := inputVector.reg12;
--		temp(13*16+15 downto 13*16+0) := inputVector.reg13;
--		temp(14*16+15 downto 14*16+0) := inputVector.reg14;
--		temp(15*16+15 downto 15*16+0) := inputVector.reg15;
--		return temp;
--	end;
--	 
--end registerTypeBase;
