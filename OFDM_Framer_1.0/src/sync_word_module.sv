`timescale 1ns / 1ps


module sync_word_module#
        ( 
        parameter integer USED_CARRIERS = 800,
        parameter integer S_AXIS_TDATA_WIDTH = 32
        )
        (
    	input wire  s_axis_config_aclk,
		input wire  s_axis_config_aresetn,
		output wire  s_axis_config_tready,
		input wire [S_AXIS_TDATA_WIDTH-1 : 0] s_axis_config_tdata,
		input wire [(S_AXIS_TDATA_WIDTH/8)-1 : 0] s_axis_config_tstrb,
		input wire  s_axis_config_tlast,
		input wire  s_axis_config_tvalid,
		output reg [799 : 0] sync_word
    );
    assign s_axis_config_tready = (sync_word_count < USED_CARRIERS);
    
    reg [10 : 0] sync_word_count = 0;
    
    always @(posedge s_axis_config_aclk) begin
        if ( s_axis_config_aresetn == 1'b0 ) begin
            sync_word_count <= 0;
        end
        else begin
            if(s_axis_config_tvalid && s_axis_config_tready) begin
                sync_word[sync_word_count +: 32] = s_axis_config_tdata;
                sync_word_count = sync_word_count + 32;
            end
        end
    end
endmodule
