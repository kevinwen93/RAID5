// $Id: $mg97
// File name:   flex_counter2.sv
// Created:     9/14/2015
// Author:      Renjun Zheng
// Lab Section: 337-007
// Version:     1.0  Initial Design Entry
// Description: scalable counter


module flex_counter2
#(
	parameter NUM_CNT_BITS = 7
)
(
	input wire clk,n_rst,clear,count_enable,
	input wire [(NUM_CNT_BITS - 1):0] rollover_val,
	output wire [(NUM_CNT_BITS - 1):0] count_out,
	output wire rollover_flag
);

reg [(NUM_CNT_BITS - 1):0] count_temp;//current val
reg [(NUM_CNT_BITS - 1):0] count_next;
assign count_out = count_temp;
reg flagtemp, flagnext;
assign rollover_flag = flagtemp;//current flag

always_comb
begin
	if(clear == 1'b1)
	begin
		count_next = 0;
	end
	else if(count_enable == 1'b1 && count_temp == rollover_val)
		count_next = 1;
	else if(count_enable == 1'b1)
		count_next = count_temp + 1;
	else
		count_next = count_temp;
	
	if(clear == 1'b1)
		flagnext = 1'b0;
	else if(count_next == rollover_val)
		flagnext = 1'b1;
	else
		flagnext = 1'b0;
end

always_ff @(posedge clk, negedge n_rst)
begin

	if(n_rst == 1'b0)
	begin
		count_temp <= 0;
		flagtemp <= 0;
	end
	else
	begin
		count_temp <= count_next;
		flagtemp <= flagnext;
	end
end

endmodule
