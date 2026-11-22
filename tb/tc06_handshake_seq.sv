  // -------------------------------------------------------------------------
  // TC 6: Start-Busy-Done Handshake (done latches, clears on 2nd start)
  // -------------------------------------------------------------------------
  class tc06_handshake_seq extends fpu_base_seq;
    `uvm_object_utils(tc06_handshake_seq)
    function new(string name="tc06_handshake_seq"); super.new(name); endfunction
    virtual task body();
      do_load_operands(16'h3E00, 16'h4080);
      do_start(1'b0, 10);
      do_read_result(2);
      do_start(1'b1, 8);
      do_read_result(2);
    endtask
  endclass
