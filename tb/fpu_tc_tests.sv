  `define DEFINE_FPU_TEST(TEST_NAME, SEQ_TYPE) \
    class TEST_NAME extends fpu_seq_base_test; \
      `uvm_component_utils(TEST_NAME) \
      function new(string name = `"TEST_NAME`", uvm_component parent = null); \
        super.new(name, parent); \
      endfunction \
      virtual task run_phase(uvm_phase phase); \
        SEQ_TYPE seq; \
        phase.raise_objection(this); \
        seq = SEQ_TYPE::type_id::create("seq"); \
        run_seq(seq, `"TEST_NAME`"); \
        #200; \
        phase.drop_objection(this); \
      endtask \
    endclass

  `DEFINE_FPU_TEST(tc01_reset_test,              tc01_reset_seq)
  `DEFINE_FPU_TEST(tc02_byte_write_test,         tc02_byte_write_seq)
  `DEFINE_FPU_TEST(tc03_ready_indication_test,   tc03_ready_indication_seq)
  `DEFINE_FPU_TEST(tc04_add_test,                tc04_add_seq)
  `DEFINE_FPU_TEST(tc05_sub_test,                tc05_sub_seq)
  `DEFINE_FPU_TEST(tc06_handshake_test,          tc06_handshake_seq)
  `DEFINE_FPU_TEST(tc07_lat_normal_test,         tc07_lat_normal_seq)
  `DEFINE_FPU_TEST(tc08_lat_special_test,        tc08_lat_special_seq)
  `DEFINE_FPU_TEST(tc09_readout_test,            tc09_readout_seq)
  `DEFINE_FPU_TEST(tc10_norm_carry_test,         tc10_norm_carry_seq)
  `DEFINE_FPU_TEST(tc11_norm_lshift_test,        tc11_norm_lshift_seq)
  `DEFINE_FPU_TEST(tc12_zero_op_test,            tc12_zero_op_seq)
  `DEFINE_FPU_TEST(tc13_exact_cancel_test,       tc13_exact_cancel_seq)
  `DEFINE_FPU_TEST(tc14_mixed_test,              tc14_mixed_seq)
  `DEFINE_FPU_TEST(tc15_inf_test,                tc15_inf_seq)
  `DEFINE_FPU_TEST(tc16_nan_test,                tc16_nan_seq)
  `DEFINE_FPU_TEST(tc17_denormal_test,           tc17_denormal_seq)
  `DEFINE_FPU_TEST(tc18_err_clear_test,          tc18_err_clear_seq)
  `DEFINE_FPU_TEST(tc19_start_before_ready_test, tc19_start_before_ready_seq)
  `DEFINE_FPU_TEST(tc20_write_while_busy_test,   tc20_write_while_busy_seq)
  `DEFINE_FPU_TEST(tc21_overflow_test,           tc21_overflow_seq)
  `DEFINE_FPU_TEST(tc22_underflow_test,          tc22_underflow_seq)
  `DEFINE_FPU_TEST(tc23_large_exp_diff_test,     tc23_large_exp_diff_seq)
  `DEFINE_FPU_TEST(tc24_b2b_start_test,          tc24_b2b_start_seq)
  `DEFINE_FPU_TEST(tc25_partial_reload_test,     tc25_partial_reload_seq)
  `DEFINE_FPU_TEST(tc26_reset_during_op_test,    tc26_reset_during_op_seq)
  `DEFINE_FPU_TEST(tc_rd_wr_prio_test,           tc_rd_wr_prio_seq)
  `DEFINE_FPU_TEST(tc_rd_start_prio_test,        tc_rd_start_prio_seq)
  `DEFINE_FPU_TEST(tc_rsvd_ui_in_test,           tc_rsvd_ui_in_seq)
  `DEFINE_FPU_TEST(tc_wr_start_same_test,        tc_wr_start_same_seq)
  `DEFINE_FPU_TEST(tc_wr_lvl_rd_trig_test,       tc_wr_lvl_rd_trig_seq)