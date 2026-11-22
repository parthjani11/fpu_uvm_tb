  // -------------------------------------------------------------------------
  // TC 5: Subtraction (random normal operands, opcode = 1)
  // -------------------------------------------------------------------------
  class tc05_sub_seq extends fpu_base_seq;
    `uvm_object_utils(tc05_sub_seq)
    function new(string name="tc05_sub_seq"); super.new(name); endfunction
    virtual task body();
      repeat(num_txns)
        do_full_op(gen_fp16(FP_NORMAL), gen_fp16(FP_NORMAL), 1'b1);
    endtask
  endclass
