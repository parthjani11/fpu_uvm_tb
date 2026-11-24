// -------------------------------------------------------------------------
  // TC 31: Constant write_en High (>= 2 cycles) -> Assert read_en
  // Verifies request-based priority: held write_en level does NOT block
  // read_en from asserting uio_oe=8'hFF and reading both result bytes,
  // and does NOT trigger spurious extra writes.
  // -------------------------------------------------------------------------
  class tc_wr_lvl_rd_trig_seq extends fpu_base_seq;
    `uvm_object_utils(tc_wr_lvl_rd_trig_seq)

    function new(string name="tc_wr_lvl_rd_trig_seq");
      super.new(name);
    endfunction

    task run_wr_lvl_rd_case(logic [15:0] op_a1, logic [15:0] op_b1, bit op1,
                            logic [15:0] op_a2, logic [15:0] op_b2, bit op2,
                            int hold_cycles);
      // 1. Complete Op 1 so valid result is latched and ready for readout (rd_ptr=0)
      do_load_operands(op_a1, op_b1);
      do_start(op1);

      // 2. Assert write_en=1 continuously for >= 2 cycles:
      //    - Cycle 0: rising edge (triggers 1 write request -> wr_ptr: 0 -> 1)
      //    - Cycle 1: hold op_a2[7:0] for synchronized write capture
      //    - Cycle 2+: hold write_en=1 with junk data (0xEE) to prove no extra writes occur
      drive_cycle(1'b1, 8'h01, op_a2[7:0]);
      drive_cycle(1'b1, 8'h01, op_a2[7:0]);
      if (hold_cycles > 2) begin
        repeat(hold_cycles - 2) drive_cycle(1'b1, 8'h01, 8'hEE);
      end

      // 3. While write_en STAYS high continuously, assert read_en for Byte 0 & Byte 1
      //    -> read_en must trigger uio_oe=8'hFF and read out Op 1's full result
      repeat(2) drive_cycle(1'b1, 8'h03, 8'hEE); // Byte 0 (LSB): write_en=1, read_en=1
      repeat(2) drive_cycle(1'b1, 8'h01, 8'hEE); // Drop read_en (rd_ptr: 0 -> 1), keep write_en=1
      repeat(2) drive_cycle(1'b1, 8'h03, 8'hEE); // Byte 1 (MSB): write_en=1, read_en=1
      do_idle(2);                                // Drop both (rd_ptr: 1 -> 0)

      // 4. Write remaining 3 bytes of Op 2, start, and read Op 2 result
      //    -> confirms held write_en only incremented wr_ptr once and preserved Byte 0
      do_write_byte(op_a2[15:8]);
      do_write_byte(op_b2[7:0]);
      do_write_byte(op_b2[15:8]);
      do_start(op2);
      do_read_result(2);
    endtask

    virtual task body();
      logic [15:0] op_a1, op_b1, op_a2, op_b2;
      bit          op1, op2;
      int          hold_cycles;

      do_reset(3);

      // Directed case: exact 2-cycle write_en hold before read_en
      run_wr_lvl_rd_case(16'h3E00, 16'h4080, 1'b0,   // Op 1: 1.5 + 2.25 = 3.75 (0x4380)
                         16'h3E55, 16'h40AA, 1'b1,   // Op 2: SUB (0xBA00)
                         2);

      // Randomized cases: 2 to 5 cycles of continuous write_en high before read_en
      repeat(5) begin
        op_a1 = gen_fp16(FP_NORMAL);
        op_b1 = gen_fp16(FP_NORMAL);
        op_a2 = gen_fp16(FP_NORMAL);
        op_b2 = gen_fp16(FP_NORMAL);
        assert(std::randomize(op1, op2, hold_cycles) with {
          hold_cycles inside {[2:5]};
        });
        run_wr_lvl_rd_case(op_a1, op_b1, op1, op_a2, op_b2, op2, hold_cycles);
      end
    endtask
  endclass