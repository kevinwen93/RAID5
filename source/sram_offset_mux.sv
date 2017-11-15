// $Id: $mg97
// File name:   sram_offset_mux.sv
// Created:     12/10/2015
// Author:      Renjun Zheng
// Lab Section: 337-007
// Version:     1.0  Initial Design Entry
// Description: choose the offset for the sram controller

module sram_offset_mux(
	input wire [6:0] cache_out_offset, 
	input wire [6:0] sram_counter_count_out,
	input wire select,
	output wire [6:0] sram_offset
);

assign sram_offset = (select == 1'b1) ? cache_out_offset : sram_counter_count_out;

endmodule
