// $Id: $mg97
// File name:   sd_data_in_select.sv
// Created:     12/1/2015
// Author:      Renjun Zheng
// Lab Section: 337-007
// Version:     1.0  Initial Design Entry
// Description: select data input for sd card

module sd_data_in_select(
	input wire [1:0] selectid,
	input wire [31:0] sram1,
	input wire [31:0] sram2,
	input wire [31:0] parity,
	input wire [1:0] sram1sd,
	input wire [1:0] sram2sd,
	output wire [31:0] result
);

assign result = (selectid == sram1sd) ? sram1 : ((selectid == sram2sd) ? sram2 : parity);

endmodule
