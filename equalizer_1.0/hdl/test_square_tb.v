`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/03/2021 11:06:14 AM
// Design Name: 
// Module Name: test_square_tb
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


module test_square_tb(

);
    reg signed [31:0] tmp_i_sq;
    reg signed [31:0] tmp_q_sq;
    function[27 : 0] mag_squared;
        input signed [15 : 0] i;
        input signed [15 : 0] q;
        begin
            tmp_i_sq = i * i;
            tmp_q_sq = q * q;
            mag_squared = (tmp_i_sq >> 15) + (tmp_q_sq >> 15);
        end
    endfunction
    
    reg [15 : 0] out;
    
    initial begin
        out = mag_squared(16'h6000, 16'h6000);
    end
endmodule
