
module ComputerSystem (
	audio_pll_clk_clk,
	clk_clk,
	clock_bridge_0_in_clk_clk,
	coefficents_fifo_a2f_out_readdata,
	coefficents_fifo_a2f_out_read,
	coefficents_fifo_a2f_out_csr_address,
	coefficents_fifo_a2f_out_csr_read,
	coefficents_fifo_a2f_out_csr_writedata,
	coefficents_fifo_a2f_out_csr_write,
	coefficents_fifo_a2f_out_csr_readdata,
	fifo_0_in_writedata,
	fifo_0_in_write,
	fifo_0_in_csr_address,
	fifo_0_in_csr_read,
	fifo_0_in_csr_writedata,
	fifo_0_in_csr_write,
	fifo_0_in_csr_readdata,
	memory_mem_a,
	memory_mem_ba,
	memory_mem_ck,
	memory_mem_ck_n,
	memory_mem_cke,
	memory_mem_cs_n,
	memory_mem_ras_n,
	memory_mem_cas_n,
	memory_mem_we_n,
	memory_mem_reset_n,
	memory_mem_dq,
	memory_mem_dqs,
	memory_mem_dqs_n,
	memory_mem_odt,
	memory_mem_dm,
	memory_oct_rzqin,
	enable_output_byte_export,
	reset_reset_n);	

	output		audio_pll_clk_clk;
	input		clk_clk;
	input		clock_bridge_0_in_clk_clk;
	output	[31:0]	coefficents_fifo_a2f_out_readdata;
	input		coefficents_fifo_a2f_out_read;
	input	[2:0]	coefficents_fifo_a2f_out_csr_address;
	input		coefficents_fifo_a2f_out_csr_read;
	input	[31:0]	coefficents_fifo_a2f_out_csr_writedata;
	input		coefficents_fifo_a2f_out_csr_write;
	output	[31:0]	coefficents_fifo_a2f_out_csr_readdata;
	input	[31:0]	fifo_0_in_writedata;
	input		fifo_0_in_write;
	input	[2:0]	fifo_0_in_csr_address;
	input		fifo_0_in_csr_read;
	input	[31:0]	fifo_0_in_csr_writedata;
	input		fifo_0_in_csr_write;
	output	[31:0]	fifo_0_in_csr_readdata;
	output	[14:0]	memory_mem_a;
	output	[2:0]	memory_mem_ba;
	output		memory_mem_ck;
	output		memory_mem_ck_n;
	output		memory_mem_cke;
	output		memory_mem_cs_n;
	output		memory_mem_ras_n;
	output		memory_mem_cas_n;
	output		memory_mem_we_n;
	output		memory_mem_reset_n;
	inout	[31:0]	memory_mem_dq;
	inout	[3:0]	memory_mem_dqs;
	inout	[3:0]	memory_mem_dqs_n;
	output		memory_mem_odt;
	output	[3:0]	memory_mem_dm;
	input		memory_oct_rzqin;
	output	[7:0]	enable_output_byte_export;
	input		reset_reset_n;
endmodule
