`timescale 1ns / 1ps


module data_module #
        (
        parameter integer SYMBOLS_PER_FRAME = 10,
        parameter integer USED_CARRIERS = 800,
        parameter integer PILOT_DENSITY = 5,
        parameter integer M_AXIS_TDATA_WIDTH = 40,
        parameter integer S_AXIS_TDATA_WIDTH = 32
        )
        (
    	input wire  s_axis_data_aclk,
		input wire  s_axis_data_aresetn,
		output wire  s_axis_data_tready,
		input wire [S_AXIS_TDATA_WIDTH-1 : 0] s_axis_data_tdata,
		input wire [(S_AXIS_TDATA_WIDTH/8)-1 : 0] s_axis_data_tstrb,
		input wire  s_axis_data_tlast,
		input wire  s_axis_data_tvalid,
        input wire [799 : 0] sync_word,
        input wire sync_word_ready,
		output wire  m_axis_data_tvalid,
		output wire [M_AXIS_TDATA_WIDTH-1 : 0] m_axis_data_tdata,
		output wire [(M_AXIS_TDATA_WIDTH/8)-1 : 0] m_axis_data_tstrb,
		output wire  m_axis_data_tlast,
		input wire  m_axis_data_tready
    );
    reg [9 : 0] subc_cnt = 0;
    reg [9 : 0] symbol_cnt = 0;
    reg [39 : 0] data_out;
    reg initial_setup = 1;
    wire init_done;
    reg[5 : 0] bit_index;
    wire state_sync_word;
    wire [5 : 0] current_length;
    
    
    assign init_done = !initial_setup && sync_word_ready;
    assign m_axis_data_tdata = (symbol_cnt == 0) ? sync_word[subc_cnt +: S_AXIS_TDATA_WIDTH]
                                                 :  data_out;
    assign m_axis_data_tstrb[0] = (symbol_cnt == 0) ? 1 : 0;
    assign m_axis_data_tstrb[(M_AXIS_TDATA_WIDTH/8)-1 : 1] = 0;
    assign s_axis_data_tready = init_done && (symbol_cnt != 0) && m_axis_data_tready;
    assign m_axis_data_tvalid = init_done && (symbol_cnt == 0 || s_axis_data_tvalid);
    
    assign data_out[4 : 1] = s_axis_data_tdata[3 : 0];
    assign data_out[9 : 6] = s_axis_data_tdata[7 : 4];
    assign data_out[14 : 11] = s_axis_data_tdata[11 : 8];
    assign data_out[19 : 16] = s_axis_data_tdata[15 : 12];
    assign data_out[24 : 21] = s_axis_data_tdata[19 : 16];
    assign data_out[29 : 26] = s_axis_data_tdata[23 : 20];
    assign data_out[34 : 31] = s_axis_data_tdata[27 : 24];
    assign data_out[39 : 36] = s_axis_data_tdata[31 : 28];
    
    assign state_sync_word = (symbol_cnt == 0);
    assign current_length = (state_sync_word) ? S_AXIS_TDATA_WIDTH : M_AXIS_TDATA_WIDTH;
    
    always@(posedge s_axis_data_aclk) begin
        if(!s_axis_data_aresetn)
            initial_setup <= 1;
        else
            if(initial_setup) begin
                for(bit_index=0; bit_index < M_AXIS_TDATA_WIDTH; bit_index=bit_index + PILOT_DENSITY) begin
                    if(bit_index % (2 * PILOT_DENSITY) == 0)
                        data_out[bit_index] <= 1;
                    else if(bit_index % (2 * PILOT_DENSITY) == PILOT_DENSITY)
                        data_out[bit_index] <= 0;
                end
                initial_setup <= 0;
            end
    end
    
     always@(posedge s_axis_data_aclk) begin
        if(!s_axis_data_aresetn)
            symbol_cnt <= 0;
        else begin
            if((subc_cnt == (USED_CARRIERS - current_length)) && init_done && (symbol_cnt == 0 || s_axis_data_tvalid) && m_axis_data_tready)
                if(symbol_cnt < SYMBOLS_PER_FRAME - 1)
                    symbol_cnt <= symbol_cnt + 1;
                else
                    symbol_cnt <= 0;
        end
     end
     
     always@(posedge s_axis_data_aclk) begin
        if(!s_axis_data_aresetn)
            subc_cnt <= 0;
        else begin
            if(init_done && (symbol_cnt == 0 || s_axis_data_tvalid) && m_axis_data_tready)
                if(subc_cnt < (USED_CARRIERS - current_length))
                    subc_cnt <= subc_cnt + current_length;
                else
                    subc_cnt <= 0;
        end
     end
    
    
endmodule
