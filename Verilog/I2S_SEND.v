// DOUT needs to be set on the falling edge of BCK
// LRCK needs to be set on the falling edge of BCK
// audio_buffer can only be changed on right_channel and BCK > 24


module I2S_SEND(
	input CLK_50,
	input CLK_AUDIO, //12.288 mhz
	input nRST,
	input enable,
		
	input [23:0] left_audio_in,
	input [23:0] right_audio_in,
	
	output reg LRCK,
	output reg BCK,
	output reg DOUT
);

reg busy;

wire [23:0] left_audio_buffer;
wire [23:0] right_audio_buffer;

reg [23:0] left_audio_internal;
reg [23:0] right_audio_internal;

reg clk_prescaler;


reg [7:0] bck_counter; 


localparam LEFT_CHANNEL = 1'b1;
localparam RIGHT_CHANNEL = 1'b0;

always @(posedge CLK_AUDIO, negedge nRST)
begin
	if(nRST == 1'b0)
	begin
		// Reset
		left_audio_internal <= 24'b0;
		right_audio_internal <= 24'b0;
	end
	else
	begin
		// Audio clock prescaler
		// 48 khz
		clk_prescaler <= clk_prescaler + 1;
		if(clk_prescaler == 0)
		begin
			BCK <= !BCK;
			if(BCK == 1)
				handle_bck();
		end
		
		// New audio frame
		if(LRCK == RIGHT_CHANNEL)
		begin 
			if(bck_counter == 8'd30)
				busy <= 1'b1;
			else if(bck_counter == 8'd31)
			begin
				left_audio_internal <= left_audio_buffer;
				right_audio_internal <= right_audio_buffer;
			end
			else if(bck_counter >= 8'd23)
				busy <= 1'b0;
		end
	end
end

task handle_bck;
begin
	bck_counter <= bck_counter + 1;
	if(bck_counter == 8'd31)
	begin
		bck_counter <= 0;
		LRCK <= !LRCK;
		if(LRCK == RIGHT_CHANNEL)
			DOUT <= left_audio_internal[23];
		else if(LRCK == LEFT_CHANNEL)
			DOUT <= right_audio_internal[23];
	end
		
	if(bck_counter < 8'd23)
	begin
		if(LRCK == LEFT_CHANNEL)
			DOUT <= left_audio_internal[23 - (bck_counter+1)];
		else if(LRCK == RIGHT_CHANNEL)
			DOUT <= right_audio_internal[23 - (bck_counter+1)];
	end
	else if(bck_counter >= 8'd23 && bck_counter != 8'd31)
	begin
		DOUT <= 1'b0;
	end
end
endtask

SF_AUDIO_BUFFER buffer(
								.CLK					(CLK_50), 
								.nRST					(nRST), 
								
								.left_audio_in		(left_audio_in), 
								.right_audio_in	(right_audio_in), 
							  
								.hold_output		(busy), 
							  
								.left_audio_out	(left_audio_buffer), 
								.right_audio_out	(right_audio_buffer)
);

endmodule
