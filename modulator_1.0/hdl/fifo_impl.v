`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/08/2021 01:23:50 PM
// Design Name: 
// Module Name: fifo_impl
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


module fifo_impl # (
    parameter integer FIFO_SIZE	= 1024,
    parameter integer C_S_AXIS_TDATA_WIDTH	= 32,
    parameter integer  BIT_DEPTH = 10
    )
    (
    input wire write_req,
//    input wire read_req,
    output wire full,
    output wire empty,
    input wire [C_S_AXIS_TDATA_WIDTH-1 : 0] wdata,
//    output wire [C_S_AXIS_TDATA_WIDTH-1 : 0] rdata,
    input wire clk,
    input wire rst,
    
    output wire [BIT_DEPTH : 0] infifo
    );

    reg [C_S_AXIS_TDATA_WIDTH-1 : 0] fifo [0 : FIFO_SIZE - 1];
    reg [7:0] after_reset_cnt = 0;
    reg [BIT_DEPTH : 0] read_addr = 0, write_addr = 0, in_fifo = 0;
    reg [1:0] mst_exec_state;  
    wire wr_en;

    parameter [1:0] IDLE = 2'h0,        // This is the initial/idle state 
                AFTER_RESET = 2'h1,
                WRITE_FIFO  = 2'h2,
                READ_FIFO   = 2'h3;
                    
    always @(*) begin
        in_fifo =  write_addr - read_addr;
    end
    assign infifo = write_addr;
    assign wr_en = (in_fifo < FIFO_SIZE) ? 1 : 0;
    assign full = wr_en;
    assign empty = (write_addr == read_addr);
    
    always @(posedge clk) 
    begin  
      if (!rst) 
        begin
            write_addr <= 0;
            read_addr <= 0;
        end  
    end
    
    always @(posedge clk) begin
        if (wr_en && write_req) begin
            fifo[write_addr[BIT_DEPTH - 1 : 0]] = wdata;
            write_addr = write_addr + 1;
        end
    end
    
endmodule
