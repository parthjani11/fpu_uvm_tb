  // -------------------------------------------------------------------------
  // TC 18: Error Flag Clear (invalid & valid mixed back-to-back without reset)
  // -------------------------------------------------------------------------
  class tc18_err_clear_seq extends fpu_base_seq;
    `uvm_object_utils(tc18_err_clear_seq)
    function new(string name="tc18_err_clear_seq"); super.new(name); endfunction
    virtual task body();
      fp_kind_e err_k;
      bit op;
      repeat(6) begin
        assert(std::randomize(err_k, op) with { err_k inside {FP_INF, FP_NAN, FP_DENORM}; });
        do_full_op(gen_fp16(err_k),     gen_fp16(FP_NORMAL), op);
        do_full_op(gen_fp16(FP_NORMAL), gen_fp16(FP_NORMAL), ~op);
      end
    endtask
  endclass
