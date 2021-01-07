	component ComputerSystem is
		port (
			audio_pll_clk_clk                      : out   std_logic;                                        -- clk
			clk_clk                                : in    std_logic                     := 'X';             -- clk
			clock_bridge_0_in_clk_clk              : in    std_logic                     := 'X';             -- clk
			coefficents_fifo_a2f_out_readdata      : out   std_logic_vector(31 downto 0);                    -- readdata
			coefficents_fifo_a2f_out_read          : in    std_logic                     := 'X';             -- read
			coefficents_fifo_a2f_out_csr_address   : in    std_logic_vector(2 downto 0)  := (others => 'X'); -- address
			coefficents_fifo_a2f_out_csr_read      : in    std_logic                     := 'X';             -- read
			coefficents_fifo_a2f_out_csr_writedata : in    std_logic_vector(31 downto 0) := (others => 'X'); -- writedata
			coefficents_fifo_a2f_out_csr_write     : in    std_logic                     := 'X';             -- write
			coefficents_fifo_a2f_out_csr_readdata  : out   std_logic_vector(31 downto 0);                    -- readdata
			fifo_0_in_writedata                    : in    std_logic_vector(31 downto 0) := (others => 'X'); -- writedata
			fifo_0_in_write                        : in    std_logic                     := 'X';             -- write
			fifo_0_in_csr_address                  : in    std_logic_vector(2 downto 0)  := (others => 'X'); -- address
			fifo_0_in_csr_read                     : in    std_logic                     := 'X';             -- read
			fifo_0_in_csr_writedata                : in    std_logic_vector(31 downto 0) := (others => 'X'); -- writedata
			fifo_0_in_csr_write                    : in    std_logic                     := 'X';             -- write
			fifo_0_in_csr_readdata                 : out   std_logic_vector(31 downto 0);                    -- readdata
			memory_mem_a                           : out   std_logic_vector(14 downto 0);                    -- mem_a
			memory_mem_ba                          : out   std_logic_vector(2 downto 0);                     -- mem_ba
			memory_mem_ck                          : out   std_logic;                                        -- mem_ck
			memory_mem_ck_n                        : out   std_logic;                                        -- mem_ck_n
			memory_mem_cke                         : out   std_logic;                                        -- mem_cke
			memory_mem_cs_n                        : out   std_logic;                                        -- mem_cs_n
			memory_mem_ras_n                       : out   std_logic;                                        -- mem_ras_n
			memory_mem_cas_n                       : out   std_logic;                                        -- mem_cas_n
			memory_mem_we_n                        : out   std_logic;                                        -- mem_we_n
			memory_mem_reset_n                     : out   std_logic;                                        -- mem_reset_n
			memory_mem_dq                          : inout std_logic_vector(31 downto 0) := (others => 'X'); -- mem_dq
			memory_mem_dqs                         : inout std_logic_vector(3 downto 0)  := (others => 'X'); -- mem_dqs
			memory_mem_dqs_n                       : inout std_logic_vector(3 downto 0)  := (others => 'X'); -- mem_dqs_n
			memory_mem_odt                         : out   std_logic;                                        -- mem_odt
			memory_mem_dm                          : out   std_logic_vector(3 downto 0);                     -- mem_dm
			memory_oct_rzqin                       : in    std_logic                     := 'X';             -- oct_rzqin
			enable_output_byte_export              : out   std_logic_vector(7 downto 0);                     -- export
			reset_reset_n                          : in    std_logic                     := 'X'              -- reset_n
		);
	end component ComputerSystem;

	u0 : component ComputerSystem
		port map (
			audio_pll_clk_clk                      => CONNECTED_TO_audio_pll_clk_clk,                      --                audio_pll_clk.clk
			clk_clk                                => CONNECTED_TO_clk_clk,                                --                          clk.clk
			clock_bridge_0_in_clk_clk              => CONNECTED_TO_clock_bridge_0_in_clk_clk,              --        clock_bridge_0_in_clk.clk
			coefficents_fifo_a2f_out_readdata      => CONNECTED_TO_coefficents_fifo_a2f_out_readdata,      --     coefficents_fifo_a2f_out.readdata
			coefficents_fifo_a2f_out_read          => CONNECTED_TO_coefficents_fifo_a2f_out_read,          --                             .read
			coefficents_fifo_a2f_out_csr_address   => CONNECTED_TO_coefficents_fifo_a2f_out_csr_address,   -- coefficents_fifo_a2f_out_csr.address
			coefficents_fifo_a2f_out_csr_read      => CONNECTED_TO_coefficents_fifo_a2f_out_csr_read,      --                             .read
			coefficents_fifo_a2f_out_csr_writedata => CONNECTED_TO_coefficents_fifo_a2f_out_csr_writedata, --                             .writedata
			coefficents_fifo_a2f_out_csr_write     => CONNECTED_TO_coefficents_fifo_a2f_out_csr_write,     --                             .write
			coefficents_fifo_a2f_out_csr_readdata  => CONNECTED_TO_coefficents_fifo_a2f_out_csr_readdata,  --                             .readdata
			fifo_0_in_writedata                    => CONNECTED_TO_fifo_0_in_writedata,                    --                    fifo_0_in.writedata
			fifo_0_in_write                        => CONNECTED_TO_fifo_0_in_write,                        --                             .write
			fifo_0_in_csr_address                  => CONNECTED_TO_fifo_0_in_csr_address,                  --                fifo_0_in_csr.address
			fifo_0_in_csr_read                     => CONNECTED_TO_fifo_0_in_csr_read,                     --                             .read
			fifo_0_in_csr_writedata                => CONNECTED_TO_fifo_0_in_csr_writedata,                --                             .writedata
			fifo_0_in_csr_write                    => CONNECTED_TO_fifo_0_in_csr_write,                    --                             .write
			fifo_0_in_csr_readdata                 => CONNECTED_TO_fifo_0_in_csr_readdata,                 --                             .readdata
			memory_mem_a                           => CONNECTED_TO_memory_mem_a,                           --                       memory.mem_a
			memory_mem_ba                          => CONNECTED_TO_memory_mem_ba,                          --                             .mem_ba
			memory_mem_ck                          => CONNECTED_TO_memory_mem_ck,                          --                             .mem_ck
			memory_mem_ck_n                        => CONNECTED_TO_memory_mem_ck_n,                        --                             .mem_ck_n
			memory_mem_cke                         => CONNECTED_TO_memory_mem_cke,                         --                             .mem_cke
			memory_mem_cs_n                        => CONNECTED_TO_memory_mem_cs_n,                        --                             .mem_cs_n
			memory_mem_ras_n                       => CONNECTED_TO_memory_mem_ras_n,                       --                             .mem_ras_n
			memory_mem_cas_n                       => CONNECTED_TO_memory_mem_cas_n,                       --                             .mem_cas_n
			memory_mem_we_n                        => CONNECTED_TO_memory_mem_we_n,                        --                             .mem_we_n
			memory_mem_reset_n                     => CONNECTED_TO_memory_mem_reset_n,                     --                             .mem_reset_n
			memory_mem_dq                          => CONNECTED_TO_memory_mem_dq,                          --                             .mem_dq
			memory_mem_dqs                         => CONNECTED_TO_memory_mem_dqs,                         --                             .mem_dqs
			memory_mem_dqs_n                       => CONNECTED_TO_memory_mem_dqs_n,                       --                             .mem_dqs_n
			memory_mem_odt                         => CONNECTED_TO_memory_mem_odt,                         --                             .mem_odt
			memory_mem_dm                          => CONNECTED_TO_memory_mem_dm,                          --                             .mem_dm
			memory_oct_rzqin                       => CONNECTED_TO_memory_oct_rzqin,                       --                             .oct_rzqin
			enable_output_byte_export              => CONNECTED_TO_enable_output_byte_export,              --           enable_output_byte.export
			reset_reset_n                          => CONNECTED_TO_reset_reset_n                           --                        reset.reset_n
		);

