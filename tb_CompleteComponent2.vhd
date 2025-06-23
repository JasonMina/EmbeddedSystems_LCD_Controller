library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_Custom_IP is
end entity;

architecture test of tb_Custom_IP is 
	constant clockPeriod 	: time := 20 ns;

	signal IP_clk     : std_logic := '0';
	signal IP_nReset : std_logic := '1';

	-- Avalon slave with registers component
	signal IP_address_reg     : std_logic_vector(2 downto 0) := "000";
	signal IP_write_reg       : std_logic := '0';
	signal IP_read_reg        : std_logic := '0';
	signal IP_writedata_reg    : std_logic_vector(31 downto 0) := (others => '0');
	signal IP_readdata_reg    : std_logic_vector(31 downto 0) := (others => '0');

	-- Avalon master with DMA
	signal IP_address_Master       : std_logic_vector(31 downto 0) := (others => '0');
	signal IP_Burst_Count_Master : std_logic_vector(6 downto 0) := (others => '0');
	signal IP_read_Master          : std_logic := '0';
	signal IP_readdata_Master      : std_logic_vector(31 downto 0) := (others => '0');
	signal IP_waitrequest_Master   : std_logic := '1';
	signal IP_readdatavalid_Master : std_logic := '0';

	-- GPIO pins
	signal IP_LCD_ON_GPIO        : std_logic := '0';
	signal IP_Reset_N_GPIO        : std_logic := '1';
	signal IP_R_S_GPIO           : std_logic := '0';
 	signal IP_WR_N_GPIO           : std_logic := '0';
 	signal IP_RD_N_GPIO            : std_logic := '0';
 	signal IP_Data_GPIO      : std_logic_vector (15 downto 0) := (others => '0');

begin

	comp: entity work.Custom_IP
		port map (IP_clk , 
				  IP_nReset , 
				  IP_address_reg, 
				  IP_write_reg, 
				  IP_read_reg, 
				  IP_writedata_reg, 
				  IP_readdata_reg,
		          IP_address_Master, 
		          IP_Burst_Count_Master, 
		          IP_read_Master, 
		          IP_readdata_Master, 
		          IP_waitrequest_Master, 
		          IP_readdatavalid_Master, 
		          IP_LCD_ON_GPIO, 
		          IP_Reset_N_GPIO, 
		          IP_R_S_GPIO, 
		          IP_WR_N_GPIO, 
		          IP_RD_N_GPIO,
		          IP_Data_GPIO
		);
	

	-- Generate clock signal
	global_clk <= not global_clk after clockPeriod/2;
	
	process is
	begin    

		  
		IP_writedata_reg <= "00000000000000000000000000000011";
		wait until rising_edge(global_clk);
		IP_address_reg <= "010";
		wait until rising_edge(global_clk);		
		IP_write_reg <= '1';
		wait until rising_edge(global_clk);
		IP_write_reg <= '0';
		wait until rising_edge(global_clk);

				  
		IP_writedata_reg <= "00000000000000000000000000000001";
		wait until rising_edge(global_clk);
		IP_address_reg <= "010";
		wait until rising_edge(global_clk);		
		IP_write_reg <= '1';
		wait until rising_edge(global_clk);
		IP_write_reg <= '0';
		wait until rising_edge(global_clk);

				  
		IP_writedata_reg <= "00000000000000000000000000000011";
		wait until rising_edge(global_clk);
		IP_address_reg <= "010";
		wait until rising_edge(global_clk);		
		IP_write_reg <= '1';
		wait until rising_edge(global_clk);
		IP_write_reg <= '0';
		wait until rising_edge(global_clk);

		IP_writedata_reg <= "00000000000000000000000001000000";
		wait until rising_edge(global_clk);
		IP_address_reg <= "000";
		 		
		IP_write_reg <= '1';
		wait until rising_edge(global_clk);
		wait until rising_edge(global_clk);
	
		IP_write_reg <= '0';
		 


		  
		IP_writedata_reg <= "00101000011111000010100001111100";
		wait until rising_edge(global_clk);
		IP_address_reg <= "001";
		 		
		IP_write_reg <= '1';
		wait until rising_edge(global_clk);
		wait until rising_edge(global_clk);
		wait until rising_edge(global_clk);
		wait until rising_edge(global_clk);
		wait until rising_edge(global_clk);
		wait until rising_edge(global_clk);
		IP_write_reg <= '0';
		 

		  
		IP_writedata_reg <= "10100101101001011000011110000111";
		 
		IP_address_reg <= "001";
		wait until rising_edge(global_clk);		
		IP_write_reg <= '1';
		wait until rising_edge(global_clk);
		wait until rising_edge(global_clk);
		wait until rising_edge(global_clk);
		wait until rising_edge(global_clk);
		IP_write_reg <= '0';
		 

		  
		IP_writedata_reg <= "00101000011111000010100001111100";
		wait until rising_edge(global_clk);
		IP_address_reg <= "001";
		 		
		IP_write_reg <= '1';
		wait until rising_edge(global_clk);
		wait until rising_edge(global_clk);
		wait until rising_edge(global_clk);
		wait until rising_edge(global_clk);
		IP_write_reg <= '0';
		 

		  
		IP_writedata_reg <= "10100101101001011000011110000111";
		wait until rising_edge(global_clk);
		IP_address_reg <= "001";
		 		
		IP_write_reg <= '1';
		wait until rising_edge(global_clk);
		wait until rising_edge(global_clk);
		wait until rising_edge(global_clk);
		wait until rising_edge(global_clk);
		IP_write_reg <= '0';
		 
		wait until rising_edge(global_clk);
		wait until rising_edge(global_clk);
		wait until rising_edge(global_clk);
		wait until rising_edge(global_clk);
		

		  
		IP_writedata_reg <= "00101000011111000010100001111100";
		wait until rising_edge(global_clk);
		IP_address_reg <= "001";
		 		
		IP_write_reg <= '1';
		wait until rising_edge(global_clk);
		wait until rising_edge(global_clk);
		wait until rising_edge(global_clk);
		wait until rising_edge(global_clk);
		IP_write_reg <= '0';
		 


		  
		IP_writedata_reg <= "00000000000000000000000000000011";
		wait until rising_edge(global_clk);
		IP_address_reg <= "011";
		 		
		IP_write_reg <= '1';
		wait until rising_edge(global_clk);
		wait until rising_edge(global_clk);
		wait until rising_edge(global_clk);
		wait until rising_edge(global_clk);
		IP_write_reg <= '0';
		 

		  
		IP_writedata_reg <= "00000000000000000000000001000000";
		wait until rising_edge(global_clk);
		IP_address_reg <= "101";
		wait until rising_edge(global_clk);		
		IP_write_reg <= '1';
		wait until rising_edge(global_clk);
		IP_write_reg <= '0';
		 

		  
		IP_writedata_reg <= "00000000000000000000000000000111";
		wait until rising_edge(global_clk);
		IP_address_reg <= "010";
		wait until rising_edge(global_clk);		
		IP_write_reg <= '1';
		wait until rising_edge(global_clk);
		IP_write_reg <= '0';
		 

		IP_waitrequest_Master <= '0';
		wait until rising_edge(global_clk);
		IP_readdatavalid_Master <= '1';
		wait until rising_edge(global_clk);		


	

		wait;

		
		
	end process;
end architecture;
