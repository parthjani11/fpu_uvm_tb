class tc_wr_start_same_seq extends fpu_base_seq;
    `uvm_object_utils(tc_wr_start_same_seq)
    function new(string name="tc_wr_start_same_seq"); super.new(name); endfunction
    virtual task body();
      logic [15:0] a, b;
      logic [7:0]  junk;
      bit          op;
      repeat(num_txns) begin
        a = gen_fp16(FP_NORMAL);
        b = gen_fp16(FP_NORMAL);
        assert(std::randomize(op, junk));
        do_load_operands(a, b);                                  // ready=1, wr_ptr=0
        repeat(2) drive_cycle(1'b1, {4'h0, op, 1'b1, 1'b0, 1'b1}, junk); // start + write together
        do_idle(6);
        do_read_result(2);                                       // must be a op b, not junk
      end
    endtask
  endclass