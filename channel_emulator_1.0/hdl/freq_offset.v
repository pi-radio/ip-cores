`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/15/2021 01:56:02 PM
// Design Name: 
// Module Name: freq_offset
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


module freq_offset(
    input wire clk,
    input wire areset_n, 
    input wire [15 : 0] phase,
    input wire phase_valid,
    input wire s_valid,
    output wire s_ready,
    input wire [31 : 0] s_tdata,
    input wire m_ready,
    output wire m_valid,
    output wire [31 : 0] m_tdata
    );
    
    localparam high_end = 16'h6488;
    localparam low_end = 16'h9B78;
    
    reg signed [15 : 0] pha = 0;
    wire s_axis_phase_tvalid;
    wire m_axis_dout_tvalid, m_axis_dout_tready;
    wire [31 : 0] m_axis_dout_tdata;
    wire cordic_ready;
    reg phase_inited = 0;
    
    wire [79 : 0] mult_data_out;
    
    wire [15 : 0] i, q;
    wire [31 : 0] mult_in;
    
    wire [15 : 0] m_tdata_i, m_tdata_q;
    
    wire [15 : 0] mult_in_i, mult_in_q;
    
    wire passthrough;
    
    wire pt_s_valid, pt_s_ready, pt_m_valid, pt_m_ready;
    wire [31 : 0] pt_s_tdata, pt_m_tdata;
    

    
    cordic_0 complex_sine (
      .aclk(clk),                                // input wire aclk
      .aresetn(areset_n),                          // input wire aresetn
      .s_axis_phase_tvalid(s_axis_phase_tvalid),  // input wire s_axis_phase_tvalid
      .s_axis_phase_tready(cordic_ready),  // output wire s_axis_phase_tready
      .s_axis_phase_tdata(pha),    // input wire [15 : 0] s_axis_phase_tdata
      .m_axis_dout_tvalid(m_axis_dout_tvalid),    // output wire m_axis_dout_tvalid
      .m_axis_dout_tready(m_axis_dout_tready),    // input wire m_axis_dout_tready
      .m_axis_dout_tdata(m_axis_dout_tdata)      // output wire [31 : 0] m_axis_dout_tdata
);

    freq_off_mult_0 mult (
      .aclk(clk),                              // input wire aclk
      .aresetn(areset_n),                        // input wire aresetn
      .s_axis_a_tvalid(m_axis_dout_tvalid),        // input wire s_axis_a_tvalid
      .s_axis_a_tready(m_axis_dout_tready),        // output wire s_axis_a_tready
      .s_axis_a_tdata(mult_in),          // input wire [31 : 0] s_axis_a_tdata
      .s_axis_b_tvalid(pt_s_valid),        // input wire s_axis_b_tvalid
      .s_axis_b_tready(pt_s_ready),        // output wire s_axis_b_tready
      .s_axis_b_tdata(s_tdata),          // input wire [31 : 0] s_axis_b_tdata
      .m_axis_dout_tvalid(pt_m_valid),  // output wire m_axis_dout_tvalid
      .m_axis_dout_tready(pt_m_ready),  // input wire m_axis_dout_tready
      .m_axis_dout_tdata(mult_data_out)    // output wire [79 : 0] m_axis_dout_tdata
    );
    
    assign passthrough = phase_valid && (phase == 16'h0000);
    
    assign mult_in_q = (m_axis_dout_tdata[31 : 16] == 16'h4000) ? 16'h7fff :
                        ((m_axis_dout_tdata[31 : 16] == 16'hbfff) ? 16'h8000 :
                          m_axis_dout_tdata[31 : 16] << 1);
    assign mult_in_i = (m_axis_dout_tdata[15 : 0] == 16'h4000) ? 16'h7fff :
                        ((m_axis_dout_tdata[15 : 0] == 16'hbfff) ? 16'h8000 :
                          m_axis_dout_tdata[15 : 0] << 1);
    assign mult_in = {mult_in_q, mult_in_i};
    assign i = m_axis_dout_tdata[15 : 0];
    assign q = m_axis_dout_tdata[31 : 16];
    assign m_tdata_i = mult_data_out[32 : 0] >> 15;
    assign m_tdata_q = mult_data_out[72 : 40] >> 15;
    assign pt_m_tdata = {m_tdata_q , m_tdata_i};
    
    assign m_valid = (passthrough) ? s_valid : pt_m_valid;
    assign s_ready = (passthrough) ? m_ready : pt_s_ready;
    assign m_tdata = (passthrough) ? s_tdata : pt_m_tdata;
    assign pt_s_valid = (passthrough) ? 0 : s_valid;
    assign pt_m_ready = (passthrough) ? 0 : m_ready;
    
    assign s_axis_phase_tvalid = phase_inited;
    always @(posedge clk) begin
        if(!areset_n) begin
            pha <= 0;
            phase_inited <= 0;
        end
        else begin 
            if(phase_valid && ~phase_inited) begin
                pha <= phase;
                phase_inited <= 1;    
            end
            if(phase_valid && cordic_ready) begin
                if((pha + phase > high_end) && ~pha[15]) begin  
                    pha <= (pha + phase - (high_end + 1)) + low_end;
                end
                else 
                    pha <= pha + phase;
            end
        end
    end    
    
    
    
endmodule
