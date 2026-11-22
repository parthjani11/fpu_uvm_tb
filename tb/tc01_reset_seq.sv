  // -------------------------------------------------------------------------
  // TC 1: Reset Handling (in idle & after completed operation)
  // -------------------------------------------------------------------------
  class tc01_reset_seq extends fpu_base_seq;
    `uvm_object_utils(tc01_reset_seq)
    function new(string name="tc01_reset_seq"); super.new(name); endfunction
    virtual task body();
      do_reset(3);
      do_full_op(gen_fp16(FP_NORMAL), gen_fp16(FP_NORMAL), 1'b0);
      do_reset(3);
      do_full_op(gen_fp16(FP_NORMAL), gen_fp16(FP_NORMAL), 1'b1);
    endtask
  endclass
