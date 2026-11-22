  // -------------------------------------------------------------------------
  // TC 24: Back-to-Back Start Without Reload (1..5 restarts, random reads)
  // -------------------------------------------------------------------------
  class tc24_b2b_start_seq extends fpu_base_seq;
    `uvm_object_utils(tc24_b2b_start_seq)
    function new(string name="tc24_b2b_start_seq"); super.new(name); endfunction
    virtual task body();
      int n_restarts;
      bit do_rd;
      do_load_operands(gen_fp16(FP_NORMAL), gen_fp16(FP_NORMAL));
      do_start(1'b0);
      do_read_result(2);

      assert(std::randomize(n_restarts) with { n_restarts inside {[1:5]}; });
      repeat(n_restarts) begin
        do_start(1'b0);
        assert(std::randomize(do_rd));
        if (do_rd) do_read_result(2);
      end
      do_read_result(2);
    endtask
  endclass
