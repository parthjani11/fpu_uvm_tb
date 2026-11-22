  // -------------------------------------------------------------------------
  // TC 15: Infinity Input (A, B, or both)
  // -------------------------------------------------------------------------
  class tc15_inf_seq extends fpu_base_seq;
    `uvm_object_utils(tc15_inf_seq)
    function new(string name="tc15_inf_seq"); super.new(name); endfunction
    virtual task body();
      bit op;
      int mode;
      repeat(num_txns) begin
        assert(std::randomize(op, mode) with { mode inside {0, 1, 2}; });
        if (mode == 0)      do_full_op(gen_fp16(FP_INF),    gen_fp16(FP_NORMAL), op);
        else if (mode == 1) do_full_op(gen_fp16(FP_NORMAL), gen_fp16(FP_INF),    op);
        else                do_full_op(gen_fp16(FP_INF),    gen_fp16(FP_INF),    op);
      end
    endtask
  endclass
