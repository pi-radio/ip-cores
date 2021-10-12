`timescale 1ns / 1ps


module fifo_impl # (
    parameter integer FIFO_SIZE	= 512,
    parameter integer C_S_AXIS_TDATA_WIDTH	= 32,
    parameter integer C_S_AXIS_TDATA_EXT_WIDTH	= 40,
    parameter integer C_M_AXIS_TDATA_WIDTH	= 32,
    parameter integer  BIT_DEPTH = 9,
    parameter integer FFT_SIZE = 1024
    )
    (
    output wire s_ready,
    input wire s_valid,
    input wire m_ready,
    output wire m_valid,
    input wire [C_S_AXIS_TDATA_EXT_WIDTH-1 : 0] wdata,
    output wire [C_M_AXIS_TDATA_WIDTH-1 : 0] rdata,
    input wire clk,
    input wire rst,
    output wire m_tlast,
    output wire [1:0] st,
    input wire reset_mod,
    input wire [(C_S_AXIS_TDATA_EXT_WIDTH/8)-1 : 0] tstrb
    );
    
    wire s_axis_tvalid;
    wire s_axis_tready;
    wire [63 : 0] s_axis_tdata;
    wire [7 : 0] s_axis_tstrb;
    
    wire m_axis_tvalid;
    wire m_axis_tready;
    wire [63 : 0] m_axis_tdata;
    wire [7 : 0] m_axis_tstrb;
    
    reg [9 : 0] subc_cnt  = 0;
    reg [5 : 0] bit_cnt = 0;
    wire [63 : 0] current_sample; 
    wire [7 : 0] current_tstrb;
    
    wire [31 : 0] modulated_sample; 
    reg [1:0] state;
    
    parameter [1:0] IDLE = 2'h0,        // This is the initial/idle state 
                READ_FIFO = 2'h1,
                INSERT_NULL  = 2'h2,
                HALT   = 2'h3;
    
    fifo_modulator fifo_mod_inst (
      .s_aclk(clk),                // input wire s_aclk
      .s_aresetn(rst),          // input wire s_aresetn
      .s_axis_tvalid(s_axis_tvalid),  // input wire s_axis_tvalid
      .s_axis_tready(s_axis_tready),  // output wire s_axis_tready
      .s_axis_tdata(s_axis_tdata),    // input wire [63 : 0] s_axis_tdata
      .s_axis_tstrb(s_axis_tstrb),    // input wire [7 : 0] s_axis_tstrb
      .s_axis_tuser(s_axis_tuser),    // input wire [3 : 0] s_axis_tuser
      .m_axis_tvalid(m_axis_tvalid),  // output wire m_axis_tvalid
      .m_axis_tready(m_axis_tready),  // input wire m_axis_tready
      .m_axis_tdata(m_axis_tdata),    // output wire [63 : 0] m_axis_tdata
      .m_axis_tstrb(m_axis_tstrb),    // output wire [7 : 0] m_axis_tstrb
      .m_axis_tuser(m_axis_tuser)    // output wire [3 : 0] m_axis_tuser
    );
    
    
    assign s_ready = s_axis_tready;
    assign s_axis_tvalid = s_valid;
    assign s_axis_tdata = {24'h000000, wdata};
    assign s_axis_tstrb = {3'h00, tstrb};
    
    assign m_axis_tready = (m_ready && ((m_axis_tvalid && m_axis_tstrb == 8'h01) ? ((state == READ_FIFO) && (bit_cnt == 31 )):
                             ((m_axis_tvalid && m_axis_tstrb == 8'h00) ?  ((state == READ_FIFO) && (bit_cnt == 39 )) 
                                                                        : 0)));
//    assign current_sample = (m_axis_tready && m_axis_tvalid && bit_cnt == 0) ? m_axis_tdata : current_sample; // Latch here
//    assign current_tstrb = (m_axis_tready && m_axis_tvalid && bit_cnt == 0) ? m_axis_tstrb : current_tstrb;
    
    assign modulated_sample = (m_axis_tdata[bit_cnt] == 1) ? {16'h0000, 16'h7fff}
                                                            : {16'h0000, 16'h8000};
                                                            
    assign m_valid = (m_axis_tvalid);
    assign m_tlast = (subc_cnt == 1023) && (state == INSERT_NULL) && m_valid;
    
    assign rdata = (state == INSERT_NULL) ? 32'h00000000 : modulated_sample;
    
    always @(posedge clk) begin
        if(!rst || reset_mod) begin
            subc_cnt <= 0;
            state <= INSERT_NULL;
        end
        else begin
            if(m_ready) begin
                case(state)
                     INSERT_NULL: begin
                     if(m_axis_tvalid) begin
                            subc_cnt <= subc_cnt + 1;
                            if(((subc_cnt == 0) || (subc_cnt == 622))) begin
                                state <= READ_FIFO;
                            end   
                        end
                     end
                     READ_FIFO: begin
                        if(m_axis_tvalid) begin
                            subc_cnt <= subc_cnt + 1;
                            if(m_axis_tstrb == 8'h01)
                                if(bit_cnt < 31)
                                    bit_cnt <= bit_cnt + 1;
                                else
                                    bit_cnt <= 0;
                             else
                                if(bit_cnt < 39)
                                    bit_cnt <= bit_cnt + 1;
                                else
                                    bit_cnt <= 0;
                            if((subc_cnt == 400) || (subc_cnt == 1022 )) begin
                                state <= INSERT_NULL;
                        end
                        end
                     end
                endcase
                
            end
        end
            
    end
    
    
    
    
    
    
    
    
    
    
    
    
    
    
//    //localparam fifo_size_actual = FIFO_SIZE * C_S_AXIS_TDATA_EXT_WIDTH;

//    reg [C_M_AXIS_TDATA_WIDTH-1 : 0] fifo [0 : FIFO_SIZE - 1];
//    reg [7:0] after_reset_cnt = 0;
//    reg [BIT_DEPTH : 0] read_addr = 0, write_addr = 0 ;
//    reg [BIT_DEPTH : 0] in_fifo = 0;
//    reg [1:0] state;
//    reg [9 : 0] subc_cnt  = 0;
//    reg [9 : 0] upper_bound = FIFO_SIZE;
    
//    reg [C_M_AXIS_TDATA_WIDTH - 1 : 0] data_out = 32'hffffffff;
//    wire fuck;
    
//    assign fuck = write_addr[9];

//    wire fifo_wren, fifo_rden;
    
//    parameter [1:0] IDLE = 2'h0,        // This is the initial/idle state 
//                READ_FIFO = 2'h1,
//                INSERT_NULL  = 2'h2,
//                HALT   = 2'h3;
                
//    assign m_tlast = (subc_cnt == 1023) && (state == INSERT_NULL);//(state == READ_FIFO) && (in_fifo == 1) && (~fifo_wren);
    
//    always @(posedge clk) begin
//        if(!rst) begin
//            state <= IDLE;
//            read_addr <= 0;
//            subc_cnt <= 0;
//        end
//        else if(reset_mod) begin
//            state <= IDLE;
//            read_addr <= 0;
//            subc_cnt <= 0;
//        end
//        else begin
//            if(m_ready) begin
//            case(state)
//                IDLE: 
//                    if((in_fifo > 0)) begin
//                        state <= INSERT_NULL;
//                        data_out <= 32'h00000000;
//                    end
//                INSERT_NULL: begin
//                subc_cnt <= subc_cnt + 1;
//                    if(((subc_cnt == 0) || (subc_cnt == 622))) begin
//                        state <= READ_FIFO;
//                        data_out <= fifo[read_addr[BIT_DEPTH - 1 : 0]];
//                        if(read_addr[BIT_DEPTH - 1 : 0] + 1 >= upper_bound)
//                                if(read_addr[9])
//                                    read_addr <= 0;
//                                else
//                                    read_addr <= 10'd512;
//                            else
//                                read_addr <= read_addr + 1;
//                        end
//                    else if(subc_cnt == 1023)
//                        state <= IDLE;
//                    else 
//                        data_out <= 32'h00000000;
//                    end
//                READ_FIFO:
//                    if((in_fifo == 0) && ~(subc_cnt == 1022))begin
//                        state <= HALT;
//                    end
//                    else begin 
//                        subc_cnt <= subc_cnt + 1;
//                        if((subc_cnt == 400) || (subc_cnt == 1022 )) begin
//                            state <= INSERT_NULL;
//                            data_out <= 32'h00000000;
//                        end
//                        else begin
//                            data_out <= fifo[read_addr[BIT_DEPTH - 1 : 0]];
//                            if(read_addr[BIT_DEPTH - 1 : 0] + 1 >= upper_bound)
//                                if(read_addr[9])
//                                    read_addr <= 0;
//                                else
//                                    read_addr <= 10'd512;
//                            else
//                                read_addr <= read_addr + 1;
//                        end
//                    end
//                HALT:
//                    if((in_fifo > 0)) begin
//                    subc_cnt <= subc_cnt + 1;
//                        if(((subc_cnt > 0) && (subc_cnt <= 400)) ||
//                            ((subc_cnt > 622) && (subc_cnt < 1023))) begin
//                            state <= READ_FIFO;
//                            data_out <= fifo[read_addr[BIT_DEPTH - 1 : 0]];
//                            if(read_addr[BIT_DEPTH - 1 : 0] + 1 >= upper_bound)
//                                if(read_addr[9])
//                                    read_addr <= 0;
//                                else
//                                    read_addr <= 10'd512;
//                            else
//                                read_addr <= read_addr + 1;
//                            end
//                        else if(subc_cnt == 1023) begin
//                            state <= IDLE;
//                            data_out <= 32'h00000000;
//                            end
//                    end
//                default: state <= IDLE;
//             endcase
//             end
//        end
//        end
                    
//    always @(*) begin
//        if (!rst) 
//        begin
//            in_fifo <= 0;
//        end
//        else if(reset_mod) begin
//            in_fifo <= 0;
//        end
//        else begin
//            in_fifo <=  write_addr - read_addr;
//        end
//    end
    
//    assign s_ready = (in_fifo < (FIFO_SIZE - C_S_AXIS_TDATA_EXT_WIDTH)); // Allow some space in order not to overwrite data
//    assign m_valid = (state == READ_FIFO) || (state == INSERT_NULL);

//    assign rdata = data_out ;
    
    
//    assign fifo_wren = s_ready && s_valid;
//    assign fifo_rden = m_ready && m_valid;
    
//    reg[8 : 0] bit_index;
       
//	    always @( posedge clk )
//	    begin
//	        if (!rst) 
//                begin
//                write_addr = 0;
//            end
//            else if(reset_mod) begin
//                write_addr <= 0;
//            end
//            else begin
//	           if (fifo_wren) begin
//	               if(tstrb[4 : 0] == 5'h01) begin // Sync Word
//                        for(bit_index=0; bit_index < C_S_AXIS_TDATA_WIDTH; bit_index=bit_index+1)
//                            case(wdata[bit_index])
//                                1'b0: begin
//                                    fifo[write_addr[BIT_DEPTH - 1 : 0]  + bit_index ] <= {16'h0000, 16'h8000}; // Real part
//                                end
//                                1'b1:  begin
//                                    fifo[write_addr[BIT_DEPTH - 1 : 0]  + bit_index ] <= {16'h0000, 16'h7fff}; // Real part
//                                end
//                            endcase
//                            if(write_addr[BIT_DEPTH - 1 : 0] + C_S_AXIS_TDATA_WIDTH + C_S_AXIS_TDATA_EXT_WIDTH > FIFO_SIZE) begin
//                                upper_bound <= write_addr[BIT_DEPTH - 1 : 0] + C_S_AXIS_TDATA_WIDTH;
//                                if(write_addr[9] == 1)
//                                    write_addr <= 0;
//                                else if (write_addr[9] == 0)
//                                    write_addr <= 10'h200;
//                            end
//                            else
//                                write_addr = write_addr + C_S_AXIS_TDATA_WIDTH;
//                    end
//                    else begin
//                        for(bit_index=0; bit_index < C_S_AXIS_TDATA_EXT_WIDTH; bit_index=bit_index+1)
//                            case(wdata[bit_index])
//                                1'b0: begin
//                                    fifo[write_addr[BIT_DEPTH - 1 : 0]  + bit_index ] <= {16'h0000, 16'h8000}; // Real part
//                                end
//                                1'b1:  begin
//                                    fifo[write_addr[BIT_DEPTH - 1 : 0]  + bit_index ] <= {16'h0000, 16'h7fff}; // Real part
//                                end
//                            endcase
//                            if(write_addr[BIT_DEPTH - 1 : 0] + C_S_AXIS_TDATA_EXT_WIDTH + C_S_AXIS_TDATA_EXT_WIDTH > FIFO_SIZE) begin
//                                upper_bound <= write_addr[BIT_DEPTH - 1 : 0] + C_S_AXIS_TDATA_EXT_WIDTH;
//                                if(write_addr[9] == 1)
//                                    write_addr <= 0;
//                                else if(write_addr[9] == 0)
//                                    write_addr <= 10'h200;
//                            end
//                            else
//                                write_addr = write_addr + C_S_AXIS_TDATA_EXT_WIDTH;
//                    end    	        
//	           end
//	        end
//	    end  
endmodule
