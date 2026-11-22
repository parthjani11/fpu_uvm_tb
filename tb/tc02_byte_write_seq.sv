  // -------------------------------------------------------------------------
  // TC 2: Operand Byte Write (verify wr_ptr & byte/operand order via SUB)
  // -------------------------------------------------------------------------
  class tc02_byte_write_seq extends fpu_base_seq;
    `uvm_object_utils(tc02_byte_write_seq)
    function new(string name="tc02_byte_write_seq"); super.new(name); endfunction
    virtual task body();
      logic [15:0] a, b;
      do_reset(2);
      repeat(num_txns) begin
        assert(std::randomize(a, b) with {
          a[14:10] inside {[5'd5 : 5'd25]};
          b[14:10] inside {[5'd5 : 5'd25]};
          a != b;
          a[7:0] != a[15:8];
          b[7:0] != b[15:8];
        });
        do_full_op(a, b, 1'b1);
      end
    endtask
  endclass
