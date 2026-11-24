  // -------------------------------------------------------------------------
  // Reserved Input Seq: drive every value on ui_in[7:4] (must not affect the DUT)
  // -------------------------------------------------------------------------
  class tc_rsvd_ui_in_seq extends fpu_base_seq;
    `uvm_object_utils(tc_rsvd_ui_in_seq)
    function new(string name="tc_rsvd_ui_in_seq"); super.new(name); endfunction
    virtual task body();
      for (int i = 0; i < 16; i++) begin
        repeat(2) drive_cycle(1'b1, {i[3:0], 4'h0}, 8'h00);  // ui_in[7:4] = i
        repeat(2) drive_cycle(1'b1, 8'h00, 8'h00);           // back to 0
      end
      repeat(num_txns)
        do_full_op(gen_fp16(FP_NORMAL), gen_fp16(FP_NORMAL), 1'b0);
    endtask
  endclass
 