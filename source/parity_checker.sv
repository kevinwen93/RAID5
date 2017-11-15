// $Id: $mg97
// File name:   parity_bit_checker.sv
// Created:     11/3/2015
// Author:      Renjun Zheng
// Lab Section: 337-007
// Version:     1.0  Initial Design Entry
// Description: check if parity bit is valid

module parity_checker(
	input wire [31:0] input1,
	input wire [31:0] input2,
	input wire [31:0] input3,
	output wire valid // 1 stands for valid, 0 stands for non valid parity
);
	// no need to check which one is parity disk

	/*
	wire [31:0] block1, block2, temp;
	
	//assign block1 = (paritydisk == 2'b00) ? input2: ((paritydisk == 2'b01) ? input1: input1);
	//assign block2 = (paritydisk == 2'b00) ? input3: ((paritydisk == 2'b01) ? input3: input2);

	assign block1 = (paritydisk == 2'b00) ? input2 : input1;
	assign block2 = (paritydisk == 2'b10) ? input2 : input3;

	generator parity_bit_generator(.block1(block1),.block2(block2),.result(temp));

	assign valid = (enable == 1'b1) ? ((paritydisk == 2'b00 && input1 == temp) ? 1 : ((paritydisk == 2'b01 && input2 == temp) ? 1 : ((paritydisk == 2'b10 && input3 == temp) ? 1 : 0))): 1;*/
	wire [31:0] temp;
	parity_gen gen(.block1(input1),.block2(input2),.result(temp));
	assign valid = (temp == input3);
endmodule
