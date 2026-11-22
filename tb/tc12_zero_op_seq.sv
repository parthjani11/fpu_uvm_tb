  // -------------------------------------------------------------------------
  // TC 12: Zero Operand Handling (+0/-0 in A, B, or both; random opcode)
  // -------------------------------------------------------------------------
  class tc12_zero_op_seq extends fpu_base_seq;
    `uvm_object_utils(tc12_zero_op_seq)
    function new(string name="tc12_zero_op_seq"); super.new(name); endfunction
    virtual task body();
      bit op;
      int pos;
      repeat(num_txns) begin
        assert(std::randomize(op, pos) with { pos inside {0, 1, 2}; });
        if (pos == 0)      do_full_op(gen_fp16(FP_ZERO),   gen_fp16(FP_NORMAL), op);
        else if (pos == 1) do_full_op(gen_fp16(FP_NORMAL), gen_fp16(FP_ZERO),   op);
        else               do_full_op(gen_fp16(FP_ZERO),   gen_fp16(FP_ZERO),   op);
      end
    endtask
  endclass
