  // -------------------------------------------------------------------------
  // TC 22: Underflow (equal small exp, close mantissas, eff sub -> +/-0.0)
  // -------------------------------------------------------------------------
  class tc22_underflow_seq extends fpu_base_seq;
    `uvm_object_utils(tc22_underflow_seq)
    function new(string name="tc22_underflow_seq"); super.new(name); endfunction
    virtual task body();
      logic        sa, sb, op, swap_ab;
      logic [4:0]  e;
      int unsigned max_diff, diff, base;
      logic [9:0]  ma, mb;
      repeat(num_txns) begin
        assert(std::randomize(sa, sb, op, e, swap_ab) with {
          e inside {[5'd1 : 5'd5]};
          (sa ^ sb ^ op) == 1'b1;
        });
        max_diff = (1 << (11 - e)) - 1;
        assert(std::randomize(diff) with { diff inside {[1 : max_diff]}; });
        assert(std::randomize(base) with { base <= (1023 - diff); });
        ma = swap_ab ? 10'(base + diff) : 10'(base);
        mb = swap_ab ? 10'(base)        : 10'(base + diff);
        do_full_op({sa, e, ma}, {sb, e, mb}, op);
      end
    endtask
  endclass
