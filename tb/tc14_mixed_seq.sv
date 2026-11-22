  // -------------------------------------------------------------------------
  // TC 14: Random Special and Normal Mix
  // -------------------------------------------------------------------------
  class tc14_mixed_seq extends fpu_base_seq;
    `uvm_object_utils(tc14_mixed_seq)
    function new(string name="tc14_mixed_seq"); super.new(name); endfunction
    virtual task body();
      fp_kind_e ka, kb;
      bit op;
      repeat(num_txns * 2) begin
        assert(std::randomize(ka, kb, op));
        do_full_op(gen_fp16(ka), gen_fp16(kb), op);
      end
    endtask
  endclass
