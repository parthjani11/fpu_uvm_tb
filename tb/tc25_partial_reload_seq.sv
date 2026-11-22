  // -------------------------------------------------------------------------
  // TC 25: Start With Partial Reload (write 1..3 new bytes, then start)
  // -------------------------------------------------------------------------
  class tc25_partial_reload_seq extends fpu_base_seq;
    `uvm_object_utils(tc25_partial_reload_seq)
    function new(string name="tc25_partial_reload_seq"); super.new(name); endfunction
    virtual task body();
      int         n_bytes;
      logic [7:0] new_byte;
      bit         op;

      do_reset(3);
      do_full_op(gen_fp16(FP_NORMAL), gen_fp16(FP_NORMAL), 1'b0);

      for (int k = 1; k <= 3; k++) begin
        n_bytes = k;
        repeat(n_bytes) begin
          assert(std::randomize(new_byte));
          do_write_byte(new_byte);
        end
        assert(std::randomize(op));
        do_start(op);
        do_read_result(2);
      end
      do_reset(3);
    endtask
  endclass
