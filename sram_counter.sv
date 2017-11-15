// $Id: $mg97
// File name:   sram_counter.sv
// Created:     12/1/2015
// Author:      Renjun Zheng
// Lab Section: 337-007
// Version:     1.0  Initial Design Entry
// Description: counter for sram operation

module sram_counter(
	input wire clk,n_rst,cnt_enable,clear,
	output wire rollover_flag,
	output reg [6:0] count_out
);
	flex_counter2#(7) cache_counter_temp(.clk(clk),.n_rst(n_rst),.clear(clear),.count_enable(cnt_enable),.rollover_val(7'd128),.count_out(count_out),.rollover_flag(rollover_flag));
endmodule
