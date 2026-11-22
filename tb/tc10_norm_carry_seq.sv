  // -------------------------------------------------------------------------
  // TC 10: Normalization - Carry (equal exp, effective add -> carry out)
  // -------------------------------------------------------------------------
  class tc10_norm_carry_seq extends fpu_base_seq;
    `uvm_object_utils(tc10_norm_carry_seq)
    function new(string name="tc10_norm_carry_seq"); super.new(name); endfunction
    virtual task body();
      logic       sa, sb, op;
      logic [4:0] e;
      logic [9:0] ma, mb;
      repeat(num_txns) begin
        assert(std::randomize(sa, sb, op, e, ma, mb) with {
          e inside {[5'd1 : 5'd29]};
          (sa ^ sb ^ op) == 1'b0;
        });
        do_full_op({sa, e, ma}, {sb, e, mb}, op);
      end
    endtask
  endclass
