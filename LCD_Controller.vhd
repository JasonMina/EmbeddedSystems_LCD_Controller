-- #############################################################################
-- Jason Mina / Ahmet Avcioglu
-- Lab 4.0 LCD Controller 

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity LCD_Controller is
port(
  
	LCD_clk    : in std_logic;
	LCD_nReset : in std_logic := '1';

	-- Interface with Registers component
	LCD_Frame_End        : out std_logic := '0';
	LCD_LCD_INIT          : in std_logic_vector (2 downto 0) := "010"; 
	LCD_Command_Or_Data    : in std_logic := '0';
	LCD_Data_From_Reg	       : in std_logic_vector (15 downto 0) := (others => '0');	
	--LCD_Mode1_Executed     : in std_logic := '0';
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
end LCD_Controller;

architecture comp of LCD_Controller is
TYPE LCD_FSM IS (Idle, Reading_Data, Wait_1, Flip_Write, Wait_2);

signal SM: LCD_FSM;

begin


-- LCD Controller FSM
process(LCD_clk, LCD_nReset)

-- Counter for the frame
variable LCD_Counter: integer := 0;

begin
counter <= std_logic_vector(to_unsigned(LCD_Counter, counter'length));
if LCD_nReset = '0' then 
    LCD_ON_GPIO        <= '0';
	Reset_N_GPIO         <= '0';
	R_S_GPIO           <= '0';
 	WRX_GPIO           <= '1';
 	RDX_GPIO           <= '1';
 	LCD_Rd_FIFO        <= '0';
 	Data_Line_GPIO     <= (others => '0');
 	SM 				   <= Idle; 
	
elsif rising_edge(LCD_clk) then
	LCD_ON_GPIO <= LCD_LCD_INIT(0);
	Reset_N_GPIO  <= LCD_LCD_INIT(1); 	
	
	-- default values unless set by the specific state
	WRX_GPIO <= '1';
	LCD_Rd_FIFO <= '0';

	case SM is 
		when Idle =>
			WRX_GPIO <= '1';
			Data_Line_GPIO <= (others => '0');
			R_S_GPIO <= '0';

			-- Go to next state if mode 1 or mode 2
			if (LCD_LCD_INIT(2) = '1' or LCD_Change = '1') then
				LCD_Counter := 0;
				SM <= Reading_Data; 
			end if;

		when Reading_Data =>
			-- MODE 2: Reading from FIFO Read_frame = 1
			if LCD_LCD_INIT(2) = '1' then
				WRX_GPIO <= '1';
				-- check if FIFO is not empty
				if LCD_FIFO_Empty = '0' then
					WRX_GPIO <= '0';
					R_S_GPIO <= '1';
					LCD_Rd_FIFO <= '1';
					Data_Line_GPIO <= LCD_Read_Data;
					LCD_Counter := LCD_Counter +1;
					SM <= Wait_1;
				end if;

			-- MODE 1: Reading from registers write_LCD = 1
			else 
				WRX_GPIO <= '0';
				R_S_GPIO <= LCD_Command_Or_Data;
				Data_Line_GPIO <= LCD_Data_From_Reg;
				SM <= Wait_1; 
			end if;

		when Wait_1 =>
			WRX_GPIO <= '0';
			SM <= Flip_Write;

		when Flip_Write => 
			WRX_GPIO <= '1';
			SM <= Wait_2;

		when Wait_2 =>
			WRX_GPIO <= '1';
			-- MODE 1 Reading from registers 
			if LCD_LCD_INIT(2) = '0' then
				SM <= Idle;
				
			else 
			-- Mode 2 Reading from FIFO 
				if LCD_Counter = 76800 then
					LCD_Frame_End <= '1';
					SM <= Idle;
				else 
					SM <= Reading_Data;
				end if;	
			end if;

		end case;
	end if; 
end process;
end comp;