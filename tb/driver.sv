  // =========================================================================
  // Driver, Sequencer, Monitors, Agent
  // =========================================================================
  class driver extends uvm_driver#(sequence_item);
    `uvm_component_utils(driver)
    virtual dut_if vif;

    function new(string name = "driver", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(virtual dut_if)::get(this, "", "vif", vif))
        `uvm_fatal("DRV", "vif not fetched")
    endfunction

    virtual task run_phase(uvm_phase phase);
      sequence_item req;

      // Power-on reset and clean idle release
      @(vif.DRV.cb_drv);
      vif.DRV.cb_drv.rst_n  <= 1'b0;
      vif.DRV.cb_drv.ui_in  <= 8'h00;
      vif.DRV.cb_drv.uio_in <= 8'h00;
      repeat(2) @(vif.DRV.cb_drv);
      vif.DRV.cb_drv.rst_n  <= 1'b1;
      repeat(2) @(vif.DRV.cb_drv);

      forever begin
        seq_item_port.get_next_item(req);
        @(vif.DRV.cb_drv);
        vif.DRV.cb_drv.rst_n  <= req.rst_n;
        vif.DRV.cb_drv.ui_in  <= req.ui_in;
        vif.DRV.cb_drv.uio_in <= req.uio_in;
        seq_item_port.item_done();
      end
    endtask
  endclass
