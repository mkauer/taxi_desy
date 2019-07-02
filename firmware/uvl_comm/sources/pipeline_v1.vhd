--------------------------------------------------------------------------------
-- Design Name : pipeline_v1
-- File Name   : pipeline_v1.vhd
-- Function    : simple pipeline to delay or synchronize signals
-- Coder       : Marko Kossatz, DESY
-- Date        : 2019
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
--use ieee.numeric_std.all;

entity pipeline_v1 is
	generic
	(
		pipeLength : natural := 4;
		vectorWidth : natural := 16
	);
	port
	(
		clk : in std_logic;
		reset : in std_logic;
		--pipeIn : in std_logic; --_vector(vectorWidth-1 downto 0);
		--pipeOut : out std_logic --_vector(vectorWidth-1 downto 0);
		pipeIn : in std_logic_vector(vectorWidth-1 downto 0);
		pipeOut : out std_logic_vector(vectorWidth-1 downto 0)
	);
end entity;

-- TODO: implement vector input for variable width

architecture pipeline_v1_arch of pipeline_v1 is

	--signal pipe : std_logic_vector(pipeLength downto 0);
	type pipe_t is array (0 to pipeLength) of std_logic_vector(vectorWidth-1 downto 0);
	signal pipe : pipe_t;

begin

	--pipeOut <= pipeIn when pipeLength = 0 else pipe(pipe'right+1);
	pipeOut <= pipeIn when pipeLength = 0 else pipe(0);

g0: if pipeLength = 0 generate
	pipeOut <= pipeIn;
end generate;

g1: if pipeLength = 1 generate
	process(clk)
	begin
		if(rising_edge(clk)) then
			pipeOut <= pipeIn;
		end if; 
	end process;
end generate;

g2: if pipeLength > 1 generate
	
	pipeOut <= pipe(0);
	
	process(clk)
	begin
		if(rising_edge(clk)) then
			if(reset = '1') then
				--pipe <= (others=>'0');
				pipe <= (others=>(others=>'0'));
			else
				--pipe <= pipeIn & pipe(pipe'left downto pipe'right+1);
				pipe(pipeLength-1) <= pipeIn;
				for i in 0 to pipeLength-2 loop
					pipe(i) <= pipe(i+1);
				end loop;
			end if; 
		end if; 
	end process;
end generate;

end architecture;
