module debug_led(
	input CLK, // 50 MHZ
	input nRST,
	
	input trigger,
	
	output reg led
);

reg [31:0] timer;

always @(posedge CLK)
begin
	if(~nRST)
	begin
		led <= 1'b0;
		timer <= 32'b0;
	end
	else
	begin
		if(trigger)
			timer <= 32'd50_000_000;
			
		if(timer != 32'd0)
		begin
			timer <= timer - 32'd1;
			led <= 1'b1;
		end
		else
			led <= 1'b0;
	
	end
end

endmodule
