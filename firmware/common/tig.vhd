library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.NUMERIC_STD.ALL;
--use work.types.all;

--library unisim;
--use unisim.vcomponents.all;

entity tig is
    port
	(
		i : in std_logic;
		o : out std_logic
     );
end entity;

architecture Behavioral of tig is
	attribute keep : string;
	attribute DONT_TOUCH : string;

	signal temp_TPTHRU_TIG : std_logic;

	attribute keep of temp_TPTHRU_TIG : signal is "true";
	attribute DONT_TOUCH of temp_TPTHRU_TIG : signal is "true";

begin
	temp_TPTHRU_TIG <= i;
	o <= temp_TPTHRU_TIG;
end Behavioral;
