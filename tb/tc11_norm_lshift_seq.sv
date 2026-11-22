  // -------------------------------------------------------------------------
  // TC 11: Normalization - Left Shift (equal exp, close operands, eff sub)
  // -------------------------------------------------------------------------
  class tc11_norm_lshift_seq extends fpu_base_seq;
    `uvm_object_utils(tc11_norm_lshift_seq)
    function new(string name="tc11_norm_lshift_seq"); super.new(name); endfunction
    virtual task body();
      logic       sa, sb, op;
      logic [4:0] e;
      logic [9:0] ma, mb;
      repeat(num_txns) begin
        assert(std::randomize(sa, sb, op, e, ma, mb) with {
          e inside {[5'd12 : 5'd30]};
          ma != mb;
          (sa ^ sb ^ op) == 1'b1;
        });
        do_full_op({sa, e, ma}, {sb, e, mb}, op);
      end
    endtask
  endclass
