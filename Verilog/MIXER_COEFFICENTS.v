module MIXER_COEFFICENTS(

	input CLK,
	input nRST,
	
	input latch_input,
	input [15:0] coefficent_input,
	input [3:0] input_address,
	input [3:0] output_address,
	
	input [3:0] config_id,

	output [15:0] coeff_a,
	output [15:0] coeff_b,
	output [15:0] coeff_c,
	output [15:0] coeff_d,
	output [15:0] coeff_e,
	output [15:0] coeff_f,
	output [15:0] coeff_output
);

////////////////
// Input addresses:
//
localparam OUTPUT = 			4'b0000; // Not counted as an input
localparam ADC_ALPHA = 		4'b0001;
localparam ADC_BETA = 		4'b0010; // Changing this to 2 (from 3) breaks everything. No idea why.
localparam SIG_GEN_ALPHA = 4'b0011;
localparam SIG_GEN_BETA = 	4'b0100;
localparam ETHERNET_IN = 	4'b0101;
localparam BLUETOOTH_IN = 	4'b0110;

////////////////
// Output Addresses (read addresses):
//
localparam DAC_ALPHA = 		4'b0000;
localparam DAC_BETA = 		4'b0001;
localparam BLUETOOTH_OUT = 4'b0010;
localparam ETHERNET_OUT = 	4'b0011;

localparam num_of_inputs = 6;
localparam num_of_outputs = 4;

reg [15:0] coeff_array [num_of_outputs-1:0][num_of_inputs:0];


integer i;
integer j;

assign coeff_output = coeff_array[config_id][OUTPUT];
assign coeff_a = coeff_array[config_id][ADC_ALPHA];
assign coeff_b = coeff_array[config_id][ADC_BETA];
assign coeff_c = coeff_array[config_id][SIG_GEN_ALPHA];
assign coeff_d = coeff_array[config_id][SIG_GEN_BETA];
assign coeff_e = coeff_array[config_id][ETHERNET_IN];
assign coeff_f = coeff_array[config_id][BLUETOOTH_IN];

always @(posedge CLK)
begin
	
	if(~nRST)
	begin
		// RESET - clear all  stored coefficents
		for(i=0; i < num_of_outputs; i=i+1) begin
			for(j=0; j < num_of_inputs; j=j+1) begin
				coeff_array[i][j] <= 16'b0; // Reset Array
			end
		end
				
		
	end
	else
	begin
		if(latch_input == 1'b1)
		begin
			// Latch the input into storage
			// input_address 0x0 = output coefficent
			coeff_array[output_address][input_address] <= coefficent_input;
		end
	end
end

endmodule
