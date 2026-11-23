  // =========================================================================
  // Tests (Individual TC 1..26, Priority Tests & Full Regression Test)
  // =========================================================================
  class fpu_seq_base_test extends uvm_test;
    `uvm_component_utils(fpu_seq_base_test)
    environment env;

    function new(string name = "fpu_seq_base_test", uvm_component parent = null);
      super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      env = environment::type_id::create("env", this);
    endfunction

    virtual task run_seq(fpu_base_seq seq, string tag);
      `uvm_info("REGRESSION", $sformatf("========== Starting %s ==========", tag), UVM_NONE)
      seq.start(env.agent1.seqr);
    endtask
  endclass
