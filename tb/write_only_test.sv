  class write_only_test extends fpu_test;
    `uvm_component_utils(write_only_test)

    function new(string name = "write_only_test", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
      phase.raise_objection(this);

      repeat(`num_of_transaction) begin
        write_seq = sequences::type_id::create("write_seq");
        write_seq.start(env.agent1.seqr);

        // Wait for computation to start and complete (no read_seq triggered)
        wait(vif.uo_out[0] == 1'b1); // busy
        wait(vif.uo_out[1] == 1'b1); // done

        // Hold idle with read_en=0 to inspect uio_oe and uio_out
        repeat(4) begin
          @(posedge vif.clk);
          `uvm_info("WR_ONLY_CHK",
            $sformatf("read_en=%b | busy=%b done=%b | uio_oe=%h uio_out=%h",
                      vif.ui_in[1], vif.uo_out[0], vif.uo_out[1], vif.uio_oe, vif.uio_out),
            UVM_LOW)

          if (vif.uio_oe !== 8'h00)
            `uvm_error("WR_ONLY_BUG",
              $sformatf("uio_oe=%h asserted while read_en=0!", vif.uio_oe))

          if (vif.uio_out !== 8'h00)
            `uvm_warning("WR_ONLY_OBS",
              $sformatf("uio_out=%h is non-zero while read_en=0 (uio_oe=%h)",
                        vif.uio_out, vif.uio_oe))
        end
      end

      #100;
      phase.drop_objection(this);
    endtask
  endclass
