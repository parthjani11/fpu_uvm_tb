  class sequences extends uvm_sequence#(sequence_item);
    `uvm_object_utils(sequences)
    function new(string name="sequences"); super.new(name); endfunction
    
    virtual task body();
      sequence_item req;
      logic [15:0] op_a, op_b;
      logic [7:0]  bytes[4];

      // Randomize valid normal FP16 operands (exponent 1 to 30; signs & mantissas random)
      if (!std::randomize(op_a, op_b) with {
        op_a[14:10] inside {[5'd1 : 5'd30]};
        op_b[14:10] inside {[5'd1 : 5'd30]};
      }) `uvm_fatal("SEQ", "Operand randomization failed");

      bytes[0] = op_a[7:0];  // A LSB
      bytes[1] = op_a[15:8]; // A MSB
      bytes[2] = op_b[7:0];  // B LSB
      bytes[3] = op_b[15:8]; // B MSB

      // Drive 4 operand bytes (2-cycle high, 2-cycle low)
      for (int i = 0; i < 4; i++) begin
        repeat(2) begin
          req = sequence_item::type_id::create("req");
          start_item(req);
          assert(req.randomize() with {rst_n == 1; ui_in == 8'h01; uio_in == bytes[i];});
          finish_item(req);
        end
        repeat(2) begin
          req = sequence_item::type_id::create("req");
          start_item(req);
          assert(req.randomize() with {rst_n == 1; ui_in == 8'h00; uio_in == 8'h00;});
          finish_item(req);
        end
      end
      
      // Start pulse (ui_in[2]=1 for start, ui_in[3]=0 for ADD only)
      repeat(2) begin
        req = sequence_item::type_id::create("req");
        start_item(req);
        assert(req.randomize() with {rst_n == 1; ui_in == 8'h04; uio_in == 8'h00;});
        finish_item(req);
      end
      repeat(2) begin
        req = sequence_item::type_id::create("req");
        start_item(req);
        assert(req.randomize() with {rst_n == 1; ui_in == 8'h00; uio_in == 8'h00;});
        finish_item(req);
      end
    endtask
  endclass
