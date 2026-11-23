  class fpu_regression_test extends fpu_seq_base_test;
    `uvm_component_utils(fpu_regression_test)

    function new(string name = "fpu_regression_test", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
      phase.raise_objection(this);

      run_seq(tc01_reset_seq::type_id::create("s01"),              "TC01: Reset Handling");
      run_seq(tc02_byte_write_seq::type_id::create("s02"),         "TC02: Operand Byte Write");
      run_seq(tc03_ready_indication_seq::type_id::create("s03"),   "TC03: Ready Indication");
      run_seq(tc04_add_seq::type_id::create("s04"),                "TC04: Addition");
      run_seq(tc05_sub_seq::type_id::create("s05"),                "TC05: Subtraction");
      run_seq(tc06_handshake_seq::type_id::create("s06"),          "TC06: Start-Busy-Done Handshake");
      run_seq(tc07_lat_normal_seq::type_id::create("s07"),         "TC07: Latency - Normal");
      run_seq(tc08_lat_special_seq::type_id::create("s08"),        "TC08: Latency - Special");
      run_seq(tc09_readout_seq::type_id::create("s09"),            "TC09: Result Byte Readout");
      run_seq(tc10_norm_carry_seq::type_id::create("s10"),         "TC10: Normalization - Carry");
      run_seq(tc11_norm_lshift_seq::type_id::create("s11"),        "TC11: Normalization - Left Shift");
      run_seq(tc12_zero_op_seq::type_id::create("s12"),            "TC12: Zero Operand Handling");
      run_seq(tc13_exact_cancel_seq::type_id::create("s13"),       "TC13: Exact Cancellation");
      run_seq(tc14_mixed_seq::type_id::create("s14"),              "TC14: Random Special/Normal Mix");
      run_seq(tc15_inf_seq::type_id::create("s15"),                "TC15: Infinity Input");
      run_seq(tc16_nan_seq::type_id::create("s16"),                "TC16: NaN Input");
      run_seq(tc17_denormal_seq::type_id::create("s17"),           "TC17: Denormal Input");
      run_seq(tc18_err_clear_seq::type_id::create("s18"),          "TC18: Error Flag Clear");
      run_seq(tc19_start_before_ready_seq::type_id::create("s19"), "TC19: Start Before Ready");
      run_seq(tc20_write_while_busy_seq::type_id::create("s20"),   "TC20: Write While Busy");
      run_seq(tc21_overflow_seq::type_id::create("s21"),           "TC21: Overflow");
      run_seq(tc22_underflow_seq::type_id::create("s22"),          "TC22: Underflow");
      run_seq(tc23_large_exp_diff_seq::type_id::create("s23"),     "TC23: Large Exponent Difference");
      run_seq(tc24_b2b_start_seq::type_id::create("s24"),          "TC24: Back-to-Back Start");
      run_seq(tc25_partial_reload_seq::type_id::create("s25"),     "TC25: Start With Partial Reload");
      run_seq(tc26_reset_during_op_seq::type_id::create("s26"),    "TC26: Reset During Operation");
      run_seq(tc_rd_wr_prio_seq::type_id::create("s27"),           "TC27: Read->Write Priority on OE");
      run_seq(tc_rd_start_prio_seq::type_id::create("s28"),        "TC28: Read->Start Priority on OE");

      #200;
      phase.drop_objection(this);
    endtask
  endclass
