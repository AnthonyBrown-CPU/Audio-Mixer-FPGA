module ADC_FRAME_BUFFER(
	input CLK,
	input nRST,
	
	input [23:0] left_audio_in,
	input [23:0] right_audio_in,
	
	input hold_output,
	output reg busy,
	
	output reg [23:0] left_audio_out,
	output reg [23:0] right_audio_out

);



always @(posedge CLK, negedge nRST)
begin
	
	// RESET
	//
	if(nRST == 1'b0)
	begin
		left_audio_out <= 24'b0;
		right_audio_out <= 24'b0;
	end
	
	else
	begin
		if(hold_output == 1'b0)
		begin
			left_audio_out <= left_audio_in;
			right_audio_out <= right_audio_in;
			busy <= 1'b1;
		end
		begin
			busy <= 1'b0;
		end
	end
end

endmodule
