  class read_sequences extends uvm_sequence#(sequence_item);
    `uvm_object_utils(read_sequences)
    function new(string name="read_sequences"); super.new(name); endfunction
    
    virtual task body();
      sequence_item req;
      // Read 2 result bytes (LSB first, then MSB)
      repeat(2) begin
        repeat(2) begin // Hold read_en (ui_in[1]) high to drive uio_out
          req = sequence_item::type_id::create("req");
          start_item(req);
          assert(req.randomize() with {rst_n == 1; ui_in == 8'h02; uio_in == 8'h00;});
          finish_item(req);
        end
        repeat(2) begin // Drop read_en low -> falling edge advances rd_ptr
          req = sequence_item::type_id::create("req");
          start_item(req);
          assert(req.randomize() with {rst_n == 1; ui_in == 8'h00; uio_in == 8'h00;});
          finish_item(req);
        end
      end
    endtask
  endclass
