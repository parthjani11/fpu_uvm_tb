  class out_monitor extends uvm_monitor;
    `uvm_component_utils(out_monitor)
    virtual dut_if vif;
    uvm_analysis_port#(sequence_item) analysis_port;

    function new(string name = "out_monitor", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      analysis_port = new("analysis_port", this);
      if (!uvm_config_db#(virtual dut_if)::get(this, "", "vif", vif))
        `uvm_fatal("MON", "vif not got")
    endfunction

    virtual task run_phase(uvm_phase phase);
      sequence_item req;
      @(vif.OUT_MON.cb_out_mon);
      forever begin
        @(vif.OUT_MON.cb_out_mon);
        req = sequence_item::type_id::create("req");
        req.uo_out  = vif.OUT_MON.cb_out_mon.uo_out;
        req.uio_out = vif.OUT_MON.cb_out_mon.uio_out;
        req.uio_oe  = vif.OUT_MON.cb_out_mon.uio_oe;
        analysis_port.write(req);
      end
    endtask
  endclass
