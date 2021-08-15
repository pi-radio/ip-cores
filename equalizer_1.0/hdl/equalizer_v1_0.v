
`timescale 1 ns / 1 ps

	module equalizer_v1_0 #
	(
    // Users to add parameters here

    // User parameters ends
    // Do not modify the parameters beyond this line


    // Parameters of Axi Master Bus Interface M00_AXIS
    parameter integer C_M00_AXIS_TDATA_WIDTH	= 32,
    parameter integer C_M00_AXIS_START_COUNT	= 32,

    // Parameters of Axi Slave Bus Interface S00_AXIS
    parameter integer C_S00_AXIS_TDATA_WIDTH	= 32,

    parameter integer DATA_CARRIERS	= 800
)
	(
    // Users to add ports here

    // User ports ends
    // Do not modify the ports beyond this line


    // Ports of Axi Master Bus Interface M00_AXIS
    input wire  m00_axis_aclk,
    input wire  m00_axis_aresetn,
    output wire  m00_axis_tvalid,
    output wire [C_M00_AXIS_TDATA_WIDTH-1 : 0] m00_axis_tdata,
    output wire [(C_M00_AXIS_TDATA_WIDTH/8)-1 : 0] m00_axis_tstrb,
    output wire  m00_axis_tlast,
    input wire  m00_axis_tready,
    
    input wire  m00_axis_chann_aclk,
    input wire  m00_axis_chann_aresetn,
    output wire  m00_axis_chann_tvalid,
    output wire [C_M00_AXIS_TDATA_WIDTH-1 : 0] m00_axis_chann_tdata,
    input wire  m00_axis_chann_tready,    

    // Ports of Axi Slave Bus Interface S00_AXIS
    input wire  s00_axis_aclk,
    input wire  s00_axis_aresetn,
    output wire  s00_axis_tready,
    input wire [C_S00_AXIS_TDATA_WIDTH-1 : 0] s00_axis_tdata,
    input wire [(C_S00_AXIS_TDATA_WIDTH/8)-1 : 0] s00_axis_tstrb,
    input wire  s00_axis_tlast,
    input wire  s00_axis_tvalid
);

    wire s_axis_a_tready;
    wire [31 : 0] s_axis_a_tdata;
    wire s_axis_b_tvalid;
    wire s_axis_b_tready;
    wire [31 : 0] s_axis_b_tdata;
    wire m_axis_dout_tvalid;
    wire m_axis_dout_tready;
    wire [31 : 0] m_axis_dout_tdata;
    
    wire comp_mult_valid;
    wire comp_mult_ready;
    wire [72 : 0] comp_mult_tdata;
    wire s_dividend1_ready, s_dividend2_ready;
    wire s_divisor1_ready, s_divisor2_ready;
    wire s_divisor_valid;
    wire divide_out_re_ready;
    wire divide_out_re_valid;
    wire divide_out_im_ready;
    wire divide_out_im_valid;
    
    
    wire signed [15 : 0] dividend_re;
    wire signed [15 : 0] dividend_im;
    
    wire signed [15 : 0] mult_out_re;
    wire signed [15 : 0] mult_out_im;

    reg signed [31:0] tmp_i_sq;
    reg signed [31:0] tmp_q_sq;
    function[15 : 0] mag_squared;
        input signed [15 : 0] i;
        input signed [15 : 0] q;
        begin
            tmp_i_sq = i * i;
            tmp_q_sq = q * q;
            mag_squared = (tmp_i_sq >> 15) + (tmp_q_sq >> 15);
        end
    endfunction
    
    reg [3 : 0] symbol_cnt = 0;
    reg [7 : 0] channel_idx = 0;
    reg [31 : 0] channel [0 : 160];
    reg [7 : 0] channel_idx_write = 0;
    reg [7 : 0] channel_idx_read = 0;
    reg [9 : 0] subc_cnt = 0;
    reg [9 : 0] mult_out_cnt = 0;

    wire signed [15 : 0] rx_i;
    wire signed [15 : 0] rx_q;
    
    wire signed [15 : 0] channel_i;
    wire signed [15 : 0] channel_q;
    
    reg signs_re [0 : 63];
    reg signs_im [0 : 63];
    reg [5 : 0] signs_idx_write = 0;
    reg [5 : 0] signs_idx_read = 0;
    
    wire [15 : 0] divisor;
    wire [31 : 0] divide_out_re;
    wire [31 : 0] divide_out_im;
    
    wire [15 : 0] divide_out_re_quot;
    wire [31 : 0] divide_out_re_remain;
    
    wire [15 : 0] divide_out_im_quot;
    wire [31 : 0] divide_out_im_remain;
    
    wire signed [15 : 0] out_re;
    wire signed [15 : 0] out_im;
    
    assign s_axis_a_tvalid = s00_axis_tvalid && (((subc_cnt % 10 == 0) || (subc_cnt % 10 == 5)) ? 0 : 1);
    assign s_axis_b_tdata = {-channel_q, channel_i};
    
    
    assign channel_i = (subc_cnt % 10 == 0)? rx_i : ((subc_cnt % 10 == 5) ? -rx_i : channel[channel_idx_write][15 : 0]) ;
    assign channel_q = (subc_cnt % 10 == 0)? rx_q : ((subc_cnt % 10 == 5) ? -rx_q : channel[channel_idx_write][31 : 16]);
    
    assign m00_axis_chann_tdata = {channel_q, channel_i};
    assign m00_axis_chann_tvalid = ((subc_cnt % 10 == 0) || (subc_cnt % 10 == 5)) && (s00_axis_tvalid && s00_axis_tready);

    assign rx_i = s00_axis_tdata[15 : 0];
    assign rx_q = s00_axis_tdata[31 : 16];
    
    assign comp_mult_ready = s_dividend1_ready && s_dividend2_ready;
    assign s_divisor_valid = comp_mult_valid;
    assign mult_out_re = comp_mult_tdata[32 : 0] >> 15;
    assign dividend_re = (mult_out_re < 0) ? -mult_out_re : mult_out_re;
    
    assign mult_out_im = comp_mult_tdata[72 : 40] >> 15;
    assign dividend_im = (mult_out_im < 0) ? -mult_out_im : mult_out_im;
    
    assign divisor = (mult_out_cnt % 5 == 0) ? mag_squared(channel[channel_idx_read][15 : 0],
                                 channel[channel_idx_read][31 : 16])
                                : mag_squared(channel[channel_idx_read - 1][15 : 0],
                                 channel[channel_idx_read - 1][31 : 16]);
                                 
    assign divide_out_re_quot = divide_out_re[31 : 16];
    assign divide_out_re_remain = divide_out_re[15 : 0];
    
    assign divide_out_im_quot = divide_out_im[31 : 16];
    assign divide_out_im_remain = divide_out_im[15 : 0];
    
    assign out_re = (signs_re[signs_idx_read]) ? ((divide_out_re_quot > 0) ? 16'h7fff : (divide_out_re_remain >>> 1))
                                                : ((divide_out_re_quot > 0) ? 16'h8001 : -(divide_out_re_remain >>> 1));
 
    assign out_im = (signs_im[signs_idx_read]) ? ((divide_out_im_quot > 0) ? 16'h7fff : (divide_out_im_remain >>> 1))
                                                : ((divide_out_im_quot > 0) ? 16'h8001 : -(divide_out_im_remain >>> 1));
                                                
    assign m00_axis_tdata = {out_im, out_re};
    assign m00_axis_tvalid = divide_out_re_valid & divide_out_im_valid;
                                                   
    always @(posedge m00_axis_aclk) begin
        if(!m00_axis_aresetn) begin
            subc_cnt <= 0;
            channel_idx_write <= 0;
        end
        else begin
            if(s00_axis_tready && s00_axis_tvalid) begin
                if(subc_cnt == DATA_CARRIERS - 1) begin
                    subc_cnt <= 0;
                    channel_idx_write <= 0;
                end
                else begin
                    subc_cnt <= subc_cnt + 1;
                    if(subc_cnt % 5 == 4)
                        channel_idx_write <= channel_idx_write + 1;
                end
                if(subc_cnt % 10 == 0) begin
                    channel[channel_idx_write] <= s00_axis_tdata;
                end
                else if (subc_cnt % 10 == 5) begin
                    channel[channel_idx_write] <= {-rx_q, -rx_i};
                end

            end
        end
    end
    
    always @(posedge m00_axis_aclk) begin
        if(!m00_axis_aresetn) begin
            signs_idx_write <= 0;
            channel_idx_read <= 0;
            mult_out_cnt <= 0;
        end
        else begin 
            if(mult_out_cnt == DATA_CARRIERS - 1) begin
                mult_out_cnt <= 0;
                channel_idx_read <= 0;
            end
            if(comp_mult_valid && comp_mult_ready) begin
                if((mult_out_cnt % 10 == 0) || (mult_out_cnt % 10 == 5))
                    if(mult_out_cnt != DATA_CARRIERS - 1)
                        channel_idx_read <= channel_idx_read + 1;
                if(mult_out_re < 0)
                    signs_re[signs_idx_write] <= 0;
                else
                    signs_re[signs_idx_write] <= 1;
                if(mult_out_im < 0)
                    signs_im[signs_idx_write] <= 0;
                else
                    signs_im[signs_idx_write] <= 1;
                signs_idx_write <= signs_idx_write + 1;
                if(mult_out_cnt != DATA_CARRIERS - 1)
                    mult_out_cnt <= mult_out_cnt + 1;
            end
        end
    end
    
    
always @(posedge m00_axis_aclk) begin
    if(!m00_axis_aresetn) begin
        signs_idx_read <= 0;
    end
    else begin 
        if(divide_out_re_valid && divide_out_im_valid && m00_axis_tready)
            signs_idx_read <= signs_idx_read + 1;
    end
end    
    


    cmpy_eq_0 mult (
        .aclk(m00_axis_aclk), // input wire aclk
        .aresetn(m00_axis_aresetn), 
        .s_axis_a_tvalid(s_axis_a_tvalid), // input wire s_axis_a_tvalid
        .s_axis_a_tready(s00_axis_tready), // output wire s_axis_a_tready
        .s_axis_a_tdata(s00_axis_tdata), // input wire [31 : 0] s_axis_a_tdata
        .s_axis_b_tvalid(s00_axis_tvalid), // input wire s_axis_b_tvalid
        .s_axis_b_tready(s_axis_b_tready), // output wire s_axis_b_tready
        .s_axis_b_tdata(s_axis_b_tdata), // input wire [31 : 0] s_axis_b_tdata
        .m_axis_dout_tvalid(comp_mult_valid), // output wire m_axis_dout_tvalid
        .m_axis_dout_tready(comp_mult_ready), // input wire m_axis_dout_tready
        .m_axis_dout_tdata(comp_mult_tdata) // output wire [31 : 0] m_axis_dout_tdata
    );

    div_gen_0 divid_re (
        .aclk(m00_axis_aclk), // input wire aclk
        .aresetn(m00_axis_aresetn), 
        .s_axis_divisor_tvalid(s_divisor_valid), // input wire s_axis_divisor_tvalid
        .s_axis_divisor_tready(s_divisor1_ready), // output wire s_axis_divisor_tready
        .s_axis_divisor_tdata(divisor), // input wire [15 : 0] s_axis_divisor_tdata
        .s_axis_dividend_tvalid(comp_mult_valid), // input wire s_axis_dividend_tvalid
        .s_axis_dividend_tready(s_dividend1_ready), // output wire s_axis_dividend_tready
        .s_axis_dividend_tdata(dividend_re), // input wire [15 : 0] s_axis_dividend_tdata
        .m_axis_dout_tvalid(divide_out_re_valid), // output wire m_axis_dout_tvalid
        .m_axis_dout_tready(m00_axis_tready && divide_out_im_valid),
        .m_axis_dout_tdata(divide_out_re) // output wire [31 : 0] m_axis_dout_tdata
    );
    
    div_gen_0 divid_im (
        .aclk(m00_axis_aclk), // input wire aclk
        .aresetn(m00_axis_aresetn), 
        .s_axis_divisor_tvalid(s_divisor_valid), // input wire s_axis_divisor_tvalid
        .s_axis_divisor_tready(s_divisor2_ready), // output wire s_axis_divisor_tready
        .s_axis_divisor_tdata(divisor), // input wire [15 : 0] s_axis_divisor_tdata
        .s_axis_dividend_tvalid(comp_mult_valid), // input wire s_axis_dividend_tvalid
        .s_axis_dividend_tready(s_dividend2_ready), // output wire s_axis_dividend_tready
        .s_axis_dividend_tdata(dividend_im), // input wire [15 : 0] s_axis_dividend_tdata
        .m_axis_dout_tvalid(divide_out_im_valid), // output wire m_axis_dout_tvalid
        .m_axis_dout_tready(m00_axis_tready && divide_out_re_valid),
        .m_axis_dout_tdata(divide_out_im) // output wire [31 : 0] m_axis_dout_tdata
    );

endmodule
