  // -------------------------------------------------------------------------
  // Priority Seq 1: Read Enable -> Next Cycle Write Enable (Write Priority on uio_oe)
  // -------------------------------------------------------------------------
  class tc_rd_wr_prio_seq extends fpu_base_seq;
    `uvm_object_utils(tc_rd_wr_prio_seq)

    function new(string name="tc_rd_wr_prio_seq");
      super.new(name);
    endfunction

    virtual task body();
      logic [15:0] op_a2, op_b2;
      bit          op2;

      do_reset(3);

      // 1. Run Op 1: 1.5 (0x3E00) + 2.25 (0x4080) = 3.75 (0x4380)
      do_load_operands(16'h3E00, 16'h4080);
      do_start(1'b0);

      // 2. Read Byte 0 (0x80) normally -> rd_ptr advances 0 -> 1
      do_read_result(1);

      // 3. Prepare Op 2 with distinct, non-zero bytes so Byte 0 write is verifiable
      op_a2 = 16'h3E55;
      op_b2 = 16'h40AA;
      op2   = 1'b1;

      // 4. Overlap window: read_en=1 at T0, then write_en=1 in T1 while read_en=1
      drive_cycle(1'b1, 8'h02, 8'h00);       // T0: read_en=1, write_en=0
      drive_cycle(1'b1, 8'h03, op_a2[7:0]);  // T1: read_en=1, write_en=1 (Byte 0)
      drive_cycle(1'b1, 8'h03, op_a2[7:0]);  // T2: hold for synchronized write capture
      do_idle(2);                            // T3..T4: drop both (rd_ptr wraps 1 -> 0)

      // 5. Write remaining 3 bytes of Op 2, start, and verify full result
      do_write_byte(op_a2[15:8]);
      do_write_byte(op_b2[7:0]);
      do_write_byte(op_b2[15:8]);
      do_start(op2);
      do_read_result(2);

      // 6. Repeat with 5 randomized normal FP16 pairs
      repeat(5) begin
        op_a2 = gen_fp16(FP_NORMAL);
        op_b2 = gen_fp16(FP_NORMAL);
        assert(std::randomize(op2));

        do_read_result(1);
        drive_cycle(1'b1, 8'h02, 8'h00);
        drive_cycle(1'b1, 8'h03, op_a2[7:0]);
        drive_cycle(1'b1, 8'h03, op_a2[7:0]);
        do_idle(2);

        do_write_byte(op_a2[15:8]);
        do_write_byte(op_b2[7:0]);
        do_write_byte(op_b2[15:8]);
        do_start(op2);
        do_read_result(2);
      end
    endtask
  endclass
