  // -------------------------------------------------------------------------
  // TC 20: Write While Busy (pulse write_en during busy -> ignored)
  // -------------------------------------------------------------------------
  class tc20_write_while_busy_seq extends fpu_base_seq;
    `uvm_object_utils(tc20_write_while_busy_seq)
    function new(string name="tc20_write_while_busy_seq"); super.new(name); endfunction
    virtual task body();
      logic [15:0] a, b;
      logic [7:0]  junk;
      bit          op;
      int          delay_in_busy;
      repeat(num_txns) begin
        a = gen_fp16(FP_NORMAL);
        b = gen_fp16(FP_NORMAL);
        assert(std::randomize(op, junk, delay_in_busy) with { delay_in_busy inside {0, 1}; });

        do_load_operands(a, b);
        repeat(2) drive_cycle(1'b1, {4'h0, op, 1'b1, 2'b00}, 8'h00);
        if (delay_in_busy == 1) drive_cycle(1'b1, 8'h00, 8'h00);
        drive_cycle(1'b1, 8'h01, junk);
        drive_cycle(1'b1, 8'h00, 8'h00);
        do_idle(5);
        do_read_result(2);
      end
    endtask
  endclass
