  // -------------------------------------------------------------------------
  // TC 26: Reset During Operation (mid-write, mid-busy, mid-readout)
  // -------------------------------------------------------------------------
  class tc26_reset_during_op_seq extends fpu_base_seq;
    `uvm_object_utils(tc26_reset_during_op_seq)
    function new(string name="tc26_reset_during_op_seq"); super.new(name); endfunction
    virtual task body();
      int          partial_wr, busy_dly;
      logic [7:0]  rand_b;

      // 1. Reset after random number of written bytes (1..3)
      do_reset(3);
      assert(std::randomize(partial_wr) with { partial_wr inside {[1:3]}; });
      repeat(partial_wr) begin
        assert(std::randomize(rand_b));
        do_write_byte(rand_b);
      end
      do_reset(3);
      do_full_op(gen_fp16(FP_NORMAL), gen_fp16(FP_NORMAL), 1'b0);

      // 2. Reset at a random cycle during busy
      do_load_operands(gen_fp16(FP_NORMAL), gen_fp16(FP_NORMAL));
      repeat(2) drive_cycle(1'b1, 8'h04, 8'h00);
      assert(std::randomize(busy_dly) with { busy_dly inside {[0:2]}; });
      do_idle(busy_dly);
      do_reset(3);
      do_full_op(gen_fp16(FP_NORMAL), gen_fp16(FP_NORMAL), 1'b1);

      // 3. Reset midway through readout (after Byte 0)
      do_load_operands(gen_fp16(FP_NORMAL), gen_fp16(FP_NORMAL));
      do_start(1'b0);
      repeat(2) drive_cycle(1'b1, 8'h02, 8'h00);
      do_reset(3);
      do_full_op(gen_fp16(FP_NORMAL), gen_fp16(FP_NORMAL), 1'b0);
    endtask
  endclass
