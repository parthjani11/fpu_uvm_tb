  // -------------------------------------------------------------------------
  // TC 21: Overflow (both exp == 30, effective add -> +/-Inf, err=0)
  // -------------------------------------------------------------------------
  class tc21_overflow_seq extends fpu_base_seq;
    `uvm_object_utils(tc21_overflow_seq)
    function new(string name="tc21_overflow_seq"); super.new(name); endfunction
    virtual task body();
      logic       sa, sb, op;
      logic [9:0] ma, mb;
      repeat(num_txns) begin
        assert(std::randomize(sa, sb, op, ma, mb) with { (sa ^ sb ^ op) == 1'b0; });
        do_full_op({sa, 5'd30, ma}, {sb, 5'd30, mb}, op);
      end
    endtask
  endclass
