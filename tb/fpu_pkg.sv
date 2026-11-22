`timescale 1ns/1ps

// ---------------------------------------------------------
// Package & UVM Components
// (each class lives in its own file, pulled in via `include)
// ---------------------------------------------------------
package fpu_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `define num_of_transaction 10

  `include "sequence_item.sv"
  `include "fp_kind_e.sv"
  `include "fpu_base_seq.sv"
  `include "tc01_reset_seq.sv"
  `include "tc02_byte_write_seq.sv"
  `include "tc03_ready_indication_seq.sv"
  `include "tc04_add_seq.sv"
  `include "tc05_sub_seq.sv"
  `include "tc06_handshake_seq.sv"
  `include "tc07_lat_normal_seq.sv"
  `include "tc08_lat_special_seq.sv"
  `include "tc09_readout_seq.sv"
  `include "tc10_norm_carry_seq.sv"
  `include "tc11_norm_lshift_seq.sv"
  `include "tc12_zero_op_seq.sv"
  `include "tc13_exact_cancel_seq.sv"
  `include "tc14_mixed_seq.sv"
  `include "tc15_inf_seq.sv"
  `include "tc16_nan_seq.sv"
  `include "tc17_denormal_seq.sv"
  `include "tc18_err_clear_seq.sv"
  `include "tc19_start_before_ready_seq.sv"
  `include "tc20_write_while_busy_seq.sv"
  `include "tc21_overflow_seq.sv"
  `include "tc22_underflow_seq.sv"
  `include "tc23_large_exp_diff_seq.sv"
  `include "tc24_b2b_start_seq.sv"
  `include "tc25_partial_reload_seq.sv"
  `include "tc26_reset_during_op_seq.sv"
  `include "driver.sv"
  `include "sequencer.sv"
  `include "inp_monitor.sv"
  `include "out_monitor.sv"
  `include "agent.sv"
  `include "scoreboard.sv"
  `include "subscriber.sv"
  `include "environment.sv"
  `include "fpu_seq_base_test.sv"
  `include "fpu_tc_tests.sv"
  `include "fpu_regression_test.sv"
endpackage
