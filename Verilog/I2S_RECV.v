`timescale 1ns/1ns

// Assume sampling frequency (fs) is 48khz, and system clock
// frequency is 256 * fs (12.288 Mhz).

// BCK must run at minimum 64 times faster than fs.

module I2S_RECV(
	// Connections to inside FPGA
	input IN_SCK,
	output [23:0] left_out,
	output [23:0] right_out,

	
	// Connections to outside FPGA
	output reg BCK,
	output reg LRC = 1'b0,
	input DATA_IN,
	
	// Buffer interface
	input hold_output,
	output busy

);

reg [23:0] left_frame_in;
reg [23:0] right_frame_in;
reg [23:0] left_buffer;
reg [23:0] right_buffer;


reg [7:0] bit_count = 8'b0;


localparam LEFT_CHANNEL = 1'b0;
localparam RIGHT_CHANNEL = 1'b1;

reg [3:0] decimator = 2'b0;

always @(posedge IN_SCK)
begin
	decimator = decimator + 1'b1;
	if(decimator > 1)
	begin
		decimator <= 2'b0;
		BCK <= !BCK;
	end
end

always @(negedge BCK)
begin
	if(bit_count == 0) begin
		LRC = !LRC;
		
	end
end

always @(posedge BCK)
begin
	bit_count <= bit_count + 8'b1;
	
	if(bit_count > 0 && bit_count < 25)
	begin
		// Shift in next bit from DATA_IN
		if(LRC == LEFT_CHANNEL)
			left_frame_in <= {left_frame_in[22:0], DATA_IN};
		else if(LRC == RIGHT_CHANNEL)
			right_frame_in <= {right_frame_in[22:0], DATA_IN};
	end
	
	if(bit_count == 26 && LRC == RIGHT_CHANNEL)
	begin
		// All bits received, send to output
		left_buffer <= left_frame_in;
		right_buffer <= right_frame_in;
		left_frame_in <= 24'b0;
		right_frame_in <= 24'b0;
	end

	
	if(bit_count == 31)
		bit_count <= 0;
		
	
end

ADC_FRAME_BUFFER buffer
(
	.CLK(IN_SCK) ,	// input  CLK_sig
	.nRST(1'b1) ,	// input  nRST_sig
	
	.left_audio_in(left_buffer) ,		// input [23:0] left_audio_in_sig
	.right_audio_in(right_buffer) ,	// input [23:0] right_audio_in_sig
	
	.hold_output(hold_output) ,	// input  hold_output_sig
	.busy(busy) ,						// output  busy_sig
	.left_audio_out(left_out) ,	// output [23:0] left_audio_out_sig
	.right_audio_out(right_out) 	// output [23:0] right_audio_out_sig
);

endmodule
