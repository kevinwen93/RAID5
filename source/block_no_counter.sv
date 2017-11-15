// $Id: $mg97
// File name:   block_no_counter.sv
// Created:     12/8/2015
// Author:      Renjun Zheng
// Lab Section: 337-007
// Version:     1.0  Initial Design Entry
// Description: counter counts current operated block number for clear and restore disk use.

module block_no_counter(
	input wire clk,n_rst,cnt_enable,clear,
	output wire rollover_flag,
	output reg [10:0] count_out
);
	flex_counter2#(11) cache_counter_temp(.clk(clk),.n_rst(n_rst),.clear(clear),.count_enable(cnt_enable),.rollover_val(11'd2000),.count_out(count_out),.rollover_flag(rollover_flag));
endmodule
