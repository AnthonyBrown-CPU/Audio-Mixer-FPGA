// Copyright (C) 2019  Intel Corporation. All rights reserved.
// Your use of Intel Corporation's design tools, logic functions 
// and other software and tools, and any partner logic 
// functions, and any output files from any of the foregoing 
// (including device programming or simulation files), and any 
// associated documentation or information are expressly subject 
// to the terms and conditions of the Intel Program License 
// Subscription Agreement, the Intel Quartus Prime License Agreement,
// the Intel FPGA IP License Agreement, or other applicable license
// agreement, including, without limitation, that your use is for
// the sole purpose of programming logic devices manufactured by
// Intel and sold by Intel or its authorized distributors.  Please
// refer to the applicable agreement for further details, at
// https://fpgasoftware.intel.com/eula.


// Generated by Quartus Prime Version 19.1 (Build Build 670 09/22/2019)
// Created on Tue Jul 28 15:21:26 2020

I2S_RECV I2S_RECV_inst
(
	.IN_SCK(IN_SCK_sig) ,	// input  IN_SCK_sig
	.left_out(left_out_sig) ,	// output [23:0] left_out_sig
	.right_out(right_out_sig) ,	// output [23:0] right_out_sig
	.BCK(BCK_sig) ,	// output  BCK_sig
	.LRC(LRC_sig) ,	// output  LRC_sig
	.DATA_IN(DATA_IN_sig) ,	// input  DATA_IN_sig
	.hold_output(hold_output_sig) ,	// input  hold_output_sig
	.busy(busy_sig) 	// output  busy_sig
);
