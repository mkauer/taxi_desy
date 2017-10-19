--
--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 
--
-- To use any of the example code shown below, uncomment the lines and modify as necessary
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;

package lutAdder is

	function lutAdder4(inputVector : std_logic_vector) return unsigned;
	function lutAdder6(inputVector : std_logic_vector) return unsigned;
	function lutAdder8(inputVector : std_logic_vector) return unsigned;

end lutAdder;

package body lutAdder is

	function lutAdder4(inputVector : std_logic_vector) return unsigned is
		variable sum : unsigned(2 downto 0);
	begin
		with inputVector(0 to 3) select 
			sum := 
				"000" when "0000",
				"001" when "0001",
				"001" when "0010",
				"010" when "0011",
				"001" when "0100",
				"010" when "0101",
				"010" when "0110",
				"011" when "0111",
				"001" when "1000",
				"010" when "1001",
				"010" when "1010",
				"011" when "1011",
				"010" when "1100",
				"011" when "1101",
				"011" when "1110",
				"100" when "1111",
				"000" when others;
		return sum;
	end;

	function lutAdder6(inputVector : std_logic_vector) return unsigned is
		variable sum : unsigned(2 downto 0);
	begin
		with inputVector(0 to 5) select 
			sum := 
				"000" when "000000",
				"001" when "000001",
				"001" when "000010",
				"010" when "000011",
				"001" when "000100",
				"010" when "000101",
				"010" when "000110",
				"011" when "000111",
				"001" when "001000",
				"010" when "001001",
				"010" when "001010",
				"011" when "001011",
				"010" when "001100",
				"011" when "001101",
				"011" when "001110",
				"100" when "001111",
				"001" when "010000",
				"010" when "010001",
				"010" when "010010",
				"011" when "010011",
				"010" when "010100",
				"011" when "010101",
				"011" when "010110",
				"100" when "010111",
				"010" when "011000",
				"011" when "011001",
				"011" when "011010",
				"100" when "011011",
				"011" when "011100",
				"100" when "011101",
				"100" when "011110",
				"101" when "011111",
				"001" when "100000",
				"010" when "100001",
				"010" when "100010",
				"011" when "100011",
				"010" when "100100",
				"011" when "100101",
				"011" when "100110",
				"100" when "100111",
				"010" when "101000",
				"011" when "101001",
				"011" when "101010",
				"100" when "101011",
				"011" when "101100",
				"100" when "101101",
				"100" when "101110",
				"101" when "101111",
				"010" when "110000",
				"011" when "110001",
				"011" when "110010",
				"100" when "110011",
				"011" when "110100",
				"100" when "110101",
				"100" when "110110",
				"101" when "110111",
				"011" when "111000",
				"100" when "111001",
				"100" when "111010",
				"101" when "111011",
				"100" when "111100",
				"101" when "111101",
				"101" when "111110",
				"110" when "111111",
				"000" when others;
		return sum;
	end;

	function lutAdder8(inputVector : std_logic_vector) return unsigned is
		variable sum : unsigned(3 downto 0);
	begin
		with inputVector(0 to 7) select 
			sum := 
				"0000" when "00000000",
				"0001" when "00000001",
				"0001" when "00000010",
				"0010" when "00000011",
				"0001" when "00000100",
				"0010" when "00000101",
				"0010" when "00000110",
				"0011" when "00000111",
				"0001" when "00001000",
				"0010" when "00001001",
				"0010" when "00001010",
				"0011" when "00001011",
				"0010" when "00001100",
				"0011" when "00001101",
				"0011" when "00001110",
				"0100" when "00001111",
				"0001" when "00010000",
				"0010" when "00010001",
				"0010" when "00010010",
				"0011" when "00010011",
				"0010" when "00010100",
				"0011" when "00010101",
				"0011" when "00010110",
				"0100" when "00010111",
				"0010" when "00011000",
				"0011" when "00011001",
				"0011" when "00011010",
				"0100" when "00011011",
				"0011" when "00011100",
				"0100" when "00011101",
				"0100" when "00011110",
				"0101" when "00011111",
				"0001" when "00100000",
				"0010" when "00100001",
				"0010" when "00100010",
				"0011" when "00100011",
				"0010" when "00100100",
				"0011" when "00100101",
				"0011" when "00100110",
				"0100" when "00100111",
				"0010" when "00101000",
				"0011" when "00101001",
				"0011" when "00101010",
				"0100" when "00101011",
				"0011" when "00101100",
				"0100" when "00101101",
				"0100" when "00101110",
				"0101" when "00101111",
				"0010" when "00110000",
				"0011" when "00110001",
				"0011" when "00110010",
				"0100" when "00110011",
				"0011" when "00110100",
				"0100" when "00110101",
				"0100" when "00110110",
				"0101" when "00110111",
				"0011" when "00111000",
				"0100" when "00111001",
				"0100" when "00111010",
				"0101" when "00111011",
				"0100" when "00111100",
				"0101" when "00111101",
				"0101" when "00111110",
				"0110" when "00111111",
				"0001" when "01000000",
				"0010" when "01000001",
				"0010" when "01000010",
				"0011" when "01000011",
				"0010" when "01000100",
				"0011" when "01000101",
				"0011" when "01000110",
				"0100" when "01000111",
				"0010" when "01001000",
				"0011" when "01001001",
				"0011" when "01001010",
				"0100" when "01001011",
				"0011" when "01001100",
				"0100" when "01001101",
				"0100" when "01001110",
				"0101" when "01001111",
				"0010" when "01010000",
				"0011" when "01010001",
				"0011" when "01010010",
				"0100" when "01010011",
				"0011" when "01010100",
				"0100" when "01010101",
				"0100" when "01010110",
				"0101" when "01010111",
				"0011" when "01011000",
				"0100" when "01011001",
				"0100" when "01011010",
				"0101" when "01011011",
				"0100" when "01011100",
				"0101" when "01011101",
				"0101" when "01011110",
				"0110" when "01011111",
				"0010" when "01100000",
				"0011" when "01100001",
				"0011" when "01100010",
				"0100" when "01100011",
				"0011" when "01100100",
				"0100" when "01100101",
				"0100" when "01100110",
				"0101" when "01100111",
				"0011" when "01101000",
				"0100" when "01101001",
				"0100" when "01101010",
				"0101" when "01101011",
				"0100" when "01101100",
				"0101" when "01101101",
				"0101" when "01101110",
				"0110" when "01101111",
				"0011" when "01110000",
				"0100" when "01110001",
				"0100" when "01110010",
				"0101" when "01110011",
				"0100" when "01110100",
				"0101" when "01110101",
				"0101" when "01110110",
				"0110" when "01110111",
				"0100" when "01111000",
				"0101" when "01111001",
				"0101" when "01111010",
				"0110" when "01111011",
				"0101" when "01111100",
				"0110" when "01111101",
				"0110" when "01111110",
				"0111" when "01111111",
				"0001" when "10000000",
				"0010" when "10000001",
				"0010" when "10000010",
				"0011" when "10000011",
				"0010" when "10000100",
				"0011" when "10000101",
				"0011" when "10000110",
				"0100" when "10000111",
				"0010" when "10001000",
				"0011" when "10001001",
				"0011" when "10001010",
				"0100" when "10001011",
				"0011" when "10001100",
				"0100" when "10001101",
				"0100" when "10001110",
				"0101" when "10001111",
				"0010" when "10010000",
				"0011" when "10010001",
				"0011" when "10010010",
				"0100" when "10010011",
				"0011" when "10010100",
				"0100" when "10010101",
				"0100" when "10010110",
				"0101" when "10010111",
				"0011" when "10011000",
				"0100" when "10011001",
				"0100" when "10011010",
				"0101" when "10011011",
				"0100" when "10011100",
				"0101" when "10011101",
				"0101" when "10011110",
				"0110" when "10011111",
				"0010" when "10100000",
				"0011" when "10100001",
				"0011" when "10100010",
				"0100" when "10100011",
				"0011" when "10100100",
				"0100" when "10100101",
				"0100" when "10100110",
				"0101" when "10100111",
				"0011" when "10101000",
				"0100" when "10101001",
				"0100" when "10101010",
				"0101" when "10101011",
				"0100" when "10101100",
				"0101" when "10101101",
				"0101" when "10101110",
				"0110" when "10101111",
				"0011" when "10110000",
				"0100" when "10110001",
				"0100" when "10110010",
				"0101" when "10110011",
				"0100" when "10110100",
				"0101" when "10110101",
				"0101" when "10110110",
				"0110" when "10110111",
				"0100" when "10111000",
				"0101" when "10111001",
				"0101" when "10111010",
				"0110" when "10111011",
				"0101" when "10111100",
				"0110" when "10111101",
				"0110" when "10111110",
				"0111" when "10111111",
				"0010" when "11000000",
				"0011" when "11000001",
				"0011" when "11000010",
				"0100" when "11000011",
				"0011" when "11000100",
				"0100" when "11000101",
				"0100" when "11000110",
				"0101" when "11000111",
				"0011" when "11001000",
				"0100" when "11001001",
				"0100" when "11001010",
				"0101" when "11001011",
				"0100" when "11001100",
				"0101" when "11001101",
				"0101" when "11001110",
				"0110" when "11001111",
				"0011" when "11010000",
				"0100" when "11010001",
				"0100" when "11010010",
				"0101" when "11010011",
				"0100" when "11010100",
				"0101" when "11010101",
				"0101" when "11010110",
				"0110" when "11010111",
				"0100" when "11011000",
				"0101" when "11011001",
				"0101" when "11011010",
				"0110" when "11011011",
				"0101" when "11011100",
				"0110" when "11011101",
				"0110" when "11011110",
				"0111" when "11011111",
				"0011" when "11100000",
				"0100" when "11100001",
				"0100" when "11100010",
				"0101" when "11100011",
				"0100" when "11100100",
				"0101" when "11100101",
				"0101" when "11100110",
				"0110" when "11100111",
				"0100" when "11101000",
				"0101" when "11101001",
				"0101" when "11101010",
				"0110" when "11101011",
				"0101" when "11101100",
				"0110" when "11101101",
				"0110" when "11101110",
				"0111" when "11101111",
				"0100" when "11110000",
				"0101" when "11110001",
				"0101" when "11110010",
				"0110" when "11110011",
				"0101" when "11110100",
				"0110" when "11110101",
				"0110" when "11110110",
				"0111" when "11110111",
				"0101" when "11111000",
				"0110" when "11111001",
				"0110" when "11111010",
				"0111" when "11111011",
				"0110" when "11111100",
				"0111" when "11111101",
				"0111" when "11111110",
				"1000" when "11111111",
				"0000" when others;
		return sum;
	end;
 
end lutAdder;
