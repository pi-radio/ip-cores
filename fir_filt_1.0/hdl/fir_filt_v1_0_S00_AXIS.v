
`timescale 1 ns / 1 ps

	module tap #
	(
		parameter integer DATA_WIDTH	= 32
	)
	(
		input wire  clk,
		input wire rstn,
		input wire in_valid,
		input wire out_ready,
		input wire [DATA_WIDTH-1 : 0] data,
		input wire [DATA_WIDTH-1 : 0] mult,
		input wire multiplier_valid,
		input wire [DATA_WIDTH-1 : 0] acc_in,
		output wire [DATA_WIDTH - 1 : 0] acc_out,
		output wire [DATA_WIDTH-1 : 0] data_out,
		output wire out_valid,
		output wire in_ready
	);

    wire signed [72 : 0] interm;   

    wire signed [DATA_WIDTH/2 - 1 : 0] multiplied_i;
    wire signed [DATA_WIDTH/2 - 1 : 0] multiplied_q;
    reg signed [DATA_WIDTH/2 - 1 : 0] acc_i;
    reg signed [DATA_WIDTH/2 - 1 : 0] acc_q;

    reg [1 : 0] valid_shift_reg;
    reg extra_i, extra_q;
    wire mult_valid;
    wire b_ready;
    wire s_axis_a_tready;

    
    reg drop_first = 1;
    
    assign multiplied_i = interm [32 : 0] >> 15;
    assign multiplied_q = interm [72 : 40] >> 15;
    
    fir_cmpy cmpy_0_inst (
  .aclk(clk),                              // input wire aclk
  .aresetn(rstn),
  .s_axis_a_tvalid(multiplier_valid),      // input wire s_axis_a_tvalid
  .s_axis_a_tready(s_axis_a_tready),        // output wire s_axis_a_tready
  .s_axis_a_tdata(mult),          // input wire [31 : 0] s_axis_a_tdata
  .s_axis_b_tvalid(in_valid),        // input wire s_axis_b_tvalid
  .s_axis_b_tready(b_ready),        // output wire s_axis_b_tready
  .s_axis_b_tdata(data),
  .m_axis_dout_tvalid(mult_valid),  // output wire m_axis_dout_tvalid
  .m_axis_dout_tready(mult_out_ready),  // input wire m_axis_dout_tready
  .m_axis_dout_tdata(interm)    // output wire [63 : 0] m_axis_dout_tdata
);

wire delay_fifo_s_axis_tvalid, delay_fifo_s_axis_tready,
    delay_fifo_m_axis_tvalid, delay_fifo_m_axis_tready,
    accum_fifo_s_axis_tvalid, accum_fifo_s_axis_tready,
    accum_fifo_m_axis_tvalid, accum_fifo_m_axis_tready;
   
    wire [31 : 0] accum_fifo_m_axis_tdata;
    reg [1 : 0] init = 1;
    
    wire mult_out_ready;
    
    fifo_generator_0 delay_fifo (
      .s_aclk(clk),                // input wire s_aclk
      .s_aresetn(rstn),          // input wire s_aresetn
      .s_axis_tvalid(delay_fifo_s_axis_tvalid),  // input wire s_axis_tvalid
      .s_axis_tready(delay_fifo_s_axis_tready),  // output wire s_axis_tready
      .s_axis_tdata(data),    // input wire [31 : 0] s_axis_tdata
      .s_axis_tuser(delay_fifo_s_axis_tuser),    // input wire [3 : 0] s_axis_tuser
      .m_axis_tvalid(delay_fifo_m_axis_tvalid),  // output wire m_axis_tvalid
      .m_axis_tready(delay_fifo_m_axis_tready),  // input wire m_axis_tready
      .m_axis_tdata(data_out),    // output wire [31 : 0] m_axis_tdata
      .m_axis_tuser(delay_fifo_m_axis_tuser)    // output wire [3 : 0] m_axis_tuser
);

 fifo_generator_0 accum_fifo (
      .s_aclk(clk),                // input wire s_aclk
      .s_aresetn(rstn),          // input wire s_aresetn
      .s_axis_tvalid(accum_fifo_s_axis_tvalid),  // input wire s_axis_tvalid
      .s_axis_tready(accum_fifo_s_axis_tready),  // output wire s_axis_tready
      .s_axis_tdata(acc_in),    // input wire [31 : 0] s_axis_tdata
      .s_axis_tuser(accum_fifo_s_axis_tuser),    // input wire [3 : 0] s_axis_tuser
      .m_axis_tvalid(accum_fifo_m_axis_tvalid),  // output wire m_axis_tvalid
      .m_axis_tready(accum_fifo_m_axis_tready),  // input wire m_axis_tready
      .m_axis_tdata(accum_fifo_m_axis_tdata),    // output wire [31 : 0] m_axis_tdata
      .m_axis_tuser(accum_fifo_m_axis_tuser)    // output wire [3 : 0] m_axis_tuser
);
   
    assign mult_out_ready = out_ready && accum_fifo_m_axis_tvalid;
    assign delay_fifo_m_axis_tready = valid_shift_reg[0] && out_ready;
    assign accum_fifo_m_axis_tready = (mult_valid && out_ready) || (init == 2'h1 && accum_fifo_m_axis_tvalid && out_ready && ~valid_shift_reg[0]);
    
    assign delay_fifo_s_axis_tvalid = in_valid && b_ready;
    assign accum_fifo_s_axis_tvalid = delay_fifo_s_axis_tvalid;
    
    assign out_valid = valid_shift_reg[0] || (init == 2'h2)  /*|| (init && accum_fifo_m_axis_tvalid)*/;
    assign in_ready = b_ready;
    
    assign acc_out[31 : 16] = /*(init) ? accum_fifo_m_axis_tdata[DATA_WIDTH - 1 : DATA_WIDTH/2] : */
                        ({extra_q, acc_q[15]} == 2'b01 ? 16'h7fff :
                        ({extra_q, acc_q[15]} == 2'b10 ? 16'h8001 : acc_q));
    assign acc_out[15 : 0] = /*(init) ? accum_fifo_m_axis_tdata[DATA_WIDTH/2 - 1 : 0] : */
                        ({extra_i, acc_i[15]} == 2'b01 ? 16'h7fff :
                        ({extra_i, acc_i[15]} == 2'b10 ? 16'h8001 : acc_i));
    
    always @(posedge clk) begin
        if(init != 2'h1 && mult_valid && accum_fifo_m_axis_tvalid && mult_out_ready) begin
            {extra_q, acc_q} <= {multiplied_q[15], multiplied_q[15 : 0]} + {accum_fifo_m_axis_tdata[DATA_WIDTH - 1], accum_fifo_m_axis_tdata[DATA_WIDTH - 1 : DATA_WIDTH/2]};
            {extra_i, acc_i} <= {multiplied_i[15], multiplied_i[15 : 0]}  + {accum_fifo_m_axis_tdata[DATA_WIDTH/2 - 1], accum_fifo_m_axis_tdata[DATA_WIDTH/2 - 1 : 0]};
        end
        else if(init == 2'h1 && accum_fifo_m_axis_tvalid && mult_out_ready ) begin
             {extra_q, acc_q} <= {accum_fifo_m_axis_tdata[DATA_WIDTH - 1], accum_fifo_m_axis_tdata[DATA_WIDTH - 1 : DATA_WIDTH/2]};
             {extra_i, acc_i} <= {accum_fifo_m_axis_tdata[DATA_WIDTH/2 - 1], accum_fifo_m_axis_tdata[DATA_WIDTH/2 - 1 : 0]};
        end
    end
    
    always@(posedge clk) begin
        if(~rstn)
            init <= 2'h1;
        else
          if(init == 1'h1 && accum_fifo_m_axis_tvalid && out_ready)
            init <= 2'h2;
          else if(init == 2'h2)
            init <= 2'h0;
    end

    always @(posedge clk) begin
        if(~rstn) begin
            valid_shift_reg[1 : 0] <= 2'b0;
        end
        else if(out_ready)
            valid_shift_reg[1 : 0] <= {valid_shift_reg[0], mult_valid && accum_fifo_m_axis_tvalid};
    end        
	endmodule
