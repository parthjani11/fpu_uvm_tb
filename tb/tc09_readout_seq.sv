  // -------------------------------------------------------------------------
  // TC 9: Result Byte Readout (LSB then MSB, uio_oe=FF only while read_en=1)
  // -------------------------------------------------------------------------
  class tc09_readout_seq extends fpu_base_seq;
    `uvm_object_utils(tc09_readout_seq)
    function new(string name="tc09_readout_seq"); super.new(name); endfunction
    virtual task body();
      do_full_op(16'h3E00, 16'h4080, 1'b0);
      repeat(5) do_full_op(gen_fp16(FP_NORMAL), gen_fp16(FP_NORMAL), 1'b0);
    endtask
  endclass
