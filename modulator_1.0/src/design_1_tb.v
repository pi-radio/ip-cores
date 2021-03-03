`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/04/2021 01:00:42 PM
// Design Name: 
// Module Name: design_1_tb
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


module design_1_tb(

    );
  wire [31:0]M00_AXIS_tdata;
  wire M00_AXIS_tlast;
  reg M00_AXIS_tready;
  wire [3:0]M00_AXIS_tstrb;
  wire M00_AXIS_tvalid;
  reg [31:0]S00_AXIS_tdata;
  reg S00_AXIS_tlast;
  wire S00_AXIS_tready;
  reg [3:0]S00_AXIS_tstrb;
  reg S00_AXIS_tvalid;
  reg m00_axis_aclk = 0;
  reg m00_axis_aresetn;
    
   initial begin
        M00_AXIS_tready <= 0;
        #20 M00_AXIS_tready <= 1;
        #1000 $finish;
   end
   
   initial begin
        m00_axis_aresetn <= 0;
        #10 m00_axis_aresetn <= 1;
   end
   
   initial begin
    m00_axis_aclk = 0;
    forever #5 m00_axis_aclk = ~m00_axis_aclk;
   end
   
design_1_wrapper dut
   (.M00_AXIS_tdata(M00_AXIS_tdata),
    .M00_AXIS_tlast(M00_AXIS_tlast),
    .M00_AXIS_tready(M00_AXIS_tready),
    .M00_AXIS_tstrb(M00_AXIS_tstrb),
    .M00_AXIS_tvalid(M00_AXIS_tvalid),
    .S00_AXIS_tdata(S00_AXIS_tdata),
    .S00_AXIS_tlast(S00_AXIS_tlast),
    .S00_AXIS_tready(S00_AXIS_tready),
    .S00_AXIS_tstrb(S00_AXIS_tstrb),
    .S00_AXIS_tvalid(S00_AXIS_tvalid),
    .m00_axis_aclk(m00_axis_aclk),
    .m00_axis_aresetn(m00_axis_aresetn));
    
endmodule
