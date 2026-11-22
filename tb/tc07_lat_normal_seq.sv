  // -------------------------------------------------------------------------
  // TC 7: Latency - Normal Operation (4 cycles / 160 ns)
  // -------------------------------------------------------------------------
  class tc07_lat_normal_seq extends fpu_base_seq;
    `uvm_object_utils(tc07_lat_normal_seq)
    function new(string name="tc07_lat_normal_seq"); super.new(name); endfunction
    virtual task body();
      bit op;
      repeat(num_txns) begin
        assert(std::randomize(op));
        do_full_op(gen_fp16(FP_NORMAL), gen_fp16(FP_NORMAL), op);
      end
    endtask
  endclass
