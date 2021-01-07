module MIXER_6(

	// 6 24-bit inputs, multiplied with Signed Q4.12 Fixed Point coefficients
	
	// Coefficents are set by the ARM,
	// while audio_# contain ADC samples.
	
	input signed [23:0] audio_a,
	input signed [15:0] coeff_a,
	
	input signed [23:0] audio_b,
	input signed [15:0] coeff_b,
	
	input signed [23:0] audio_c,
	input signed [15:0] coeff_c,
	
	input signed [23:0] audio_d,
	input signed [15:0] coeff_d,
	
	input signed [23:0] audio_e,
	input signed [15:0] coeff_e,
	
	input signed [23:0] audio_f,
	input signed [15:0] coeff_f,
	
	input signed [15:0] output_coeff,
	
	output reg signed [23:0] result,
	output reg overflow
);

// 64-bit holding register

reg signed [63:0] sum_buffer;
reg signed [63:0] result_buffer;

always @(*)
begin

	// Multiply inputs by respective coefficents (Amplify or Attenuate)
	sum_buffer = ((audio_a * coeff_a)
					+ (audio_b * coeff_b)
					+ (audio_c * coeff_c)
					+ (audio_d * coeff_d)
					+ (audio_e * coeff_e)
					+ (audio_f * coeff_f));
	
	// Cut off fractional
	if(sum_buffer[63] == 1'b0) // Number is positive
		sum_buffer = {12'b0, sum_buffer[63:12]};
	else // Number is negative
		sum_buffer = {13'h1FFF, sum_buffer[62:12]};
	
	
	
	// Multiply output by output coefficent
	result_buffer = (sum_buffer * output_coeff);	
	
	// Check for overflow and cap the result if there is
	if(result_buffer[63] == 0 && result_buffer[62:35] != 0)
	begin
		result = 24'h7F_FFFF;
		overflow = 1'b1;
	end
	else if(result_buffer[63] == 1 && result_buffer[62:35] != 28'hFFF_FFFF)
	begin
		result = 24'h80_0000;
		overflow = 1'b1;
	end
	else
	begin
		// Set result
		result = {result_buffer[63], result_buffer[34:12]};
		overflow = 1'b0;
	end
	

end

endmodule
