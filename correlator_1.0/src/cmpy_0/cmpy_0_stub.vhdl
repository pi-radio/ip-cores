-- Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2020.2 (lin64) Build 3064766 Wed Nov 18 09:12:47 MST 2020
-- Date        : Tue Mar  9 11:06:59 2021
-- Host        : linux-p7vy running 64-bit openSUSE Tumbleweed
-- Command     : write_vhdl -force -mode synth_stub /mnt/hdd/projects/ip_repo/correlator_1.0/src/cmpy_0/cmpy_0_stub.vhdl
-- Design      : cmpy_0
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xczu9eg-ffvb1156-2-e
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity cmpy_0 is
  Port ( 
    aclk : in STD_LOGIC;
    s_axis_a_tvalid : in STD_LOGIC;
    s_axis_a_tready : out STD_LOGIC;
    s_axis_a_tdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    s_axis_b_tvalid : in STD_LOGIC;
    s_axis_b_tready : out STD_LOGIC;
    s_axis_b_tdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    m_axis_dout_tvalid : out STD_LOGIC;
    m_axis_dout_tready : in STD_LOGIC;
    m_axis_dout_tdata : out STD_LOGIC_VECTOR ( 31 downto 0 )
  );

end cmpy_0;

architecture stub of cmpy_0 is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "aclk,s_axis_a_tvalid,s_axis_a_tready,s_axis_a_tdata[31:0],s_axis_b_tvalid,s_axis_b_tready,s_axis_b_tdata[31:0],m_axis_dout_tvalid,m_axis_dout_tready,m_axis_dout_tdata[31:0]";
attribute x_core_info : string;
attribute x_core_info of stub : architecture is "cmpy_v6_0_19,Vivado 2020.2";
begin
end;
