  // -------------------------------------------------------------------------
  // TC 16: NaN Input (A, B, or both)
  // -------------------------------------------------------------------------
  class tc16_nan_seq extends fpu_base_seq;
    `uvm_object_utils(tc16_nan_seq)
    function new(string name="tc16_nan_seq"); super.new(name); endfunction
    virtual task body();
      bit op;
      int mode;
      repeat(num_txns) begin
        assert(std::randomize(op, mode) with { mode inside {0, 1, 2}; });
        if (mode == 0)      do_full_op(gen_fp16(FP_NAN),    gen_fp16(FP_NORMAL), op);
        else if (mode == 1) do_full_op(gen_fp16(FP_NORMAL), gen_fp16(FP_NAN),    op);
        else                do_full_op(gen_fp16(FP_NAN),    gen_fp16(FP_NAN),    op);
      end
    endtask
  endclass
