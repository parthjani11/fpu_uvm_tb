  // -------------------------------------------------------------------------
  // TC 4: Addition (random normal operands, opcode = 0)
  // -------------------------------------------------------------------------
  class tc04_add_seq extends fpu_base_seq;
    `uvm_object_utils(tc04_add_seq)
    function new(string name="tc04_add_seq"); super.new(name); endfunction
    virtual task body();
      repeat(num_txns)
        do_full_op(gen_fp16(FP_NORMAL), gen_fp16(FP_NORMAL), 1'b0);
    endtask
  endclass
