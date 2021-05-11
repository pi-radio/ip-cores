
`timescale 1 ns / 1 ps

	module tap #
	(
		parameter integer DATA_WIDTH	= 32
	)
	(
		input wire  clk,
		input wire in_valid,
		input wire out_ready,
		input wire [DATA_WIDTH-1 : 0] data,
		input wire [DATA_WIDTH-1 : 0] mult,
		input wire [DATA_WIDTH-1 : 0] acc_in,
		output wire [DATA_WIDTH - 1 : 0] acc_out,
		output wire [DATA_WIDTH-1 : 0] data_out,
		output wire out_valid,
		output wire in_ready
	);
    
    reg [DATA_WIDTH-1 : 0] delay1;
    reg [DATA_WIDTH-1 : 0] delay2;
    reg [DATA_WIDTH-1 : 0] delay3, delay4,delay5,delay6, delay7, delay8, delay9;
    
    reg [DATA_WIDTH-1 : 0] accum_delay1;
    reg [DATA_WIDTH-1 : 0] accum_delay2, accum_delay3, accum_delay4,
        accum_delay5, accum_delay6, accum_delay7, accum_delay8, accum_delay9;
    wire signed [DATA_WIDTH/2 - 1 : 0] i_data;
    wire signed [DATA_WIDTH/2 - 1 : 0] q_data;
    wire signed [DATA_WIDTH/2 - 1 : 0] i_mult;
    wire signed [DATA_WIDTH/2 - 1 : 0] q_mult;
    reg signed [DATA_WIDTH/2 - 1 : 0] tmp_i_data;
    reg signed [DATA_WIDTH/2 - 1 : 0] tmp_q_data;
    wire enable;
//    reg signed [DATA_WIDTH/2 - 1 : 0] interm; 
  
    wire signed [72 : 0] interm;   
//    reg signed [DATA_WIDTH - 1 : 0] multiplied_i;
//    reg signed [DATA_WIDTH - 1 : 0] multiplied_q;
    wire signed [DATA_WIDTH/2 - 1 : 0] multiplied_i;
    wire signed [DATA_WIDTH/2 - 1 : 0] multiplied_q;
    reg signed [DATA_WIDTH/2 - 1 : 0] acc_i;
    reg signed [DATA_WIDTH/2 - 1 : 0] acc_q;
    //reg [2 : 0] shift_reg = 0;
    reg [8 : 0] shift_reg = 0;
    reg extra_i, extra_q;
    wire mult_valid;
    wire b_ready;
    wire s_axis_a_tready;
    
    
    assign multiplied_i = interm [32 : 0] >> 15;
    assign multiplied_q = interm [72 : 40] >> 15;
    
    cmpy_0 cmpy_0_inst (
  .aclk(clk),                              // input wire aclk
  .s_axis_a_tvalid(1),                      // input wire s_axis_a_tvalid
  .s_axis_a_tready(s_axis_a_tready),        // output wire s_axis_a_tready
  .s_axis_a_tdata(mult),          // input wire [31 : 0] s_axis_a_tdata
  .s_axis_b_tvalid(in_valid),        // input wire s_axis_b_tvalid
  .s_axis_b_tready(b_ready),        // output wire s_axis_b_tready
  .s_axis_b_tdata(data),
  .m_axis_dout_tvalid(mult_valid),  // output wire m_axis_dout_tvalid
  .m_axis_dout_tready(out_ready),  // input wire m_axis_dout_tready
  .m_axis_dout_tdata(interm)    // output wire [63 : 0] m_axis_dout_tdata
);
    
    //assign data_out = delay3;
    assign data_out = delay9;
    assign i_data = data[DATA_WIDTH/2 - 1 : 0];
    assign q_data = data[DATA_WIDTH - 1 : DATA_WIDTH/2];
    assign i_mult = mult[DATA_WIDTH/2 - 1 : 0];
    assign q_mult = mult[DATA_WIDTH - 1 : DATA_WIDTH/2];
    assign out_valid = shift_reg[0] && in_ready;
    
    /* This wire indicates when the pipeline should run */
    assign enable = ~(!shift_reg || (shift_reg[0] && ~out_ready)) || (!shift_reg && in_valid);
    assign in_ready = enable &&  b_ready;
    
    always@(posedge clk) if(in_ready && in_valid) delay1 <= data;
    always@(posedge clk) if(in_ready && in_valid) delay2 <= delay1;
    always@(posedge clk) if(in_ready && in_valid) delay3 <= delay2;
    always@(posedge clk) if(in_ready && in_valid) delay4 <= delay3;
    always@(posedge clk) if(in_ready && in_valid) delay5 <= delay4;
    always@(posedge clk) if(in_ready && in_valid) delay6 <= delay5;
    always@(posedge clk) if(in_ready && in_valid) delay7 <= delay6;
    always@(posedge clk) if(in_ready && in_valid) delay8 <= delay7;
    always@(posedge clk) if(in_ready && in_valid) delay9 <= delay8;
    
    always@(posedge clk) if(in_ready && in_valid) accum_delay1 <= acc_in;
    always@(posedge clk) if(in_ready && in_valid) accum_delay2 <= accum_delay1;
    always@(posedge clk) if(in_ready && in_valid) accum_delay3 <= accum_delay2;
    always@(posedge clk) if(in_ready && in_valid) accum_delay4 <= accum_delay3;
    always@(posedge clk) if(in_ready && in_valid) accum_delay5 <= accum_delay4;
    always@(posedge clk) if(in_ready && in_valid) accum_delay6 <= accum_delay5;
    always@(posedge clk) if(in_ready && in_valid) accum_delay7 <= accum_delay6;
    always@(posedge clk) if(in_ready && in_valid) accum_delay8 <= accum_delay7;
    always@(posedge clk) if(in_ready && in_valid) accum_delay9 <= accum_delay8;
    
    assign acc_out[31 : 16] = {extra_q, acc_q[15]} == 2'b01 ? 16'h7fff :
                        ({extra_q, acc_q[15]} == 2'b10 ? 16'h8001 : acc_q);
    assign acc_out[15 : 0] = {extra_i, acc_i[15]} == 2'b01 ? 16'h7fff :
                        ({extra_i, acc_i[15]} == 2'b10 ? 16'h8001 : acc_i);
    
    always @(posedge clk) begin
        //if(enable) begin
        if(mult_valid && enable) begin
//            interm <= (q_data * (i_mult + q_mult)) >>> 15;
//            tmp_i_data <= i_data;
//            tmp_q_data <= q_data;
//            multiplied_q <= (((tmp_i_data - tmp_q_data) * q_mult) >>> 15) + interm;
//            multiplied_i <= (((tmp_i_data + tmp_q_data) * i_mult) >>> 15 ) - interm;
//            {extra_q, acc_q} <= {multiplied_q[15], multiplied_q[15 : 0]} + {accum_delay2[DATA_WIDTH - 1], accum_delay2[DATA_WIDTH - 1 : DATA_WIDTH/2]};
//            {extra_i, acc_i} <= {multiplied_i[15], multiplied_i[15 : 0]}  + {accum_delay2[DATA_WIDTH/2 - 1], accum_delay2[DATA_WIDTH/2 - 1 : 0]};
            {extra_q, acc_q} <= {multiplied_q[15], multiplied_q[15 : 0]} + {accum_delay7[DATA_WIDTH - 1], accum_delay7[DATA_WIDTH - 1 : DATA_WIDTH/2]};
            {extra_i, acc_i} <= {multiplied_i[15], multiplied_i[15 : 0]}  + {accum_delay7[DATA_WIDTH/2 - 1], accum_delay7[DATA_WIDTH/2 - 1 : 0]};
        end
    end
    
    always @(posedge clk)
        if(enable)
//            shift_reg <= {in_valid, shift_reg[2 : 1]};
              shift_reg <= {in_valid, shift_reg[8 : 1]};
	endmodule

