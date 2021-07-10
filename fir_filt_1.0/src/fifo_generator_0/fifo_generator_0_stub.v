// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2020.2 (lin64) Build 3064766 Wed Nov 18 09:12:47 MST 2020
// Date        : Thu Jun 24 14:29:02 2021
// Host        : linux-p7vy running 64-bit openSUSE Tumbleweed
// Command     : write_verilog -force -mode synth_stub
//               /mnt/hdd/projects/ip_repo/fir_filt_1.0/src/fifo_generator_0/fifo_generator_0_stub.v
// Design      : fifo_generator_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xczu9eg-ffvb1156-2-e
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "fifo_generator_v13_2_5,Vivado 2020.2" *)
module fifo_generator_0(s_aclk, s_aresetn, s_axis_tvalid, 
  s_axis_tready, s_axis_tdata, s_axis_tuser, m_axis_tvalid, m_axis_tready, m_axis_tdata, 
  m_axis_tuser)
/* synthesis syn_black_box black_box_pad_pin="s_aclk,s_aresetn,s_axis_tvalid,s_axis_tready,s_axis_tdata[31:0],s_axis_tuser[3:0],m_axis_tvalid,m_axis_tready,m_axis_tdata[31:0],m_axis_tuser[3:0]" */;
  input s_aclk;
  input s_aresetn;
  input s_axis_tvalid;
  output s_axis_tready;
  input [31:0]s_axis_tdata;
  input [3:0]s_axis_tuser;
  output m_axis_tvalid;
  input m_axis_tready;
  output [31:0]m_axis_tdata;
  output [3:0]m_axis_tuser;
endmodule
