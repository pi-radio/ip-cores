// Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2020.2 (lin64) Build 3064766 Wed Nov 18 09:12:47 MST 2020
// Date        : Tue Jun 15 14:46:04 2021
// Host        : linux-p7vy running 64-bit openSUSE Tumbleweed
// Command     : write_verilog -force -mode synth_stub
//               /mnt/hdd/projects/ip_repo/channel_emulator_1.0/src/freq_off_mult_0/freq_off_mult_0_stub.v
// Design      : freq_off_mult_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xczu9eg-ffvb1156-2-e
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "cmpy_v6_0_19,Vivado 2020.2" *)
module freq_off_mult_0(aclk, aresetn, s_axis_a_tvalid, 
  s_axis_a_tready, s_axis_a_tdata, s_axis_b_tvalid, s_axis_b_tready, s_axis_b_tdata, 
  m_axis_dout_tvalid, m_axis_dout_tready, m_axis_dout_tdata)
/* synthesis syn_black_box black_box_pad_pin="aclk,aresetn,s_axis_a_tvalid,s_axis_a_tready,s_axis_a_tdata[31:0],s_axis_b_tvalid,s_axis_b_tready,s_axis_b_tdata[31:0],m_axis_dout_tvalid,m_axis_dout_tready,m_axis_dout_tdata[79:0]" */;
  input aclk;
  input aresetn;
  input s_axis_a_tvalid;
  output s_axis_a_tready;
  input [31:0]s_axis_a_tdata;
  input s_axis_b_tvalid;
  output s_axis_b_tready;
  input [31:0]s_axis_b_tdata;
  output m_axis_dout_tvalid;
  input m_axis_dout_tready;
  output [79:0]m_axis_dout_tdata;
endmodule
