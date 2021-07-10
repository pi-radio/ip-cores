
`timescale 1 ns / 1 ps

	module modulator_v1_0_S00_AXIS #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line

		// AXI4Stream sink: Data Width
		parameter integer C_S_AXIS_TDATA_WIDTH	= 32,
		parameter integer FIFO_SIZE	= 16,
    parameter integer  BIT_DEPTH = 10
	)
	(
		// Users to add ports here

		// User ports ends
		// Do not modify the ports beyond this line

		// AXI4Stream sink: Clock
		input wire  S_AXIS_ACLK,
		// AXI4Stream sink: Reset
		input wire  S_AXIS_ARESETN,
		// Ready to accept data in
		output wire  S_AXIS_TREADY,
		// Data in
		input wire [C_S_AXIS_TDATA_WIDTH-1 : 0] S_AXIS_TDATA,
		// Byte qualifier
		input wire [(C_S_AXIS_TDATA_WIDTH/8)-1 : 0] S_AXIS_TSTRB,
		// Indicates boundary of last packet
		input wire  S_AXIS_TLAST,
		// Data is in valid
		input wire  S_AXIS_TVALID,
		output wire [31 : 0 ] data
	);
	
	(* dont_touch = "true"*) reg [10 : 0] counter = 0;
	(* dont_touch = "true"*) wire enable;
	
	assign enable = (counter < 16);
	
	assign S_AXIS_TREADY = enable;
	
	always @(posedge S_AXIS_ACLK) begin
	   if(!S_AXIS_ARESETN) begin
	       counter <= 0;
	   end
	   else begin
	       counter = counter + 1;
	   end
	end

	endmodule
