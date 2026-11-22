  // -------------------------------------------------------------------------
  // TC 8: Latency - Special Case (3 cycles / 120 ns: Zero, Inf, NaN, Denorm)
  // -------------------------------------------------------------------------
  class tc08_lat_special_seq extends fpu_base_seq;
    `uvm_object_utils(tc08_lat_special_seq)
    function new(string name="tc08_lat_special_seq"); super.new(name); endfunction
    virtual task body();
      do_full_op(gen_fp16(FP_ZERO),   gen_fp16(FP_NORMAL), 1'b0);
      do_full_op(gen_fp16(FP_NORMAL), gen_fp16(FP_ZERO),   1'b1);
      do_full_op(gen_fp16(FP_INF),    gen_fp16(FP_NORMAL), 1'b0);
      do_full_op(gen_fp16(FP_NAN),    gen_fp16(FP_NORMAL), 1'b1);
      do_full_op(gen_fp16(FP_DENORM), gen_fp16(FP_NORMAL), 1'b0);
    endtask
  endclass
