# Copyright 2020 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51

proc target_01 {} {
  global occ_hw_server
  global occ_target_serial
  global occ_hw_device
  set occ_hw_server bordcomputer:3231
  set occ_target_serial 091847100576A
  set occ_hw_device xcvu37p_0
}

proc occ_connect { } {
    global occ_hw_server
    global occ_target_serial
    global occ_hw_device
    open_hw_manager
    connect_hw_server -url ${occ_hw_server} -allow_non_jtag
    current_hw_target [get_hw_targets */xilinx_tcf/Xilinx/${occ_target_serial}]
    set_property PARAM.FREQUENCY 15000000 [get_hw_targets */xilinx_tcf/Xilinx/${occ_target_serial}]
    open_hw_target
    current_hw_device [get_hw_devices ${occ_hw_device}]
    refresh_hw_device -update_hw_probes false [lindex [get_hw_devices ${occ_hw_device}] 0]
}

proc occ_program_bit {bit ltx} {
    global occ_hw_device
    global bit_stem_ap
    set_property PROBES.FILE "${ltx}" [get_hw_devices ${occ_hw_device}]
    set_property FULL_PROBES.FILE "${ltx}" [get_hw_devices ${occ_hw_device}]
    set_property PROGRAM.FILE "${bit}" [get_hw_devices ${occ_hw_device}]
    program_hw_devices [get_hw_devices ${occ_hw_device}]
    refresh_hw_device [lindex [get_hw_devices ${occ_hw_device}] 0]
}

proc occ_program {bit ltx} {
    occ_program_bit occamy_vcu128/occamy_vcu128.runs/impl_1/occamy_vcu128_wrapper.bit occamy_vcu128/occamy_vcu128.runs/impl_1/occamy_vcu128_wrapper.ltx
}

proc occ_rst { } {
    global occ_hw_device
    set vio_sys [get_hw_vios -of_objects [get_hw_devices ${occ_hw_device}] -filter {CELL_NAME=~"*vio_sys"}]
    set_property OUTPUT_VALUE 0 [get_hw_probes */occamy_rstn -of_objects $vio_sys]
    commit_hw_vio [get_hw_probes {*/occamy_rstn} -of_objects $vio_sys]
}
proc occ_go { } {
    global occ_hw_device
    set vio_sys [get_hw_vios -of_objects [get_hw_devices ${occ_hw_device}] -filter {CELL_NAME=~"*vio_sys"}]
    set_property OUTPUT_VALUE 1 [get_hw_probes */occamy_rstn -of_objects $vio_sys]
    commit_hw_vio [get_hw_probes {*/occamy_rstn} -of_objects $vio_sys]
}

proc occ_rst_toggle { } {
    occ_rst
    occ_go
}

proc occ_flash_bootrom { } {
    global occ_hw_device
    occ_rst
    refresh_hw_device [lindex [get_hw_devices ${occ_hw_device}] 0]
    source bootrom/bootrom.tcl
    after 100
    occ_go
}