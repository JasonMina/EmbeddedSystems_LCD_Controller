
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity registers is
port(
	clk    : in std_logic;
	nReset : in std_logic := '1';

	address     : in std_logic_vector(2 downto 0) := "000";
	write       : in std_logic := '0';
	read        : in std_logic := '0';
	writedata   : in std_logic_vector(31 downto 0) := (others => '0');
	readdata    : out std_logic_vector(31 downto 0):= (others => '0');

	
	Ads_Src     : out std_logic_vector(31 downto 0) := (others => '0');
	Data_Length        : out std_logic_vector(15 downto 0) := (others => '0');
	Burst_Cnt        : out std_logic_vector(6 downto 0) := (others => '0');
	frame_end_M      : in std_logic := '0'
	Master_Begin          : out std_logic := '0';
	

	LCD_Init          : out std_logic_vector (2 downto 0) := "010";
	frame_end        : in std_logic := '0';
	Change_LCD    	   : out std_logic := '0'; 
	Data       : out std_logic_vector (15 downto 0) := (others => '0');
	R_S    : out std_logic := '0';
	


);
end registers;

architecture arc of registers is

signal iReg_Cmd_Adrs  : std_logic_vector(15 downto 0) := (others => '0');
signal iReg_Cmd_Data     : std_logic_vector(15 downto 0) := (others => '0');   
signal iReg_Ads_Src    : std_logic_vector(31 downto 0);
signal iReg_Data_Length          : std_logic_vector(15 downto 0);	
signal iReg_Burst_Cnt      : std_logic_vector(6 downto 0);
signal iReg_LCD_Init       : std_logic_vector(3 downto 0) := "0010";	
signal iReg_DMA_Done       : std_logic := '0';
signal iReg_LCD_Done       : std_logic := '0';



begin

-- Avalon slave write to registers.
process(clk, nReset)
begin
if nReset = '0' then
	iReg_Cmd_Adrs  <= (others => '0');
	iReg_Cmd_Data     <= (others => '0');
	iReg_Ads_Src    <= (others => '0');
	iReg_Data_Length	   	   <= (others => '0');
	iReg_Burst_Cnt      <= (others => '0');
	iReg_LCD_Init       <= "0010";
elsif rising_edge(clk) then
	if write = '1' then
		case address is 

			when "000"  => iReg_Cmd_Adrs        <= writedata(15 downto 0); iReg_LCD_Init(3) <= '0';
			when "001"  => iReg_Cmd_Data           <= writedata(15 downto 0); iReg_LCD_Init(3) <= '1';
			when "010"  => iReg_LCD_Init(2 downto 0) <= writedata(2 downto 0);
			when "011"  => iReg_Ads_Src          <= writedata; 
			when "100"  => iReg_Data_Length                <= writedata(15 downto 0); 
			when "101"  => iReg_Burst_Cnt            <= writedata(6 downto 0); 
			when others => null;
		end case;

	end if;
end if;
end process;

-- Avalon slave read from registers.
process(clk)
begin
if rising_edge(clk) then
	readdata <= (others => '0');
	if read = '1' then
	 	 case address is
	 	 when "000"  => readdata <= "0000000000000000"&iReg_Cmd_Adrs ;
	  	 when "001"  => readdata <= "0000000000000000"&iReg_Cmd_Data;
	  	 when "010"  => readdata <= ("0000000000000000000000000000"&iReg_LCD_Init);
	  	 when "011"  => readdata <= iReg_Ads_Src ;
		 when "100"  => readdata <= ("0000000000000000" & iReg_Data_Length);
		 when "101"  => readdata <= ("0000000000000000000000000" & iReg_Burst_Cnt);
		 when "110"  => readdata <= ("0000000000000000000000000000000" & iReg_LCD_Done);
		 when "111"  => readdata <= ("0000000000000000000000000000000" & iReg_DMA_Done);
	  	 when others => readdata <= "00000000000000000000000000000000";
	 	 end case;
	end if;
end if;
end process;

-- process to pulse the write_LCD signal sent to the LCD Controller
Change_Request: process(clk, nReset)
variable change_cnt : integer := 0; 
begin
	if nReset = '0' then
		Change_LCD <= '0';
		change_cnt := 0;

	elsif rising_edge(clk) then
		
		if write = '1' and (address = "000" or address = "001") then
			if change_cnt = 0 then
				Change_LCD <= '1';
			else 
				Change_LCD <= '0'; 
				change_cnt := 0;
			end if;
			change_cnt := change_cnt + 1;
		else 
			Change_LCD <= '0'; 
			change_cnt := 0;
		end if;
	end if;
end process; 

-- process to pulse the start_DMA signal sent to the DMA Controller
Master_Pulse: process(clk, nReset)
variable count : integer := 0; 
begin
	if nReset = '0' then
		Master_Begin <= '0';
		count := 0;

	elsif rising_edge(clk) then
		
		if write = '1' and address = "010" and writedata(2) = '1' then
			if count = 0 then
				Master_Begin <= '1';
			else 
				Master_Begin <= '0'; 
				count := 0;
			end if;
			count := count + 1;
		else 
			Master_Begin <= '0'; 
			count := 0;
		end if;
	end if;
end process;


Ads_Src <= iReg_Ads_Src;
Data_Length <= iReg_Data_Length;
Burst_Cnt <= iReg_Burst_Cnt;
iReg_LCD_Done <= frame_end;
iReg_DMA_Done <= frame_end_M;

LCD_Init(2 downto 0) <= iReg_LCD_Init(2 downto 0); 
R_S <= '0' when iReg_LCD_Init(3) = '0' else '1';
Data <= iReg_Cmd_Adrs when iReg_LCD_Init(3) = '0' else iReg_Cmd_Data;

end arc; 