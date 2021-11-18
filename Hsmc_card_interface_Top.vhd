-- Author:  Ahmed Asim Ghouri
-- Embedded Strings inc 
-- www.emstrings.com
-- Email : support@emstrings.com
-------------------------------------------------------------------
-- VHDL File Description : Hsmc ADC to DAC Card based FSK Modulator
-- HSMC = High Speed Mezzanine Card
-- Author : Ahmed Asim Ghouri 
-- Dated : 6th May 2014 
-- Ver 1.0
-- Remarks : FSK Modulator 
-- Frequency range : 12MHz-to-6Mhz
-- ++++++++++++++++++++++++
-- Embedded Strings pvt ltd
-- www.emstrings.com
----------------------------
LIBRARY ieee ;
USE ieee.std_logic_1164.all ;
USE ieee.numeric_std.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
use IEEE.math_real.all;
--

-- Top level module
ENTITY Hsmc_card_interface_Top  IS
	
	PORT (	
	      OSC_50  : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
	      -- HSMC Connector Signals
	      -- ADC Signals 
			AD_SCLK : INOUT STD_LOGIC;
	      AD_SDIO : INOUT STD_LOGIC; 
			-- U1 ADC Chip Channel A
	      ADA_D   : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
	      ADA_DCO : IN STD_LOGIC;  
	      ADA_OE  : OUT STD_LOGIC; 
	      ADA_OR  : IN STD_LOGIC;
	      ADA_SPI_CS : OUT STD_LOGIC; 
			-- U2 ADC Chip Channel B
	      ADB_D   : IN STD_LOGIC_VECTOR(13 DOWNTO 0); 
	      ADB_DCO : IN STD_LOGIC;
	      ADB_OE  : OUT STD_LOGIC;
	      ADB_OR  : IN STD_LOGIC;
	      ADB_SPI_CS :  OUT STD_LOGIC;  
			--------------------
			-- AIC23 AUDIO CODEC
			AIC_BCLK   : INOUT STD_LOGIC;
	      AIC_DIN    : OUT STD_LOGIC;
			AIC_DOUT   : INOUT STD_LOGIC;
			AIC_LRCIN  : INOUT STD_LOGIC;
			AIC_LRCOUT : INOUT STD_LOGIC; 
			AIC_SPI_CS : OUT STD_LOGIC;
			AIC_XCLK   : OUT STD_LOGIC;
			--
			CLKIN1  : IN STD_LOGIC; -- Going to TP1
			CLKOUT0 : OUT STD_LOGIC; -- Going to TP2
			-- DAC Channel A
			DA : OUT STD_LOGIC_VECTOR(13 DOWNTO 0);
			-- DAC Channel B
			DB : OUT STD_LOGIC_VECTOR(13 DOWNTO 0);
			-- Both ADC and DAC Clocks are slected by Jumper settings
			-- i.e J15, J17, J3 and J7
			-- Differental Clock Output
			FPGA_CLK_A_N : INOUT STD_LOGIC;
			FPGA_CLK_A_P : INOUT STD_LOGIC;
			--
			FPGA_CLK_B_N : INOUT STD_LOGIC;
			FPGA_CLK_B_P : INOUT STD_LOGIC;
			--
			J1_152 : INOUT STD_LOGIC; -- Going to TP5
			-- External Clock Differental input 
			XT_IN_N : IN STD_LOGIC;
			XT_IN_P : IN STD_LOGIC;
			-- Switches
			SW      :  IN STD_LOGIC_VECTOR(17 DOWNTO 0);
			-- Push Buttons 
			KEY     :  IN STD_LOGIC_VECTOR(3 DOWNTO 0); 
			-- UART Signals 
			UART_CTS: OUT STD_LOGIC; -- Going to PIN_G14
			UART_TXD: OUT STD_LOGIC; -- Going to PIN_G9
			UART_RTS:  IN STD_LOGIC; -- Going to PIN_J13
			UART_RXD:  IN STD_LOGIC; -- Going to PIN_G12
			-- LEDs 
			LEDG    :  OUT STD_LOGIC_VECTOR(8 DOWNTO 0); 
			LEDR    :  OUT STD_LOGIC_VECTOR(17 DOWNTO 0)
			     ) ;
END Hsmc_card_interface_Top ;

ARCHITECTURE Data_acquisition OF Hsmc_card_interface_Top IS
-----------------------------------------------------------
--Convert integer to unsigned std_logic vector function
function int2ustd(value : integer; width : integer) return std_logic_vector is 
-- convert integer to unsigned std_logicvector 
variable temp :   std_logic_vector(width-1 downto 0);
begin
	if (width>0) then
		temp:=conv_std_logic_vector(conv_unsigned(value, width ), width);
	end if ;
	return temp;
end int2ustd;
-------------
-- PLL_locked
Component PLL IS
	PORT
	(
		areset		: IN STD_LOGIC  := '0';
		inclk0		: IN STD_LOGIC  := '0';
		c0				: OUT STD_LOGIC ;
		c1				: OUT STD_LOGIC ;
		c2				: OUT STD_LOGIC ;
		c3				: OUT STD_LOGIC ;
		locked		: OUT STD_LOGIC 
	);
End Component;
-------------------------------------
-- gh NCO 
Component gh_nco_lut_14p is
	GENERIC (freq_word_size: INTEGER := 32);
	port(
		clk   : in STD_LOGIC;
	 	rst   : in STD_LOGIC; 
		FREQ  : in STD_LOGIC_VECTOR(freq_word_size-1 downto 0);
		PHASE : in STD_LOGIC_VECTOR(13 downto 0):=(others => '0');
		nsin  : out STD_LOGIC_VECTOR(13 downto 0);
		cos   : out STD_LOGIC_VECTOR(13 downto 0)
		);
End Component;
-------------------------------------------------
Component GPIO_demo is
    Port ( SW       : in  STD_LOGIC_VECTOR (17 downto 0);
           CLOCK_50 : in  STD_LOGIC;
           LEDR0    : out  STD_LOGIC; 
           UART_TXD : out  STD_LOGIC
			    );
End Component;
---------------
-- ADC data registers
SIGNAL ADC_data_A : STD_LOGIC_VECTOR(13 DOWNTO 0);
SIGNAL ADC_data_B : STD_LOGIC_VECTOR(13 DOWNTO 0);
--
-- DAC Data registers
SIGNAL DAC_A : STD_LOGIC_VECTOR(13 DOWNTO 0);
SIGNAL DAC_B : STD_LOGIC_VECTOR(13 DOWNTO 0);
--
SIGNAL freq_out     : STD_LOGIC_VECTOR(13 DOWNTO 0);
SIGNAL sin_out_reg  : STD_LOGIC_VECTOR(13 DOWNTO 0);
SIGNAL sin_out_adj  : STD_LOGIC_VECTOR(13 DOWNTO 0);
SIGNAL nco_sin_out  : STD_LOGIC_VECTOR(13 DOWNTO 0);
SIGNAL nco_cos_out  : STD_LOGIC_VECTOR(13 DOWNTO 0);
SIGNAL nco_squ_out  : STD_LOGIC_VECTOR(13 DOWNTO 0);
SIGNAL nco_saw_out  : STD_LOGIC_VECTOR(13 DOWNTO 0);
Constant OFF_set:STD_LOGIC_VECTOR(13 DOWNTO 0):="01111111111111";
Constant Phase_input : INTEGER := 180;
Constant Phase_mode  : INTEGER := 80;
Constant Freq_mode   : INTEGER := 20;
Constant Freqy_set   : INTEGER := 12;
------------------------------------------------------------------
Constant Freq_12Mhz  : INTEGER := 515396075; --<< to generate 12Mhz
Constant Freq_6Mhz   : INTEGER := 257698037; --<< to generate 6Mhz
SIGNAL   Freq_set    : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL   Freq_set_12Mhz    : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL   Freq_set_6Mhz     : STD_LOGIC_VECTOR(31 DOWNTO 0);
--
SIGNAL Count : STD_LOGIC_VECTOR(13 DOWNTO 0);
SIGNAL reset_n, reset_pll, NCO_valid, DAC_rdy, UART_Txout, UART_pll : STD_LOGIC ;
SIGNAL sys_clk, sys_clk_90deg, sys_clk_180deg, sys_clk_270deg, pll_locked : STD_LOGIC ;

Begin 
---------------------
reset_n	  <= KEY(3);
reset_pll  <= not(reset_n);
AD_SCLK	  <= SW(0);			-- (DFS)Data Format Select
AD_SDIO	  <= SW(1);			-- (DCS)Duty Cycle Stabilizer Select
ADA_OE	  <= '0';			-- enable ADA output
ADA_SPI_CS <= '1';			-- disable ADA_SPI_CS (CSB)
ADB_OE	  <= '0';			-- enable ADB output
ADB_SPI_CS <= '1';			-- disable ADB_SPI_CS (CSB)
-- Clock Sources 
FPGA_CLK_A_P	<=  sys_clk_180deg;
FPGA_CLK_A_N	<= not(sys_clk_180deg);
FPGA_CLK_B_P	<=  sys_clk_270deg;
FPGA_CLK_B_N	<= not(sys_clk_270deg);
LEDG(2)        <= pll_locked;
Freq_set_12Mhz <= int2ustd(Freq_12Mhz,32);
Freq_set_6Mhz  <= int2ustd(Freq_6Mhz,32);
-----------------------------------------
-- Freq_set <= Freq_set_12Mhz when SW(4 downto 2) = "011" else Freq_set_6Mhz;   
--------------------------------------------------------------------------
-- PLL Port Mapping
Clock : PLL  port map (
                      reset_pll, 
                      OSC_50(0), 
							 sys_clk, 
							 sys_clk_90deg, 
							 sys_clk_180deg, 
							 sys_clk_270deg, 
							 pll_locked
							 );

----------------------
--gh NCO Port Mapping
Sine_Wave_Generator : gh_nco_lut_14p  port map (
										                sys_clk,
										                reset_pll,
										                Freq_set,
										                int2ustd(Phase_input,14),
										                nco_sin_out,
										                nco_cos_out
										                          );
--------------------------------------------------------	
-- UART Port Mapping
UART_module : GPIO_demo port map (
                      SW, 
                      OSC_50(0), 
							 LEDR(0), 
							 UART_Txout 
							 		 );
---------------------------------							 
Generating_Ramp: PROCESS(sys_clk)
BEGIN
     IF reset_n = '0' THEN
           Count <= (others=>'0');
		ELSE IF rising_edge(sys_clk) THEN  
		  Count <= Count + "0000000000001" ;
   END IF;
 END IF; 
END PROCESS;			 
----------------------------------------------
Interfacing_ADC_DAC: PROCESS(sys_clk, reset_n)
BEGIN
IF reset_n = '0' THEN
        ADC_data_A <= (others=>'0');
		  ADC_data_B <= (others=>'0');
		  --
		  DA <= (others=>'0');
		  DB <= (others=>'0');
		  --
		  LEDR(17 downto 15) <= (others=>'0');
		  DAC_rdy <= '0';
		  -- Defualt Frquency settings
		  Freq_set <= Freq_set_6Mhz; 
		  		  	  
		-- 1st Condition -------------------
		   ELSIF SW(17 downto 15) = "000" THEN 
			      LEDR(17 downto 15) <= "000";
	            ADC_data_A <= ADA_D;  
               ADC_data_B <= ADB_D;
		      ----------------
				-- DAC's A & B are connected to an Up-Counter 
            DA <= Count;
		      DB <= not(Count);
		
		-- 2nd Condition -------------------
	  	   ELSIF SW(17 downto 15)  = "001" THEN    
			      LEDR(17 downto 15) <= "001";
				-- ADC output is connected directly to DAC 
	         DA <= ADA_D;  
            DB <= ADB_D;
		
		-- 3rd Condition -------------------
	  	   ELSIF SW(17 downto 15)  = "010" THEN   
			      LEDR(17 downto 15) <= "010";
				-- DAC is connected to a NOC output
	         DA <= nco_sin_out + OFF_set;  
            DB <= nco_sin_out + OFF_set;
				
		-- 4th Condition -------------------
		-- Connect loop back cable i.e 
		-- DAC_A o/p -> ADC_A i/p
	   -- ADC_A digital o/p --> DAC_B	
	  	   ELSIF SW(17 downto 15)  = "100" THEN   
			      LEDR(17 downto 15) <= "100";
				   -- DAC_A is connected to a NOC output
				   DA <= nco_sin_out + OFF_set;  
               DB <= ADA_D;
				-------------------------------------
		-- 5th Condition -------------------
	  	   ELSIF SW(17 downto 15)  = "101" THEN   
			      LEDR(17 downto 15) <= "101";
				   -- FSK Modulation of UART output
					if UART_Txout = '1' then
				      Freq_set <= Freq_set_12Mhz;
						DA <= nco_sin_out + OFF_set; 
					else 
				      Freq_set <= Freq_set_6Mhz;
						DA <= nco_sin_out + OFF_set; 
					end if;	
				   -------------------------------
		-- 6th Condition -------------------
	  	   ELSIF SW(17 downto 15)  = "110" THEN   
			      LEDR(17 downto 15) <= "110";
				   -- DAC is connected to a NOC output
	            DA <= nco_sin_out + OFF_set;  
               DB <= nco_sin_out + OFF_set;
				   -- Sending UART output to RS-232 port 
				   UART_TXD <= UART_Txout; 
		
   END IF;
END PROCESS;			 


END Data_acquisition;



