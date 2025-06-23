-- #############################################################################
-- Ahmet Avcioglu/ Jason Mina
-- Lab 4.0 Master Controller 

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity Master_Controller is
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
end Master_Controller;

architecture comp of Master_Controller is
TYPE MasterFSM IS (Idle,Look_FIFO, Prepare_Read, Get_Data, Check_Frame_Completed);

signal SM: MasterFSM;

-- Signal to hold and increment the start address
signal start_address_incremented : std_logic_vector (31 downto 0) := (others => '0');


begin


-- Controller read from memory.
process(DMA_clk, DMA_nReset)

variable Burst_Counter: integer := 0;
variable Frame_Counter: integer := 0;

begin
if DMA_nReset = '0' then 
	DMA_Ads_Src <=  (others => '0');
	DMA_Burst_Cnt_Bus <= (others => '0');
	DMA_Wr_Data <= (others => '0');
	DMA_Wr_FIFO <= '0';
	DMA_read <= '0';
	DMA_Frame_End_M <= '0';
	
elsif rising_edge(DMA_clk) then
	-- default values if not set by a specific state 
	DMA_Ads_Src <= (others => '0'); 
	DMA_Burst_Cnt_Bus <= (others => '0');  
	DMA_read <= '0';

	case SM is 

		when Idle =>
			if Frame_Counter = 0 then
				if (DMA_LCD_ON = '1' and DMA_Master_Begin = '1') then
					start_address_incremented <= DMA_Start_Address;
					DMA_Frame_End_M <= '0';
					SM <= Look_FIFO;
				else 
					SM <= Idle;
				end if;
				
			else 
				Frame_Counter := 0;
				SM <= Idle;
			end if;

		when Look_FIFO =>
			if DMA_LCD_ON = '1' then
				-- if there is space for one more burst transfer to the FIFO
				-- Compare with 256 - 64  = 192 in binary
				if unsigned(DMA_usedw) <= 192 then
					SM <= Prepare_Read;
				end if;	
			else 
				SM <= Idle;
			end if;

		when Prepare_Read =>
			if DMA_LCD_ON = '1' then 
				DMA_read <= '1';
				DMA_Ads_Src <= start_address_incremented;
				DMA_Burst_Cnt_Bus <= DMA_Burst_Cnt_Signal;

				if DMA_Wait_Request = '0' then
					SM <= Get_Data;
				end if;
			else 

				SM <= Idle;

			end if;

		when Get_Data =>
			if DMA_LCD_ON = '1' then 
				if Burst_Counter < DMA_Burst_Cnt_Signal then
				    if DMA_Read_Data_Valid = '1' then
						DMA_Wr_FIFO <= '1';
						DMA_Wr_Data <= DMA_Read_Data;
						Burst_Counter := (Burst_Counter) + 1;
				    else 
						DMA_Wr_FIFO <= '0';
						DMA_Wr_Data <= "00000000000000000000000000000000";
			        end if;

				else 
					-- increment the address to read from by the value of the burst count 
					start_address_incremented <= std_logic_vector(unsigned(start_address_incremented) + unsigned(DMA_Burst_Cnt_Signal)*4);
					DMA_Wr_FIFO <= '0';
					DMA_Wr_Data <= "00000000000000000000000000000000";
					SM <= Check_Frame_Completed;
				end if;
			else
				SM <= Idle;
			end if;

		when Check_Frame_Completed =>
			if DMA_LCD_ON = '1' then 
				Burst_Counter := 0;
				Frame_Counter := Frame_Counter +1;

				-- Compare with 600 in binary, equivalent to 76800 pixels 
				if Frame_Counter = 600 then
					DMA_Frame_End_M <= '1';
					DMA_Wr_FIFO <= '0';
					DMA_Wr_Data <= "00000000000000000000000000000000";
					SM <= Idle;
				else 
					SM <= Look_FIFO;
				end if;

			else 
				SM <= Idle;
			end if;

	end case;
	end if;

end process;
end comp;