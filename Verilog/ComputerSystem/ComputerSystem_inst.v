	ComputerSystem u0 (
		.audio_pll_clk_clk                      (<connected-to-audio_pll_clk_clk>),                      //                audio_pll_clk.clk
		.clk_clk                                (<connected-to-clk_clk>),                                //                          clk.clk
		.clock_bridge_0_in_clk_clk              (<connected-to-clock_bridge_0_in_clk_clk>),              //        clock_bridge_0_in_clk.clk
		.coefficents_fifo_a2f_out_readdata      (<connected-to-coefficents_fifo_a2f_out_readdata>),      //     coefficents_fifo_a2f_out.readdata
		.coefficents_fifo_a2f_out_read          (<connected-to-coefficents_fifo_a2f_out_read>),          //                             .read
		.coefficents_fifo_a2f_out_csr_address   (<connected-to-coefficents_fifo_a2f_out_csr_address>),   // coefficents_fifo_a2f_out_csr.address
		.coefficents_fifo_a2f_out_csr_read      (<connected-to-coefficents_fifo_a2f_out_csr_read>),      //                             .read
		.coefficents_fifo_a2f_out_csr_writedata (<connected-to-coefficents_fifo_a2f_out_csr_writedata>), //                             .writedata
		.coefficents_fifo_a2f_out_csr_write     (<connected-to-coefficents_fifo_a2f_out_csr_write>),     //                             .write
		.coefficents_fifo_a2f_out_csr_readdata  (<connected-to-coefficents_fifo_a2f_out_csr_readdata>),  //                             .readdata
		.fifo_0_in_writedata                    (<connected-to-fifo_0_in_writedata>),                    //                    fifo_0_in.writedata
		.fifo_0_in_write                        (<connected-to-fifo_0_in_write>),                        //                             .write
		.fifo_0_in_csr_address                  (<connected-to-fifo_0_in_csr_address>),                  //                fifo_0_in_csr.address
		.fifo_0_in_csr_read                     (<connected-to-fifo_0_in_csr_read>),                     //                             .read
		.fifo_0_in_csr_writedata                (<connected-to-fifo_0_in_csr_writedata>),                //                             .writedata
		.fifo_0_in_csr_write                    (<connected-to-fifo_0_in_csr_write>),                    //                             .write
		.fifo_0_in_csr_readdata                 (<connected-to-fifo_0_in_csr_readdata>),                 //                             .readdata
		.memory_mem_a                           (<connected-to-memory_mem_a>),                           //                       memory.mem_a
		.memory_mem_ba                          (<connected-to-memory_mem_ba>),                          //                             .mem_ba
		.memory_mem_ck                          (<connected-to-memory_mem_ck>),                          //                             .mem_ck
		.memory_mem_ck_n                        (<connected-to-memory_mem_ck_n>),                        //                             .mem_ck_n
		.memory_mem_cke                         (<connected-to-memory_mem_cke>),                         //                             .mem_cke
		.memory_mem_cs_n                        (<connected-to-memory_mem_cs_n>),                        //                             .mem_cs_n
		.memory_mem_ras_n                       (<connected-to-memory_mem_ras_n>),                       //                             .mem_ras_n
		.memory_mem_cas_n                       (<connected-to-memory_mem_cas_n>),                       //                             .mem_cas_n
		.memory_mem_we_n                        (<connected-to-memory_mem_we_n>),                        //                             .mem_we_n
		.memory_mem_reset_n                     (<connected-to-memory_mem_reset_n>),                     //                             .mem_reset_n
		.memory_mem_dq                          (<connected-to-memory_mem_dq>),                          //                             .mem_dq
		.memory_mem_dqs                         (<connected-to-memory_mem_dqs>),                         //                             .mem_dqs
		.memory_mem_dqs_n                       (<connected-to-memory_mem_dqs_n>),                       //                             .mem_dqs_n
		.memory_mem_odt                         (<connected-to-memory_mem_odt>),                         //                             .mem_odt
		.memory_mem_dm                          (<connected-to-memory_mem_dm>),                          //                             .mem_dm
		.memory_oct_rzqin                       (<connected-to-memory_oct_rzqin>),                       //                             .oct_rzqin
		.enable_output_byte_export              (<connected-to-enable_output_byte_export>),              //           enable_output_byte.export
		.reset_reset_n                          (<connected-to-reset_reset_n>)                           //                        reset.reset_n
	);

