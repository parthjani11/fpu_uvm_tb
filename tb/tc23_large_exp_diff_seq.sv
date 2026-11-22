  // -------------------------------------------------------------------------
  // TC 23: Large Exponent Difference (|exp_a - exp_b| in 11..29)
  // -------------------------------------------------------------------------
  class tc23_large_exp_diff_seq extends fpu_base_seq;
    `uvm_object_utils(tc23_large_exp_diff_seq)
    function new(string name="tc23_large_exp_diff_seq"); super.new(name); endfunction
    virtual task body();
      logic [15:0] a, b;
      bit op;
      repeat(num_txns) begin
        assert(std::randomize(a, b, op) with {
          a[14:10] inside {[5'd1 : 5'd30]};
          b[14:10] inside {[5'd1 : 5'd30]};
          (a[14:10] >= b[14:10] + 5'd11) || (b[14:10] >= a[14:10] + 5'd11);
        });
        do_full_op(a, b, op);
      end
    endtask
  endclass
