library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_registers2 is
end entity;

architecture test of tb_registers2 is 
	constant clockPeriod 	: time := 20 ns;

	-- signal with Avalon bus
	signal clk  	    	: std_logic := '0';
	signal nReset       	: std_logic := '1';
	
	signal address      	: std_logic_vector(2 downto 0) := "000";
	signal write 		: std_logic :='0';
	signal read		: std_logic :='0';
	signal writedata 	: std_logic_vector (31 downto 0) := (others => '0');
	signal readdata 	: std_logic_vector(31 downto 0) := (others => '0');

	-- signals to LCD controller
	signal frame_end      : std_logic := '0';
	signal LCD_Init        : std_logic_vector(2 downto 0) := "010";
	signal Change_LCD    	    : std_logic := '0';
	signal R_S  : std_logic := '0';
	signal Data     : std_logic_vector (15 downto 0) := (others => '0');

	-- signal to DMA 
	signal Ads_Src     : std_logic_vector(31 downto 0) := (others => '0');
	signal Data_Length       : std_logic_vector(15 downto 0) := (others => '0');
	signal Burst_Cnt       : std_logic_vector(6 downto 0) := (others => '0');
	signal Master_Begin         : std_logic := '0';
	signal frame_end_M     : std_logic := '0';


begin

	comp: entity work.registers  
		port map (clk =>clk, 
			  nReset => nReset,
			  address => address,
			  write=>write, 
			  read=>read, 
			  writedata => writedata,
			  readdata=>readdata, 
			  frame_end => frame_end,
			  LCD_Init => LCD_Init,
			  Change_LCD => Change_LCD,
		          R_S => R_S, 
		          Data => Data,
			  Ads_Src => Ads_Src,
			 Data_Length =>Data_Length, 
			 Burst_Cnt =>Burst_Cnt,
			 Master_Begin =>Master_Begin,
			 frame_end_M =>frame_end_M
			  );
	

	-- Generate clock signal
	clk <= not clk after clockPeriod/2;
	
	process is
	begin    
		nReset <= '0';
		wait until rising_edge(clk);
		wait until rising_edge(clk);
		
		nReset 	<='1';
		wait until rising_edge(clk);


		-- Write to a register
		address   <= "100";
		write   <= '1';
		read <= '0';
		writedata <="01101000101001100101101000011110";
		wait until rising_edge(clk);
		write   <= '0';
		read <= '1';
		wait until rising_edge(clk);
		read <= '0';
		wait until rising_edge(clk);

		-- Write to the command address register 
		address   <= "000";
		write   <= '1';
		read <= '0';
		writedata <="01101000101001100101101000011110";
		wait until rising_edge(clk);
		write   <= '0';
		read <= '1';
		wait until rising_edge(clk);
		read <= '0';
		wait until rising_edge(clk);

		-- Write to the command data register 
		address   <= "001";
		write   <= '1';
		read <= '0';
		writedata <="10101100110010001100101000011000";
		wait until rising_edge(clk);
		write   <= '0';
		read <= '1';
		wait until rising_edge(clk);
		read <= '0';
		wait until rising_edge(clk);

		-- Write to the config LCD register 
		address   <= "010";
		write   <= '1';
		read <= '0';
		writedata <="00000000000000000000000000000111";
		wait until rising_edge(clk);
		write   <= '0';
		read <= '1';
		wait until rising_edge(clk);
		read <= '0';
		wait until rising_edge(clk);		
		
	
		frame_end <= '1';
		wait until rising_edge(clk);	
		address   <= "110";
		write   <= '0';
		read <= '1';
		wait until rising_edge(clk);	
		read <= '0';
		wait until rising_edge(clk);	
		wait;
		
		
	end process;
end architecture;

