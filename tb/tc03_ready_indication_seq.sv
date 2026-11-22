  // -------------------------------------------------------------------------
  // TC 3: Ready Indication (low during partial load, high on 4th byte)
  // -------------------------------------------------------------------------
  class tc03_ready_indication_seq extends fpu_base_seq;
    `uvm_object_utils(tc03_ready_indication_seq)
    function new(string name="tc03_ready_indication_seq"); super.new(name); endfunction
    virtual task body();
      repeat(3) begin
        do_reset(3);
        do_full_op(gen_fp16(FP_NORMAL), gen_fp16(FP_NORMAL), 1'b0);
      end
    endtask
  endclass
