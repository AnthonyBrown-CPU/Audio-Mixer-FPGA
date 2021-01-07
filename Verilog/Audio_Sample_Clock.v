// Simple timer for 48kHz audio sample rate.
module Audio_Sample_Clock(
	input AUDIO_CLK,
	
	output reg flag
);

reg [7:0] counter = 8'd0;

always @(posedge AUDIO_CLK)
begin
	counter <= counter + 1;
	if(counter == 8'd0)
		flag <= 1'b1;
	else
		flag <= 1'b0;
end

endmodule
