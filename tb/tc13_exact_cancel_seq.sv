  // -------------------------------------------------------------------------
  // TC 13: Exact Cancellation (A - A or A + (-A) -> 0x0000)
  // -------------------------------------------------------------------------
  class tc13_exact_cancel_seq extends fpu_base_seq;
    `uvm_object_utils(tc13_exact_cancel_seq)
    function new(string name="tc13_exact_cancel_seq"); super.new(name); endfunction
    virtual task body();
      logic [15:0] a, b;
      bit op;
      repeat(num_txns) begin
        a = gen_fp16(FP_NORMAL);
        assert(std::randomize(op));
        b = (op == 1'b1) ? a : {~a[15], a[14:0]};
        do_full_op(a, b, op);
      end
    endtask
  endclass
