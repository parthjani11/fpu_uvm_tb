  class environment extends uvm_env;
    `uvm_component_utils(environment)
    agent      agent1;
    agent      agent2;
    scoreboard scb;
    subscriber sub;

    function new(string name = "environment", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      uvm_config_db#(uvm_active_passive_enum)::set(this, "agent1", "is_active", UVM_ACTIVE);
      uvm_config_db#(uvm_active_passive_enum)::set(this, "agent2", "is_active", UVM_PASSIVE);
      agent1 = agent::type_id::create("agent1", this);
      agent2 = agent::type_id::create("agent2", this);
      scb    = scoreboard::type_id::create("scb", this);
      sub    = subscriber::type_id::create("sub", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      agent1.inp_mon.analysis_port.connect(scb.in_fifo1.analysis_export);
      agent1.inp_mon.analysis_port.connect(sub.in_fifo2.analysis_export);
      agent2.out_mon.analysis_port.connect(scb.out_fifo1.analysis_export);
      agent2.out_mon.analysis_port.connect(sub.out_fifo2.analysis_export);
    endfunction
  endclass
