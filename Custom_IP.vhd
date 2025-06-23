library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity Custom_IP is
port (
	
	IP_clk    : in std_logic;
	IP_nReset : in std_logic := '1';

	-- Avalon slave with registers component
	IP_address_reg     : in std_logic_vector(2 downto 0) := "000";
	IP_write_reg       : in std_logic := '0';
	IP_read_reg        : in std_logic := '0';
	IP_writedata_reg   : in std_logic_vector(31 downto 0) := (others => '0');
	IP_readdata_reg    : out std_logic_vector(31 downto 0) := (others => '0');

	-- Avalon master with DMA
	IP_address_Master      : out std_logic_vector(31 downto 0) := (others => '0');
	IP_Burst_Count_Master : out std_logic_vector(6 downto 0) := (others => '0');
	IP_read_Master          : out std_logic := '0';
	IP_readdata_Master      : in std_logic_vector(31 downto 0) := (others => '0');
	IP_waitrequest_Master  : in std_logic := '1';
	IP_readdatavalid_Master : in std_logic := '0';


	-- GPIO pins
	IP_LCD_ON_GPIO        : out std_logic := '0';
	IP_Reset_N_GPIO         : out std_logic := '1';
	IP_R_S_GPIO           : out std_logic := '0';
 	IP_WR_N_GPIO           : out std_logic := '1';
 	IP_RD_N_GPIO           : out std_logic := '1';
 	IP_Data_GPIO     : out std_logic_vector (15 downto 0) := (others => '0')

);
end Custom_IP;

architecture arc of Custom_IP is

-- registers with LCD controller 
signal 	IP_frame_end       : std_logic := '0';
signal	IP_LCD_Init         : std_logic_vector (2 downto 0) := "010"; --removed CS bit 
signal	IP_R_S   : std_logic:= '0';
signal	IP_Data      : std_logic_vector (15 downto 0) := (others => '0');
signal  IP_Change_LCD     	 : std_logic := '0';

-- registers with Master Controller 
signal IP_Adrs_Src      : std_logic_vector(31 downto 0) := (others => '0');
signal IP_Data_Length        : std_logic_vector(15 downto 0) := (others => '0');
signal IP_Burst_Cnt        : std_logic_vector(6 downto 0) := (others => '0');
signal IP_Master_Begin         : std_logic := '0';
signal IP_frame_end_M      : std_logic := '0';   

-- FIFO with Master Controller
signal IP_FIFO_Clr               : std_logic := '0';
signal IP_WrFIFO            : std_logic := '0';
signal IP_WrData            : std_logic_vector (31 downto 0) := (others => '0');
signal IP_FIFO_Full               : std_logic := '0';
signal IP_FIFO_used             : std_logic_vector (7 downto 0) := (others => '0');

-- FIFO with LCD Controller
signal IP_RdFIFO            : std_logic := '0';
signal IP_RdData          : std_logic_vector (15 downto 0) := (others => '0');
signal IP_FIFO_Empty              : std_logic := '1';



component registers is
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
end component;

component MasterController is
port(

	DMA_clk    : in std_logic;
	DMA_nReset : in std_logic := '1';

	-- Internal interface (i.e. Avalon Master).
	DMA_Ads_Src       : out std_logic_vector(31 downto 0) := (others => '0');
	DMA_Burst_Cnt_Bus : out std_logic_vector(6 downto 0) := (others => '0');
	DMA_read          : out std_logic := '0';
	DMA_Read_Data      : in std_logic_vector(31 downto 0) := (others => '0');
	DMA_Wait_Request   : in std_logic := '1'; 
	DMA_Read_Data_Valid : in std_logic := '0'; 

	-- Interface with Registers component
	DMA_Start_Address      : in std_logic_vector(31 downto 0) := (others => '0');
	DMA_Data_Length        : in std_logic_vector(15 downto 0) := (others => '0');
	DMA_Burst_Cnt_Signal : in std_logic_vector(6 downto 0) := (others => '0');
	DMA_Master_Begin          : in std_logic := '0'; 
	DMA_LCD_ON             : in std_logic := '0'; 
	DMA_Frame_End_M          : out std_logic := '0';


	-- Interface with FIFO
	DMA_FIFO_clr               : out std_logic := '0';
	DMA_Wr_FIFO            : out std_logic := '0';
	DMA_Wr_Data            : out std_logic_vector (31 downto 0) := (others => '0');
	DMA_FIFO_FULL               : in std_logic := '0';
	DMA_usedw              : in std_logic_vector (7 downto 0) := (others => '0')
 
);
end component;

component LCDController is
port(

	LCD_clk    : in std_logic;
	LCD_nReset : in std_logic := '1';

	-- Interface with Registers component
	LCD_Frame_End        : out std_logic := '0';
	LCD_LCD_INIT          : in std_logic_vector (2 downto 0) := "010"; 
	LCD_Command_Or_Data    : in std_logic := '0';
	LCD_Data_From_Reg	       : in std_logic_vector (15 downto 0) := (others => '0');	
	LCD_Change     		   : in std_logic := '0';

	-- Interface with FIFO
	LCD_Rd_FIFO            : out std_logic := '0';
	LCD_Read_Data          : in std_logic_vector (15 downto 0) := (others => '0');
	LCD_FIFO_Empty              : in std_logic := '1';

	-- Interface with GPIO pins
	LCD_ON_GPIO        : out std_logic := '0';
	Reset_N_GPIO         : out std_logic := '1';
	R_S_GPIO           : out std_logic := '0';
 	WRX_GPIO           : out std_logic := '1';
 	RDX_GPIO           : out std_logic := '1';
 	Data_Line_GPIO     : out std_logic_vector (15 downto 0) := (others => '0');
	
	-- Counter test
	counter : out std_logic_vector (31 downto 0) := (others => '0')
);
end component;

component FIFO IS
	port
	(
		aclr		: IN STD_LOGIC  := '0';
		data		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		rdclk		: IN STD_LOGIC ;
		rdreq		: IN STD_LOGIC ;
		wrclk		: IN STD_LOGIC ;
		wrreq		: IN STD_LOGIC ;
		q		    : OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
		rdempty		: OUT STD_LOGIC ;
		wrfull		: OUT STD_LOGIC ;
		wrusedw		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);

END component;

begin

-- instantiate the components 
registers_component: registers
    port map(clk => IP_clk, 
    		 nReset => IP_nReset, 
    		 address => IP_address_reg, 
    		 write  => IP_write_reg, 
    		 read => IP_read_reg, 
    		 writedata => IP_writedata_reg, 
    		 readdata  => IP_readdata_reg, 
    		 frame_end =>IP_frame_end, 
    		 LCD_Init => IP_LCD_Init, 
		 Change_LCD => IP_Change_LCD,
    		 R_S => IP_R_S, 
    		 Data  => IP_Data,
    		 Adrs_Src => IP_Adrs_Src, 
    		 Data_Length => IP_Data_Length, 
    		 Burst_Cnt =>IP_Burst_Cnt,
		 Master_Begin => IP_Master_Begin,
		 frame_end_M=> IP_frame_end_M
    		 );

MasterController_comp: MasterController
port map(DMA_clk => IP_clk, 
	DMA_nReset => IP_nReset, 
	DMA_Ads_Src => IP_address_Master, 
	DMA_Burst_Cnt_Bus => IP_Burst_Count_Master, 
	DMA_read => IP_read_Master, 
	DMA_Read_Data => IP_readdata_Master, 
	DMA_Wait_Request => IP_waitrequest_Master, 
	DMA_Read_Data_Valid => IP_readdatavalid_Master, 
	DMA_Start_Address => IP_Adrs_Src,
	DMA_Data_Length => IP_Data_Length, 
	DMA_Burst_Cnt_Signal => IP_Burst_Cnt, 
	DMA_Master_Begin => IP_Master_Begin, 
	DMA_LCD_ON => IP_LCD_Init(0),
	DMA_Frame_End_M => IP_frame_end_M,
	DMA_FIFO_clr => IP_FIFO_Clr,
	DMA_Wr_FIFO => IP_WrFIFO, 
	DMA_Wr_Data => IP_WrData, 
	DMA_FIFO_FULL => IP_FIFO_Full, 
	DMA_usedw => IP_FIFO_used);

LCDController_comp: LCDController
port map(LCD_clk => IP_clk, 
		 LCD_nReset => IP_nReset, 
		 LCD_Frame_End => IP_frame_end,
		 LCD_LCD_INIT => IP_LCD_Init, 
		 LCD_Command_Or_Data => IP_R_S, 
		 LCD_Data_From_Reg => IP_Data, 
		 LCD_Change => IP_Change_LCD,
		 LCD_Rd_FIFO => IP_RdFIFO, 
		 LCD_Read_Data => IP_RdData, 
		 LCD_FIFO_Empty => IP_FIFO_Empty, 
		 LCD_ON_GPIO => IP_LCD_ON_GPIO, 
		 Reset_N_GPIO => IP_Reset_N_GPIO, 
		 R_S_GPIO => IP_R_S_GPIO, 
		 WRX_GPIO => IP_WR_N_GPIO , 
		 RDX_GPIO => IP_RD_N_GPIO, 
		 Data_Line_GPIO => IP_Data_GPIO);

FIFO_comp : FIFO
port map(aclr => IP_FIFO_Clr,
	data => IP_WrData,
	rdclk => IP_clk,
	rdreq => IP_RdFIFO,
	wrclk => IP_clk,
	wrreq => IP_WrFIFO,
	q => IP_RdData,
	rdempty => IP_FIFO_Empty,
	wrfull => IP_FIFO_Full,		 
	wrusedw => IP_FIFO_used);


end comp;