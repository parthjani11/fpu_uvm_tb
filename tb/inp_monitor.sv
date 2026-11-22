  class inp_monitor extends uvm_monitor;
    `uvm_component_utils(inp_monitor)
    virtual dut_if vif;
    uvm_analysis_port#(sequence_item) analysis_port;

    function new(string name = "inp_monitor", uvm_component parent = null);
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
      forever begin
        @(vif.IN_MON.cb_in_mon);
        req = sequence_item::type_id::create("req");
        req.rst_n  = vif.IN_MON.cb_in_mon.rst_n;
        req.ui_in  = vif.IN_MON.cb_in_mon.ui_in;
        req.uio_in = vif.IN_MON.cb_in_mon.uio_in;
        analysis_port.write(req);
      end
    endtask
  endclass
