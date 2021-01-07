//--------------------------------------------------------------------------//
// Title:        de0_nano_soc_baseline.v                                       //
// Rev:          Rev 0.1                                                    //
// Last Revised: 09/14/2015                                                 //
//--------------------------------------------------------------------------//
// Description: Baseline design file contains DE0 Nano SoC    				 //
//              Board pins and I/O Standards.                               //
//--------------------------------------------------------------------------////
//`define enable_ADC
//`define enable_ARDUINO
`define enable_GPIO0
`define enable_GPIO1
`define enable_HPS

module de0_nano_soc_baseline(


	//////////// CLOCK //////////
	input 		          		CLOCK_50,
	input 		          		CLOCK2_50,
	input 		          		CLOCK3_50,

`ifdef enable_ADC
	//////////// ADC //////////
	/* 3.3-V LVTTL */
	output		          		ADC_CONVST,
	output		          		ADC_SCLK,
	output		          		ADC_SDI,
	input 		          		ADC_SDO,
`endif
	
`ifdef enable_ARDUINO
	//////////// ARDUINO ////////////
	/* 3.3-V LVTTL */
	inout					[15:0]	ARDUINO_IO,
	inout								ARDUINO_RESET_N,
`endif
	
`ifdef enable_GPIO0
	//////////// GPIO 0 ////////////
	/* 3.3-V LVTTL */
	inout				[35:0]		GPIO_0,
`endif

`ifdef enable_GPIO1	
	//////////// GPIO 1 ////////////
	/* 3.3-V LVTTL */
	inout				[35:0]		GPIO_1,
`endif

`ifdef enable_HPS
	//////////// HPS //////////
	/* 3.3-V LVTTL */
	inout 		          		HPS_CONV_USB_N,
	
	/* SSTL-15 Class I */
	output		    [14:0]		HPS_DDR3_ADDR,
	output		     [2:0]		HPS_DDR3_BA,
	output		          		HPS_DDR3_CAS_N,
	output		          		HPS_DDR3_CKE,
	output		          		HPS_DDR3_CS_N,
	output		     [3:0]		HPS_DDR3_DM,
	inout 		    [31:0]		HPS_DDR3_DQ,
	output		          		HPS_DDR3_ODT,
	output		          		HPS_DDR3_RAS_N,
	output		          		HPS_DDR3_RESET_N,
	input 		          		HPS_DDR3_RZQ,
	output		          		HPS_DDR3_WE_N,
	/* DIFFERENTIAL 1.5-V SSTL CLASS I */
	output		          		HPS_DDR3_CK_N,
	output		          		HPS_DDR3_CK_P,
	inout 		     [3:0]		HPS_DDR3_DQS_N,
	inout 		     [3:0]		HPS_DDR3_DQS_P,
	
	/* 3.3-V LVTTL */
	output		          		HPS_ENET_GTX_CLK,
	inout 		          		HPS_ENET_INT_N,
	output		          		HPS_ENET_MDC,
	inout 		          		HPS_ENET_MDIO,
	input 		          		HPS_ENET_RX_CLK,
	input 		     [3:0]		HPS_ENET_RX_DATA,
	input 		          		HPS_ENET_RX_DV,
	output		     [3:0]		HPS_ENET_TX_DATA,
	output		          		HPS_ENET_TX_EN,
	inout 		          		HPS_GSENSOR_INT,
	inout 		          		HPS_I2C0_SCLK,
	inout 		          		HPS_I2C0_SDAT,
	inout 		          		HPS_I2C1_SCLK,
	inout 		          		HPS_I2C1_SDAT,
	inout 		          		HPS_KEY,
	inout 		          		HPS_LED,
	inout 		          		HPS_LTC_GPIO,
	output		          		HPS_SD_CLK,
	inout 		          		HPS_SD_CMD,
	inout 		     [3:0]		HPS_SD_DATA,
	output		          		HPS_SPIM_CLK,
	input 		          		HPS_SPIM_MISO,
	output		          		HPS_SPIM_MOSI,
	inout 		          		HPS_SPIM_SS,
	input 		          		HPS_UART_RX,
	output		          		HPS_UART_TX,
	input 		          		HPS_USB_CLKOUT,
	inout 		     [7:0]		HPS_USB_DATA,
	input 		          		HPS_USB_DIR,
	input 		          		HPS_USB_NXT,
	output		          		HPS_USB_STP,
`endif
	
	//////////// KEY ////////////
	/* 3.3-V LVTTL */
	input				[1:0]			KEY,
	
	//////////// LED ////////////
	/* 3.3-V LVTTL */
	output 			[7:0]			LED,
	
	//////////// SW ////////////
	/* 3.3-V LVTTL */
	input				[3:0]			SW

);

// LED[0] - left mixer overflow
// LED[1] - right mixer overflow
// LED[2] - Command received from ARM

//=======================================================
//  REG/WIRE declarations
//=======================================================

wire AUDIO_SYS_CLK;
wire hps_fpga_reset_n; // I should use this, one day I will use this.
wire take_audio_sample;

reg [7:0] SYS_STATE = 8'b0;
localparam S_IDLE = 8'd0;
localparam S_HOLD = 8'd1;
localparam S_GET_FRAMES = 8'd2;
localparam S_COEFF_SELECT = 8'd3;
localparam S_AUDIO_FRAME_OUT = 8'd4;
localparam S_CLEANUP = 8'd5;

////////////////
// Output Addresses (read addresses):
//
localparam DAC_ALPHA_ID = 		4'h0;
localparam DAC_BETA_ID = 		4'h1;
localparam BLUETOOTH_OUT = 4'h2;
localparam ETHERNET_OUT = 	4'h3;

reg [3:0] output_i = 4'b0; 

// NOTE: Only DAC_ALPHA & DAC_BETA have been implemented as outputs. System supports 6 outputs.
always @(posedge CLOCK_50)
begin
	process_new_coefficents();
	
	case (SYS_STATE)
		S_IDLE : begin
			if(take_audio_sample)
				SYS_STATE <= S_HOLD;
		end
		//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
		S_HOLD : begin
			ADC_BUFFER_HOLD <= 1'b1;
			if(ADC_ALPHA_BUFFER_BUSY == 1'b0 && ADC_BETA_BUFFER_BUSY == 1'b0)
				SYS_STATE <= S_GET_FRAMES;
		
		end
		//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
		S_GET_FRAMES : begin
			AUDIO_IN_LEFT[0] <= ADC_ALPHA_LOUT;
			AUDIO_IN_LEFT[1] <= ADC_BETA_LOUT;
			
			AUDIO_IN_RIGHT[0] <= ADC_ALPHA_ROUT;
			AUDIO_IN_RIGHT[1] <= ADC_BETA_ROUT;
			
			ADC_BUFFER_HOLD <= 1'b0;
			
			SYS_STATE <= S_COEFF_SELECT;
			
		end
		//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
		S_COEFF_SELECT : begin
			output_i <= output_i + 4'd1;
			case(output_i)
				4'd0 : mixer_config_id <= DAC_ALPHA_ID;
				4'd1 : mixer_config_id <= DAC_BETA_ID;
			endcase
			SYS_STATE <= S_AUDIO_FRAME_OUT;
		end
		//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
		S_AUDIO_FRAME_OUT : begin
			if(mixer_config_id == DAC_ALPHA_ID)
			begin
				DAC_ALPHA_LIN <= mixer_left_output;
				DAC_ALPHA_RIN <= mixer_right_output;
				
				// Debuging, mixer bypass.
				//DAC_ALPHA_LIN <= AUDIO_IN_LEFT[0]; //=-=-=-=-
				//DAC_ALPHA_RIN <= AUDIO_IN_RIGHT[0]; //=-=-=-=-
				
				SYS_STATE <= S_COEFF_SELECT;
			end
			else if(mixer_config_id == DAC_BETA_ID)
			begin
				DAC_BETA_LIN <= mixer_left_output;
				DAC_BETA_RIN <= mixer_right_output;
				
				// CYCLE END
				SYS_STATE <= S_CLEANUP;
			end
		end
		//=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
		S_CLEANUP : begin
			output_i <= 4'd0;
			SYS_STATE <= S_IDLE;
		
		end
		
	endcase
end


//=======================================================
//  Structural coding
//=======================================================

Audio_Sample_Clock Audio_Sample_Clock_inst
(
	.AUDIO_CLK(AUDIO_SYS_CLK) ,	// input  AUDIO_CLK_sig
	.flag(take_audio_sample) 	// output  flag_sig
);

ComputerSystem u0 (
	
	// Clock & Reset
	.clk_clk                   (CLOCK_50),                   		//                   clk.clk
	.reset_reset_n             (1'b1),             						//                 reset.reset_n
	.enable_output_byte_export (),	

	// PLL Clock Bridge - Connects to FIFO
	.clock_bridge_0_in_clk_clk (CLOCK_50), 							 	// clock_bridge_0_in_clk.clk
	
	// Audio Clock - SCLK (12.288 MHz)
	.audio_pll_clk_clk         (AUDIO_SYS_CLK),

	// FIFO FPGA -> HPS
	.fifo_0_in_writedata       (fpga_to_hps_in_writedata),       	//             fifo_0_in.writedata
	.fifo_0_in_write           (fpga_to_hps_in_write),           	//                      .write
	.fifo_0_in_csr_address     (32'd1),     							 	//         fifo_0_in_csr.address
	.fifo_0_in_csr_read        (1'b1),        						 	//                      .read
	.fifo_0_in_csr_writedata   (),   									 	//                      .writedata
	.fifo_0_in_csr_write       (1'b0),       							 	//                      .write
	.fifo_0_in_csr_readdata    (fpga_to_hps_in_csr_readdata),     	//                      .readdata
	
	// Command FIFO (HPS -> FPGA)
	.coefficents_fifo_a2f_out_readdata      (coeff_command),      	//     coefficents_fifo_a2f_out.readdata
	.coefficents_fifo_a2f_out_read          (coeff_command_read),  //                             .read
	.coefficents_fifo_a2f_out_csr_address   (32'd1),   				// coefficents_fifo_a2f_out_csr.address
	.coefficents_fifo_a2f_out_csr_read      (1'b1),      				//                             .read
	.coefficents_fifo_a2f_out_csr_writedata (1'b0), 					//                             .writedata
	.coefficents_fifo_a2f_out_csr_write     (1'b0),     				//                             .write
	.coefficents_fifo_a2f_out_csr_readdata  (coeff_fifo_status),  	//                             .readdata

	
	//HPS ddr3
	.memory_mem_a                          ( HPS_DDR3_ADDR),                       //                memory.mem_a
	.memory_mem_ba                         ( HPS_DDR3_BA),                         //                .mem_ba
	.memory_mem_ck                         ( HPS_DDR3_CK_P),                       //                .mem_ck
	.memory_mem_ck_n                       ( HPS_DDR3_CK_N),                       //                .mem_ck_n
	.memory_mem_cke                        ( HPS_DDR3_CKE),                        //                .mem_cke
	.memory_mem_cs_n                       ( HPS_DDR3_CS_N),                       //                .mem_cs_n
	.memory_mem_ras_n                      ( HPS_DDR3_RAS_N),                      //                .mem_ras_n
	.memory_mem_cas_n                      ( HPS_DDR3_CAS_N),                      //                .mem_cas_n
	.memory_mem_we_n                       ( HPS_DDR3_WE_N),                       //                .mem_we_n
	.memory_mem_reset_n                    ( HPS_DDR3_RESET_N),                    //                .mem_reset_n
	.memory_mem_dq                         ( HPS_DDR3_DQ),                         //                .mem_dq
	.memory_mem_dqs                        ( HPS_DDR3_DQS_P),                      //                .mem_dqs
	.memory_mem_dqs_n                      ( HPS_DDR3_DQS_N),                      //                .mem_dqs_n
	.memory_mem_odt                        ( HPS_DDR3_ODT),                        //                .mem_odt
	.memory_mem_dm                         ( HPS_DDR3_DM),                         //                .mem_dm
	.memory_oct_rzqin                      ( HPS_DDR3_RZQ)                        //                .oct_rzqin                                  
	
		
);

// Pressing button does not do anything, although is used for debuging when needed.
// DeBounce btn_debouncer (CLOCK_50, 1'b1, !KEY[1], sample_signal);

// Audio clock without the HPS bridge, reduces compilation time from 7:00 minutes to 1:30.
//Audio_Clock u0 (
//	.clk_clk       (CLOCK_50),       //       clk.clk
//	.reset_reset_n (1'b1), //     reset.reset_n
//	.audio_clk_clk (AUDIO_SYS_CLK)  // audio_clk.clk
//);
assign GPIO_0[35] = AUDIO_SYS_CLK;

reg ADC_BUFFER_HOLD;
wire ADC_ALPHA_BUFFER_BUSY;
wire ADC_BETA_BUFFER_BUSY;

wire [23:0] ADC_ALPHA_LOUT;
wire [23:0] ADC_ALPHA_ROUT;
I2S_RECV ADC_ALPHA(
	// Connections inside FPGA
	.IN_SCK		  (AUDIO_SYS_CLK),
	.left_out     (ADC_ALPHA_LOUT), 
	.right_out    (ADC_ALPHA_ROUT),
	
	
	// Connections to the ADC
	.BCK				(GPIO_0[32]),
	.LRC				(GPIO_0[34]),
	.DATA_IN 		(GPIO_0[33]),
	
	// Buffer interface
	.hold_output(ADC_BUFFER_HOLD),
	.busy(ADC_ALPHA_BUFFER_BUSY)
	
);

wire [23:0] ADC_BETA_LOUT;
wire [23:0] ADC_BETA_ROUT;
I2S_RECV ADC_BETA(
	// Connections inside FPGA
	.IN_SCK		  (AUDIO_SYS_CLK),
	.left_out     (ADC_BETA_LOUT), 
	.right_out    (ADC_BETA_ROUT),
	
	
	// Connections to the ADC
	.BCK				(GPIO_0[0]),
	.DATA_IN 		(GPIO_0[1]),
	.LRC				(GPIO_0[2]),
	
	// Buffer interface
	.hold_output(ADC_BUFFER_HOLD),
	.busy(ADC_BETA_BUFFER_BUSY)

);

reg [23:0] DAC_ALPHA_LIN;
reg [23:0] DAC_ALPHA_RIN;
I2S_SEND DAC_ALPHA(
	// Connection inside the FPGA
	.CLK_50(CLOCK_50),
	.CLK_AUDIO(AUDIO_SYS_CLK), //12.288 mhz
	.nRST(1'b1),
	.enable(1'b1),
		
	.left_audio_in(DAC_ALPHA_LIN),
	.right_audio_in(DAC_ALPHA_RIN),
	
	// Connections to the DAC
	.LRCK(GPIO_1[12]),
	.BCK(GPIO_1[10]),
	.DOUT(GPIO_1[11])
);

reg [23:0] DAC_BETA_LIN;
reg [23:0] DAC_BETA_RIN;
I2S_SEND DAC_BETA(
	// Connection inside the FPGA
	.CLK_50(CLOCK_50),
	.CLK_AUDIO(AUDIO_SYS_CLK), //12.288 mhz
	.nRST(1'b1),
	.enable(1'b1),
		
	.left_audio_in(DAC_BETA_LIN),
	.right_audio_in(DAC_BETA_RIN),
	
	// Connections to the DAC
	.LRCK(GPIO_1[33]),
	.BCK(GPIO_1[31]),
	.DOUT(GPIO_1[30])
);

wire [23:0] mixer_left_output;
wire [23:0] mixer_right_output;

wire [15:0] coeff_a_interconnect;
wire [15:0] coeff_b_interconnect;
wire [15:0] coeff_c_interconnect;
wire [15:0] coeff_d_interconnect;
wire [15:0] coeff_e_interconnect;
wire [15:0] coeff_f_interconnect;
wire [15:0] coeff_output_interconnect;

reg [23:0] AUDIO_IN_LEFT  [5:0];
reg [23:0] AUDIO_IN_RIGHT [5:0];

MIXER_6 AUDIO_MIXER_LEFT(
	.audio_a(AUDIO_IN_LEFT[0]) ,				// input [23:0] audio_a_sig
	.coeff_a(coeff_a_interconnect) ,	// input [15:0] coeff_a_sig
	
	.audio_b(AUDIO_IN_LEFT[1]) ,				// input [23:0] audio_b_sig
	.coeff_b(coeff_b_interconnect) ,	// input [15:0] coeff_b_sig
	
	.audio_c(AUDIO_IN_LEFT[2]) ,				// input [23:0] audio_c_sig
	.coeff_c(coeff_c_interconnect) ,	// input [15:0] coeff_c_sig
	
	.audio_d(AUDIO_IN_LEFT[3]) ,				// input [23:0] audio_d_sig
	.coeff_d(coeff_d_interconnect) ,	// input [15:0] coeff_d_sig
	
	.audio_e(AUDIO_IN_LEFT[4]) ,				// input [23:0] audio_e_sig
	.coeff_e(coeff_e_interconnect) ,	// input [15:0] coeff_e_sig
	
	.audio_f(AUDIO_IN_LEFT[5]) ,				// input [23:0] audio_f_sig
	.coeff_f(coeff_f_interconnect) ,	// input [15:0] coeff_f_sig
	
	.output_coeff(coeff_output_interconnect) ,	// input [15:0] output_coeff_sig
	
	.result(mixer_left_output) ,		// output [23:0] result_sig
	.overflow(overflow_sig_left) 			// output  overflow_sig
); 

MIXER_6 AUDIO_MIXER_RIGHT(
	.audio_a(AUDIO_IN_RIGHT[0]) ,				// input [23:0] audio_a_sig
	.coeff_a(coeff_a_interconnect) ,	// input [15:0] coeff_a_sig
	
	.audio_b(AUDIO_IN_RIGHT[1]) ,				// input [23:0] audio_b_sig
	.coeff_b(coeff_b_interconnect) ,	// input [15:0] coeff_b_sig
	
	.audio_c(AUDIO_IN_RIGHT[2]) ,				// input [23:0] audio_c_sig
	.coeff_c(coeff_c_interconnect) ,	// input [15:0] coeff_c_sig
	
	.audio_d(AUDIO_IN_RIGHT[3]) ,				// input [23:0] audio_d_sig
	.coeff_d(coeff_d_interconnect) ,	// input [15:0] coeff_d_sig
	
	.audio_e(AUDIO_IN_RIGHT[4]) ,				// input [23:0] audio_e_sig
	.coeff_e(coeff_e_interconnect) ,	// input [15:0] coeff_e_sig
	
	.audio_f(AUDIO_IN_RIGHT[5]) ,				// input [23:0] audio_f_sig
	.coeff_f(coeff_f_interconnect) ,	// input [15:0] coeff_f_sig
	
	.output_coeff(coeff_output_interconnect) ,	// input [15:0] output_coeff_sig
	
	.result(mixer_right_output) ,		// output [23:0] result_sig
	.overflow(overflow_sig_right) 			// output  overflow_sig
);

// If coefficent for ADC_ALPHA->DAC_ALPHA matches, led should light up
//always @(posedge CLOCK_50)
//begin
//	if(debug_led_wasTriggered)
//		if(coeff_a_interconnect != 16'b0001000000000000)
//		begin
//			debug_led_sig <= 1'b1;
//			debug_led_wasTriggered <= 1'b1;
//		end
//	else
//		debug_led_wasTriggered <= 1'b0;
//		debug_led_sig <= 1'b0;
//	
//
//end



wire overflow_sig_left;
wire overflow_sig_right;

debug_led OVERFLOW_LED_LEFT
(
	.CLK(CLOCK_50) ,					// input  CLK_sig
	.nRST(1'b1) ,						// input  nRST_sig
	.trigger(overflow_sig_left) ,	// input  trigger_sig
	.led(LED[0]) 						// output  led_sig
);
debug_led OVERFLOW_LED_RIGHT
(
	.CLK(CLOCK_50) ,					// input  CLK_sig
	.nRST(1'b1) ,						// input  nRST_sig
	.trigger(overflow_sig_right) ,	// input  trigger_sig
	.led(LED[1]) 						// output  led_sig
);

reg [3:0] mixer_config_id;
MIXER_COEFFICENTS MIXER_COEFFICENTS_inst
(
	.CLK(CLOCK_50) ,	// input  CLK_sig
	.nRST(1'b1) ,		// input  nRST_sig
	
	.latch_input(coeff_latch) ,						// input  latch_input_sig
	.coefficent_input(coeff_value) ,					// input [23:0] coefficent_input_sig
	.input_address(coeff_input_address) ,			// input [3:0] input_address_sig
	.output_address(coeff_output_address) ,		// input [3:0] output_address_sig
	
	.config_id(mixer_config_id) ,						// input [3:0] select_address_sig
	.coeff_a(coeff_a_interconnect) ,					// output [23:0] coeff_a_sig
	.coeff_b(coeff_b_interconnect) ,					// output [23:0] coeff_b_sig
	.coeff_c(coeff_c_interconnect) ,					// output [23:0] coeff_c_sig
	.coeff_d(coeff_d_interconnect) ,					// output [23:0] coeff_d_sig
	.coeff_e(coeff_e_interconnect) ,					// output [23:0] coeff_e_sig
	.coeff_f(coeff_f_interconnect) ,					// output [23:0] coeff_f_sig
	.coeff_output(coeff_output_interconnect) 		// output [23:0] coeff_output_sig
);

wire [31:0] coeff_fifo_status;
wire [31:0] coeff_command;
reg coeff_command_read;
reg coeff_command_waiting;

reg [3:0] coeff_input_address;
reg [3:0] coeff_output_address;
reg [15:0] coeff_value;
reg coeff_latch;

// Read incoming coefficent commands
localparam S_PROC_IDLE = 4'd0;
localparam S_PROC_READ = 4'd1;
localparam S_PROC_PROCESS = 4'd2;
localparam S_PROC_SAVE = 4'd3;
reg [3:0] COM_PROC_STATE = S_PROC_IDLE;


task process_new_coefficents;
begin
	// If coeff command fifo not empty, command is waiting
	if(COM_PROC_STATE == S_PROC_IDLE)
	begin
		coeff_latch <= 1'b0;
		command_processed_sig <= 1'b0;
		if(coeff_fifo_status[1] != 1'b1)
		begin
			coeff_command_read <= 1'b1;
			COM_PROC_STATE <= S_PROC_READ;
		end
	end
	else if(COM_PROC_STATE == S_PROC_READ)
	begin
		coeff_command_read <= 1'b0;
		COM_PROC_STATE <= S_PROC_PROCESS;
	end
	else if(COM_PROC_STATE == S_PROC_PROCESS)
	begin
		coeff_output_address <= coeff_command[31:28];
		coeff_input_address <= coeff_command[27:24];
		coeff_value <= coeff_command[23:8];
		command_processed_sig <= 1'b1;
		coeff_latch <= 1'b1;
		COM_PROC_STATE <= S_PROC_SAVE;
	end
	else if(COM_PROC_STATE == S_PROC_SAVE)
	begin
		
		COM_PROC_STATE <= S_PROC_IDLE;

	end
end
endtask

reg command_processed_sig;
debug_led COMMAND_PROCESSED_LED
(
	.CLK(CLOCK_50) ,							// input  CLK_sig
	.nRST(1'b1) ,								// input  nRST_sig
	.trigger(command_processed_sig) ,	// input  trigger_sig
	.led(LED[2]) 								// output  led_sig
);

endmodule
