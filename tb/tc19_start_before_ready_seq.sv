  // -------------------------------------------------------------------------
  // TC 19: Start Before Ready (write 0..3 bytes after reset, pulse start)
  // -------------------------------------------------------------------------
  class tc19_start_before_ready_seq extends fpu_base_seq;
    `uvm_object_utils(tc19_start_before_ready_seq)
    function new(string name="tc19_start_before_ready_seq"); super.new(name); endfunction
    virtual task body();
      logic [7:0] rand_byte;
      for (int n = 0; n < 4; n++) begin
        do_reset(3);
        repeat(n) begin
          assert(std::randomize(rand_byte));
          do_write_byte(rand_byte);
        end
        do_start(1'b0, 4);
      end
      do_reset(3);
    endtask
  endclass
