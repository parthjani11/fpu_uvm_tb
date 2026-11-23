  class fpu_test extends uvm_test;
    `uvm_component_utils(fpu_test)
    environment env; sequences write_seq; read_sequences read_seq; virtual dut_if vif; 
    
    function new(string name = "fpu_test", uvm_component parent = null); super.new(name, parent); endfunction
    
    virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      env = environment::type_id::create("env", this);
      if (!uvm_config_db#(virtual dut_if)::get(this, "", "vif", vif)) `uvm_fatal("TEST", "vif not found")
    endfunction
    
    virtual task run_phase(uvm_phase phase);
      phase.raise_objection(this);
      
      repeat(`num_of_transaction) begin
        write_seq = sequences::type_id::create("write_seq");
        read_seq  = read_sequences::type_id::create("read_seq");
        
        write_seq.start(env.agent1.seqr);
        
        // Isolate transaction logic securely[cite: 1]
        wait(vif.uo_out[0] == 1'b1); // Wait for Core Busy
        wait(vif.uo_out[1] == 1'b1); // Wait for Core Done
        
        read_seq.start(env.agent1.seqr);
      end
      
      #100;
      phase.drop_objection(this);
    endtask
  endclass
