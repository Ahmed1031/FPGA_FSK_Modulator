-----------------------------
-- Author:  Ahmed Asim Ghouri
-- Embedded Strings inc 
-- www.emstrings.com
-- Email : support@emstrings.com
------------------------------------
-- Testbench for Hsmc Interface Card
-- Dated : 12/5/2014
-- Testing FSK Modulator


entity Hsmc_card_TB is
end;

LIBRARY ieee ;
USE ieee.std_logic_1164.all ;
USE ieee.numeric_std.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
use IEEE.math_real.all;

architecture Testing_ADC_DAC of Hsmc_card_TB is

  component Hsmc_card_interface_Top  IS
	
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
			   );
  end component;

  signal Clock_50_tb : STD_LOGIC_VECTOR(2 downto 0);
  -- ADC Signals
  signal ADA_D_tb, ADB_D_tb    : STD_LOGIC_VECTOR(13 downto 0); 
  signal ADA_DCO_tb, ADA_OE_tb, ADA_OR_tb, ADA_SPI_CS_tb: STD_LOGIC;
  signal AD_SCLK_tb, AD_SDIO_tb, ADB_DCO_tb, ADB_OE_tb, ADB_OR_tb, ADB_SPI_CS_tb: STD_LOGIC;
  -- Audio Codec 
  signal AIC_BCLK_tb, AIC_DIN_tb, AIC_DOUT_tb, AIC_LRCIN_tb, AIC_LRCOUT_tb, AIC_SPI_CS_tb, AIC_XCLK_tb: STD_LOGIC;
  -- TP Clocks
  signal CLKIN1_tb, CLKOUT0_tb, Uart_cts_tb, Uart_TX_tb, Uart_Rts_tb, Uart_Rx_tb : STD_LOGIC;
  -- DAC Data Buses 
  signal DA_tb, DB_tb  : STD_LOGIC_VECTOR(13 downto 0);
  -- Differential Clocks
  signal FPGA_CLK_A_N_tb, FPGA_CLK_A_P_tb, FPGA_CLK_B_N_tb, FPGA_CLK_B_P_tb : STD_LOGIC;
  -- TP5  
  signal J1_152_tb, XT_IN_N_tb, XT_IN_P_tb : STD_LOGIC;
  -- Switches
  signal SW_tb : STD_LOGIC_VECTOR(17 downto 0); 
  -- KEY INputs
  signal KEY_tb : STD_LOGIC_VECTOR(3 downto 0);
  -- LED's
  signal LEDR_tb  : STD_LOGIC_VECTOR(17 downto 0);
  signal LEDG_tb  : STD_LOGIC_VECTOR(8 downto 0);
--------------------------------------------------	
	
	
begin

-- instantiate the component under test
UUT: Hsmc_card_interface_Top PORT MAP(
                                      OSC_50 => Clock_50_tb,
                                      AD_SCLK => AD_SCLK_tb,
                                      AD_SDIO => AD_SDIO_tb,
												  --
												  ADA_D => ADA_D_tb,
                                      ADA_DCO => ADA_DCO_tb,
                                      ADA_OE => ADA_OE_tb,
												  ADA_OR => ADA_OR_tb,
                                      ADA_SPI_CS => ADA_SPI_CS_tb,
												  --
												  ADB_D => ADB_D_tb,
                                      ADB_DCO => ADB_DCO_tb,
                                      ADB_OE => ADB_OE_tb,
												  ADB_OR => ADB_OR_tb,
                                      ADB_SPI_CS => ADB_SPI_CS_tb,
												  --
                                      AIC_BCLK => AIC_BCLK_tb,
												  AIC_DIN => AIC_DIN_tb,
                                      AIC_DOUT => AIC_DOUT_tb,
												  AIC_LRCIN => AIC_LRCIN_tb,
                                      AIC_LRCOUT => AIC_LRCOUT_tb,
                                      AIC_SPI_CS => AIC_SPI_CS_tb,
												  AIC_XCLK => AIC_XCLK_tb,
												  --
                                      CLKIN1 => CLKIN1_tb,
												  CLKOUT0 => CLKOUT0_tb,
                                      DA => DA_tb,
                                      DB => DB_tb,
												  FPGA_CLK_A_N => FPGA_CLK_A_N_tb,
												  FPGA_CLK_A_P => FPGA_CLK_A_P_tb,
												  FPGA_CLK_B_N => FPGA_CLK_B_N_tb,
												  FPGA_CLK_B_P => FPGA_CLK_B_P_tb,
                                      J1_152 => J1_152_tb,
                                      XT_IN_N => XT_IN_N_tb,
												  XT_IN_P => XT_IN_P_tb,
												  SW => SW_tb,
                                      KEY => KEY_tb,
												  UART_CTS => Uart_cts_tb,
												  UART_TXD => Uart_TX_tb,
												  UART_RTS => Uart_Rts_tb,
												  UART_RXD => Uart_Rx_tb,
                                      LEDG => LEDG_tb,
												  LEDR => LEDR_tb
												  );
-- End Port Mapping ----------------------------------

-- Reseting 
KEY_tb(3) <= '1','0' after 40 ns, '1' after 80 ns;  
-- UART on/off
SW_tb(4) <= '0','1' after 2300 ns;
-- Selecting data source 
SW_tb(17 downto 15) <= "000", "001" after 440 ns,
                              "010" after 780 ns,
									 	"100" after 1080 ns,
										"101" after 1780 ns,
										"110" after 2480 ns;   


-- ADC Data 
-- ADA_D_tb <= "11001001111101","11011001001110" after 200 ns; 
-- ADB_D_tb <= "10001011000001","10001001011001" after 200 ns; 


-- 50Mhz Clock 
Clocking_input : process 
begin 
     wait for 10 ns ;
     Clock_50_tb <= "000";
	  wait for 10 ns ;
	  Clock_50_tb <= "111";
end process;
---------------------------	  

-- ADC Data  
ADC_input : process 
begin 
     if KEY_tb(3) = '0' then 
	     ADA_D_tb <= "11001001111101";
		  ADB_D_tb <= "10001011000001";
		elsif rising_edge(Clock_50_tb(0)) then   
	     ADA_D_tb <= ADA_D_tb + 1;
		  ADB_D_tb <= ADB_D_tb + 1;
		end if ;  
 end process;
---------------------------	 


end Testing_ADC_DAC;