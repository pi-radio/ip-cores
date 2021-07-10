`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/02/2021 01:10:48 PM
// Design Name: 
// Module Name: test_equalizer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module test_equalizer(

    );
    
    wire [31 : 0] data [0 : 7];
    assign data[0] = 32'h00003000;
    assign data[1] = 32'h0000b000;
    assign data[2] = 32'h00002000;
    assign data[3] = 32'h00008000;
    assign data[4] = 32'h0000a000;
    assign data[5] = 32'h00003400;
    assign data[6] = 32'h0000c200;
    assign data[7] = 32'h0000aa00;
    
    reg [4 : 0] cnt = 0;
  		 reg  m00_axis_aclk = 0;
		 reg  m00_axis_aresetn;
		 wire  m00_axis_tvalid;
		 wire [32-1 : 0] m00_axis_tdata;
		 wire [(32/8)-1 : 0] m00_axis_tstrb;
		 wire  m00_axis_tlast;
		 wire  m00_axis_tready = 1;

		// Ports of Axi Slave Bus Interface S00_AXIS
		 wire  s00_axis_aclk;
		 wire  s00_axis_aresetn;
		 wire  s00_axis_tready;
		 wire [32-1 : 0] s00_axis_tdata ;
		 wire [(32/8)-1 : 0] s00_axis_tstrb;
		 reg  s00_axis_tlast;
		 wire  s00_axis_tvalid;
		 
		 wire ready1, ready2;

assign s00_axis_tvalid = (cnt < 8) ? 1 : 0;
assign s00_axis_tdata = data[cnt];

 equalizer_v1_0 dut(
     m00_axis_aclk,
     m00_axis_aresetn,
     m00_axis_tvalid,
     m00_axis_tdata,
     m00_axis_tstrb,
     m00_axis_tlast,
     m00_axis_tready,
     m00_axis_aclk,
     m00_axis_aresetn,
     s00_axis_tready,
     s00_axis_tdata,
     s00_axis_tstrb,
     s00_axis_tlast,
     s00_axis_tvalid
 );

 
 initial begin
    forever #5 m00_axis_aclk= ~m00_axis_aclk;
 end
 
 always @(posedge m00_axis_aclk) begin
    if(m00_axis_aresetn && s00_axis_tready) begin
        if(cnt < 8)
            cnt <= cnt + 1;
    end
 end
 
 reg signed [15 : 0] inv;
 
 initial begin 
    m00_axis_aresetn = 0;
    #20 m00_axis_aresetn = 1;
 end
endmodule
