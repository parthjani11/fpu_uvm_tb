  // =========================================================================
  // Base Sequence with Reusable Bus-Level Tasks & FP16 Operand Generators
  // =========================================================================
  class fpu_base_seq extends uvm_sequence#(sequence_item);
    `uvm_object_utils(fpu_base_seq)
    int num_txns = 10;

    function new(string name="fpu_base_seq");
      super.new(name);
    endfunction

    task drive_cycle(logic rst_n_v, logic [7:0] ui_v, logic [7:0] uio_v);
      sequence_item req;
      req = sequence_item::type_id::create("req");
      start_item(req);
      assert(req.randomize() with { rst_n == rst_n_v; ui_in == ui_v; uio_in == uio_v; });
      finish_item(req);
    endtask

    task do_reset(int rst_cycles = 3);
      repeat(rst_cycles) drive_cycle(1'b0, 8'h00, 8'h00);
      repeat(2)          drive_cycle(1'b1, 8'h00, 8'h00);
    endtask

    task do_idle(int cycles = 2);
      repeat(cycles) drive_cycle(1'b1, 8'h00, 8'h00);
    endtask

    task do_write_byte(logic [7:0] data);
      repeat(2) drive_cycle(1'b1, 8'h01, data);
      repeat(2) drive_cycle(1'b1, 8'h00, 8'h00);
    endtask

    task do_load_operands(logic [15:0] op_a, logic [15:0] op_b);
      do_write_byte(op_a[7:0]);
      do_write_byte(op_a[15:8]);
      do_write_byte(op_b[7:0]);
      do_write_byte(op_b[15:8]);
    endtask

    task do_start(bit op, int wait_cycles = 6);
      logic [7:0] st_val = {4'h0, op, 1'b1, 2'b00};
      repeat(2) drive_cycle(1'b1, st_val, 8'h00);
      do_idle(wait_cycles);
    endtask

    task do_read_result(int n_bytes = 2);
      repeat(n_bytes) begin
        repeat(2) drive_cycle(1'b1, 8'h02, 8'h00);
        repeat(2) drive_cycle(1'b1, 8'h00, 8'h00);
      end
    endtask

    task do_full_op(logic [15:0] op_a, logic [15:0] op_b, bit op);
      do_load_operands(op_a, op_b);
      do_start(op);
      do_read_result(2);
    endtask

    function logic [15:0] gen_fp16(fp_kind_e kind);
      logic       s;
      logic [4:0] e;
      logic [9:0] m;
      case (kind)
        FP_NORMAL: assert(std::randomize(s, e, m) with { e inside {[5'd1 : 5'd30]}; });
        FP_ZERO:   begin assert(std::randomize(s)); e = 5'h00; m = 10'h000; end
        FP_INF:    begin assert(std::randomize(s)); e = 5'h1F; m = 10'h000; end
        FP_NAN:    begin assert(std::randomize(s, m) with { m != 10'h000; }); e = 5'h1F; end
        FP_DENORM: begin assert(std::randomize(s, m) with { m != 10'h000; }); e = 5'h00; end
      endcase
      return {s, e, m};
    endfunction
  endclass
