// $Id: $mg97
// File name:   parity_bit_generator.sv
// Created:     11/1/2015
// Author:      Renjun Zheng
// Lab Section: 337-007
// Version:     1.0  Initial Design Entry
// Description: 

module parity_gen(
	input wire [31:0] block1,
	input wire [31:0] block2,
	output wire [31:0] result
);

assign result = block1 ^ block2;

endmodule
