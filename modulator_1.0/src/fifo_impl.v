`timescale 1ns / 1ps


module fifo_impl # (
    parameter integer FIFO_SIZE	= 16,
    parameter integer C_S_AXIS_TDATA_WIDTH	= 32,
    parameter integer C_M_AXIS_TDATA_WIDTH	= 32,
    parameter integer  BIT_DEPTH = 9,
    parameter integer FFT_SIZE = 1024
    )
    (
    output wire s_ready,
    input wire s_valid,
    input wire m_ready,
    output wire m_valid,
    input wire [C_S_AXIS_TDATA_WIDTH-1 : 0] wdata,
    output wire [C_M_AXIS_TDATA_WIDTH-1 : 0] rdata,
    input wire clk,
    input wire rst,
    output wire m_tlast,
    output wire [1:0] st,
    input wire reset_mod
    );
    localparam fifo_size_actual = FIFO_SIZE * C_S_AXIS_TDATA_WIDTH;

    reg [C_M_AXIS_TDATA_WIDTH-1 : 0] fifo [0 : fifo_size_actual - 1];
    reg [7:0] after_reset_cnt = 0;
    reg [BIT_DEPTH : 0] read_addr = 0, write_addr = 0 ;
    reg [BIT_DEPTH : 0] in_fifo = 0;
    reg [1:0] state;
    reg [9 : 0] subc_cnt  = 0;
    
    reg [C_M_AXIS_TDATA_WIDTH - 1 : 0] data_out = 32'hffffffff;

    wire fifo_wren, fifo_rden;
    
    parameter [1:0] IDLE = 2'h0,        // This is the initial/idle state 
                READ_FIFO = 2'h1,
                INSERT_NULL  = 2'h2,
                HALT   = 2'h3;
                
    assign m_tlast = (subc_cnt == 1023) && (state == INSERT_NULL);//(state == READ_FIFO) && (in_fifo == 1) && (~fifo_wren);
    
    always @(posedge clk) begin
        if(!rst) begin
            state <= IDLE;
            read_addr <= 0;
            subc_cnt <= 0;
        end
        else if(reset_mod) begin
            state <= IDLE;
            read_addr <= 0;
            subc_cnt <= 0;
        end
        else begin
            if(m_ready) begin
            case(state)
                IDLE: 
                    if((in_fifo > 0)) begin
                        state <= INSERT_NULL;
                        data_out <= 32'h00000000;
                    end
                INSERT_NULL: begin
                subc_cnt = subc_cnt + 1;
                    if(((subc_cnt > 0) && (subc_cnt <= 400)) ||
                    ((subc_cnt > 622) && (subc_cnt < 1023))) begin
                        state <= READ_FIFO;
                        data_out <= fifo[read_addr[BIT_DEPTH - 1 : 0]];
                        read_addr <= read_addr + 1;
                        end
                    else begin
                            data_out <= 32'h00000000;
                            state <= INSERT_NULL;
                        end
                    end
                READ_FIFO:
                    if((in_fifo == 0) && ~(subc_cnt == 1023))begin
                        state <= HALT;
                    end
                    else begin 
                        subc_cnt = subc_cnt + 1;
                        if((subc_cnt > 400) && (subc_cnt <= 622 ) || 
                        (subc_cnt == 1023)) begin
                            state <= INSERT_NULL;
                            data_out <= 32'h00000000;
                            
                        end
                        else begin
                            data_out <= fifo[read_addr[BIT_DEPTH - 1 : 0]];
                            read_addr <= read_addr + 1;
                        end
                    end
                HALT:
                    if((in_fifo > 0)) begin
                    subc_cnt = subc_cnt + 1;
                        if(((subc_cnt > 0) && (subc_cnt <= 400)) ||
                            ((subc_cnt > 622) && (subc_cnt < 1023))) begin
                            state <= READ_FIFO;
                            data_out <= fifo[read_addr[BIT_DEPTH - 1 : 0]];
                            read_addr <= read_addr + 1;
                            end
                        else if(subc_cnt == 1023) begin
                            state <= IDLE;
                            data_out <= 32'h00000000;
                            end
                    end
                default: state <= IDLE;
             endcase
             end
        end
        end
                    
    always @(*) begin
        if (!rst) 
        begin
            in_fifo <= 0;
        end
        else if(reset_mod) begin
            in_fifo <= 0;
        end
        else begin
            in_fifo <=  write_addr - read_addr;
        end
    end
    
    assign s_ready = (in_fifo < (fifo_size_actual - C_S_AXIS_TDATA_WIDTH)); // Allow some space in order not to overwrite data
    assign m_valid = (state == READ_FIFO) || (state == INSERT_NULL);

    assign rdata = data_out ;
    
    
    assign fifo_wren = s_ready && s_valid;
    assign fifo_rden = m_ready && m_valid;
    
    reg[8 : 0] bit_index;
       
	    always @( posedge clk )
	    begin
	        if (!rst) 
                begin
                write_addr = 0;
            end
            else if(reset_mod) begin
                write_addr <= 0;
            end
        else 
	      if (fifo_wren)
	        begin
	        for(bit_index=0; bit_index < C_S_AXIS_TDATA_WIDTH; bit_index=bit_index+1)
	          case(wdata[bit_index])
	          1'b0: begin
	               fifo[write_addr[BIT_DEPTH - 1 : 0]  + bit_index ] <= {16'h0000, 16'h8001}; // Real part
	           end
	          1'b1:  begin
	               fifo[write_addr[BIT_DEPTH - 1 : 0]  + bit_index ] <= {16'h0000, 16'h7fff}; // Real part
	           end
	          endcase
	          write_addr = write_addr + C_S_AXIS_TDATA_WIDTH;
	        end  
	    end  
    
endmodule
