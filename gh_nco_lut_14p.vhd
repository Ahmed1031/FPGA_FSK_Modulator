-----------------------------------------------------------------------------
--	Filename:	gh_nco_lut_14p.vhd
--
--	Description:
--		a "Numerically Controlled Oscillator"
--		  also called a "Direct Digital Synthesizer"
--		      or a "Digitally Controlled Oscillator"
--		with a phase adjust port
--
-- Author:  Ahmed Asim Ghouri
-- Embedded Strings inc 
-- www.emstrings.com
-- Email : support@emstrings.com
--
--
-----------------------------------------
-- Fout = Frequency out
-- Fclk = Frequency of the Clock
-- D = value of the input data
-- n = number of bits in the accumulator
-- Fout = Fclk*(D/2^n)

LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_arith.all;
use IEEE.std_logic_unsigned.all;
--------------------------------
entity gh_nco_lut_14p is
	GENERIC (freq_word_size: INTEGER := 32);
	port(
		clk   : in STD_LOGIC;
	 	rst   : in STD_LOGIC; 
		FREQ  : in STD_LOGIC_VECTOR(freq_word_size-1 downto 0);
		PHASE :	in STD_LOGIC_VECTOR(13 downto 0):=(others => '0');
		nsin  : out STD_LOGIC_VECTOR(13 downto 0);
		cos   : out STD_LOGIC_VECTOR(13 downto 0)
		);
end entity;

architecture a of gh_nco_lut_14p is
--------------------------------
component gh_nsincos_rom_14_4 is
	port (
		CLK  : in std_logic;
		ADD  : in std_logic_vector(13 downto 0);
		nsin : out std_logic_vector(13 downto 0);
		cos  : out std_logic_vector(13 downto 0)
		);
end component;

	signal ACC_data   : STD_LOGIC_VECTOR(freq_word_size-1 downto 0);
	signal sin_phase  : STD_LOGIC_VECTOR(13 downto 0);
	signal nsin_reg   : STD_LOGIC_VECTOR(13 downto 0);

begin
-----

nsin <=not(nsin_reg);
--------------------
PROCESS (clk,rst)
BEGIN
	if (rst = '1') then
		ACC_data <= (others => '0');
		sin_phase <= (others => '0'); 
	elsif (rising_edge(clk)) then
		ACC_data <= ACC_data + FREQ;
		sin_phase <= (ACC_data(freq_word_size-1 downto freq_word_size-14)) + phase;
 	end if;
END PROCESS;
------------		
				  
u1 : gh_nsincos_rom_14_4 
	port map(
		clk => clk,
		add => sin_phase,
		cos => cos,
	   nsin => nsin_reg
				);

	
end architecture;
