  // -------------------------------------------------------------------------
  // Priority Seq 2: Read Enable -> Next Cycle Start (Start Priority on uio_oe)
  // -------------------------------------------------------------------------
  class tc_rd_start_prio_seq extends fpu_base_seq;
    `uvm_object_utils(tc_rd_start_prio_seq)

    function new(string name="tc_rd_start_prio_seq");
      super.new(name);
    endfunction

    virtual task body();
      logic [15:0] op_a, op_b;
      logic [7:0]  st_rd_val;
      bit          op2;

      do_reset(3);

      // 1. Run Op 1: 1.5 (0x3E00) + 2.25 (0x4080) = 3.75 (0x4380)
      do_load_operands(16'h3E00, 16'h4080);
      do_start(1'b0);

      // 2. Read Byte 0 (0x80) normally -> rd_ptr advances 0 -> 1
      do_read_result(1);

      // 3. Overlap window: read_en=1 at T0, then start=1 (opcode=1 SUB) in T1
      drive_cycle(1'b1, 8'h02, 8'h00); // T0: read_en=1, start=0
      drive_cycle(1'b1, 8'h0E, 8'h00); // T1: read_en=1, start=1, opcode=1 (SUB)
      drive_cycle(1'b1, 8'h0E, 8'h00); // T2: hold for synchronized start & opcode
      drive_cycle(1'b1, 8'h02, 8'h00); // T3: keep read_en=1 while busy=1 -> uio_oe MUST be 00
      do_idle(5);                      // T4..T8: drop read_en & wait for done=1

      // 4. Read Op 2 (SUB) result -> confirms start took priority
      do_read_result(2);

      // 5. Repeat with 5 randomized normal FP16 pairs (alternating ADD/SUB)
      repeat(5) begin
        op_a = gen_fp16(FP_NORMAL);
        op_b = gen_fp16(FP_NORMAL);
        assert(std::randomize(op2));
        st_rd_val = {4'h0, op2, 1'b1, 1'b1, 1'b0}; // opcode=op2, start=1, read_en=1

        do_load_operands(op_a, op_b);
        do_start(~op2);
        do_read_result(1);

        drive_cycle(1'b1, 8'h02, 8'h00);
        drive_cycle(1'b1, st_rd_val, 8'h00);
        drive_cycle(1'b1, st_rd_val, 8'h00);
        drive_cycle(1'b1, 8'h02, 8'h00);
        do_idle(5);

        do_read_result(2);
      end
    endtask
  endclass
