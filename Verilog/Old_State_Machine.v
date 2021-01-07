	LED[5:0] <= FPGA_TO_HPS_STATE[6:0];
	LED[7] <= ADC_ALPHA_READY;
	
	// Buffer overflow indicator
	if(fifo_overflow_timer > 0)
	begin
		fifo_overflow_timer <= fifo_overflow_timer - 1'b1;
		LED[6] <= 1'b1;
	end
	else
		LED[6] <= 1'b0;
	
	// TAKE SAMPLE BUTTON DEBOUNCER
	//
	
	if(sample_signal == 1'b1 && sample_btn_was_pressed == 1'b0)
	begin
		take_sample_flag <= 1'b1;
		sample_btn_was_pressed <= 1'b1;
	end
	
	if(sample_signal == 1'b0)
		sample_btn_was_pressed <= 1'b0;
	
	// ADC STATE MACHINE
	//
	
	if(FPGA_TO_HPS_STATE == 8'd0)
	begin
		//LED[0] = 1'b1;
		//LED[0] = 1'b1; // Waiting for ADC to be ready
		if(ADC_ALPHA_READY == 1'b1)
		begin
			take_sample_flag <= 1'b0;
			// Audio sample is ready
			FPGA_TO_HPS_STATE <= 8'd1;
			sample_being_taken <= 1'b1;
		end
	end
	
	else if(FPGA_TO_HPS_STATE == 8'd1)
	begin 
		DAC_ALPHA_LIN <= ADC_ALPHA_LIN + ADC_BRAVO_LIN;
		DAC_ALPHA_RIN <= ADC_ALPHA_RIN + ADC_BRAVO_RIN;
		
		
		// Ethernet FIFO Buffer
		if(fpga_to_hps_in_csr_readdata[0])
		begin
			// Buffer is full, so wait for the next sample.
			FPGA_TO_HPS_STATE <= 8'd5;
			fifo_overflow_timer <= 64'd20_000_000;
			//LED[1] <= 1'b1; // FIFO Buffer is full
		end
		else
		begin
			// Submit left channel audio data to buffer, and write
			fpga_to_hps_in_writedata <= {8'b0, ADC_ALPHA_LIN};
			fpga_to_hps_in_write <= 1'b1;
			FPGA_TO_HPS_STATE <= 8'd2;
			//LED[1] <= 1'b0; // FIFO Buffer is not full
		end
	end
	
	else if(FPGA_TO_HPS_STATE == 8'd2)
	begin
		//LED[2] = 1'b1;
		fpga_to_hps_in_write <= 1'b0;
		FPGA_TO_HPS_STATE <= 8'd3;
	end
	
	else if(FPGA_TO_HPS_STATE == 8'd3)
	begin
		//LED[3] = 1'b1;
		// Submit right channel audio data to buffer, and write
		fpga_to_hps_in_writedata <= {8'b0, ADC_ALPHA_RIN};
		fpga_to_hps_in_write <= 1'b1;
		FPGA_TO_HPS_STATE <= 8'd4;
	end
	
	else if(FPGA_TO_HPS_STATE == 8'd4)
	begin
		//LED[4] = 1'b1;
		fpga_to_hps_in_write <= 1'b0;
		FPGA_TO_HPS_STATE <= 8'd5;
	end
	
	else if(FPGA_TO_HPS_STATE == 8'd5)
	begin
		//LED[5] = 1'b1;
		// Wait until AUDIO_DATA_RDY signal is cleared
		if(ADC_ALPHA_READY == 1'b0)
		begin
			FPGA_TO_HPS_STATE <= 8'd0;
			
		end
	end
	
	else if(FPGA_TO_HPS_STATE == 8'd6)
	begin
		if(take_sample_flag == 1'b1)
		begin
			take_sample_flag <= 1'b0;
			//LED <= 8'b0;
			FPGA_TO_HPS_STATE <= 8'd0;
			sample_being_taken <= 1'b0;
		end
	end