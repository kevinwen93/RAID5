// $Id: $mg97
// File name:   cache_counter.sv
// Created:     11/30/2015
// Author:      Renjun Zheng
// Lab Section: 337-007
// Version:     1.0  Initial Design Entry
// Description: counter for cache operation

module cache_counter(
	input wire clk,n_rst,cnt_enable,clear,
	input wire [7:0] rollover_val,
	//output wire cache_dump_half,
	output wire rollover_flag,
	output reg [7:0] count_out
);
	//assign cache_dump_half = (count_out < 8'd128) ? 1'b0:1'b1;
	flex_counter2#(8) cache_counter_temp(.clk(clk),.n_rst(n_rst),.clear(clear),.count_enable(cnt_enable),.rollover_val(rollover_val),.count_out(count_out),.rollover_flag(rollover_flag));
endmodule
