class subscriber extends uvm_subscriber#(sequence_item);
    `uvm_component_utils(subscriber)

    uvm_tlm_analysis_fifo#(sequence_item) in_fifo2;
    uvm_tlm_analysis_fifo#(sequence_item) out_fifo2;

    sequence_item in_mon_xn;
    sequence_item out_mon_xn;

    // ===============================================================
    // Input pins + plan items 1, 8, 9 + TC19/20/24/25 conditions
    // ===============================================================
    covergroup input_cg;
      // TC1, TC26: reset driven low and released
      rst_n:coverpoint in_mon_xn.rst_n{
        bins assert_rst={0};
        bins release_rst={1};}

      // Control pins driven both low and high
      write_en:coverpoint in_mon_xn.ui_in[0]{
        bins low={0};
        bins high={1};}
      read_en:coverpoint in_mon_xn.ui_in[1]{
        bins low={0};
        bins high={1};}
      start:coverpoint in_mon_xn.ui_in[2]{
        bins low={0};
        bins high={1};}

      // Plan 1: opcode, only meaningful while start is high
      opcode:coverpoint in_mon_xn.ui_in[3] iff(in_mon_xn.ui_in[2]){
        bins add={0};
        bins sub={1};}

      // Data byte on uio_in while writing (8 equal bins over 0-255)
      uio_in:coverpoint in_mon_xn.uio_in iff(in_mon_xn.ui_in[0]){
        bins data[8]={[0:255]};}

      // Plan 8 (TC20): write while idle (accepted) and while busy (ignored)
      write_while_busy:coverpoint out_mon_xn.uo_out[0] iff(in_mon_xn.ui_in[0]){
        bins busy_0={0};
        bins busy_1={1};}

      // Plan 9 (TC19): start pressed with ready=0 (ignored) and ready=1 (valid)
      start_condition:coverpoint out_mon_xn.uo_out[3] iff(in_mon_xn.ui_in[2]){
        bins ready_0 = {0};   // start before ready: ignored
        bins ready_1 = {1};}  // start when ready: operation begins

      // TC24: valid start with done already 1 (restart without reload) vs fresh
      restart:coverpoint out_mon_xn.uo_out[1]
          iff(in_mon_xn.ui_in[2] && out_mon_xn.uo_out[3] && !out_mon_xn.uo_out[0]){
        bins fresh_start   = {0};
        bins restart_start = {1};}

      // TC19, TC25: number of bytes written when start is pressed
      // (ptr=0: all 4 bytes written, ptr=1..3: partial load)
      start_wr_ptr:coverpoint out_mon_xn.uo_out[7:4] iff(in_mon_xn.ui_in[2]){
        bins full_load      = {0};
        bins partial_reload = {[1:3]};}

      // Only one control is used at a time; multi-control combos are ignored
      control_combo:cross write_en,read_en,start {
        ignore_bins multi_ctrl =
          (binsof(write_en.high) && binsof(read_en.high)) ||
          (binsof(write_en.high) && binsof(start.high))   ||
          (binsof(read_en.high)  && binsof(start.high));
      }
    endgroup

    // ===============================================================
    // Output pins: TC2, TC3, TC6, TC9, TC15-18
    // ===============================================================
    covergroup output_cg;
      // TC2: wr_ptr takes all values 0-3
      wr_ptr:coverpoint out_mon_xn.uo_out[7:4]{
        bins ptr[4]={[0:3]};}

      // TC3: ready low and high
      ready:coverpoint out_mon_xn.uo_out[3]{
        bins low={0};
        bins high={1};}

      // TC3: ready vs wr_ptr
      ptr_x_ready:cross wr_ptr, ready {
        // ready is high only when wr_ptr==0 (it drops once a partial write
        // happens), so ready=1 with wr_ptr 1..3 cannot occur.
        ignore_bins ready_with_partial_ptr =
          binsof(ready.high) && binsof(wr_ptr) intersect {[1:3]};
      }

      // TC6: busy and done each seen low and high
      busy:coverpoint out_mon_xn.uo_out[0]{
        bins low={0};
        bins high={1};}
      done:coverpoint out_mon_xn.uo_out[1]{
        bins low={0};
        bins high={1};}

      // TC15-18: error flag seen 0 and 1 once an operation is done
      error:coverpoint out_mon_xn.uo_out[2] iff(out_mon_xn.uo_out[1]){
        bins no_error={0};
        bins error={1};}

      // TC9: uio_oe is 0xFF while reading, 0x00 otherwise
      uio_oe:coverpoint out_mon_xn.uio_oe{
        bins oe_off={8'h00};
        bins oe_on ={8'hFF};}
    endgroup

    function new(string name="subscriber", uvm_component parent=null);
      super.new(name, parent);
      input_cg  = new();
      output_cg = new();
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      in_fifo2  = new("in_fifo2", this);
      out_fifo2 = new("out_fifo2", this);
    endfunction

    virtual function void write(sequence_item t);
    endfunction

    virtual task run_phase(uvm_phase phase);
      forever begin
        in_fifo2.get(in_mon_xn);
        out_fifo2.get(out_mon_xn);
        input_cg.sample();
        output_cg.sample();
      end
    endtask

    function void report_phase(uvm_phase phase);
      super.report_phase(phase);
      `uvm_info(get_name(), $sformatf("INPUT COVERAGE  = %0f", input_cg.get_coverage()),  UVM_NONE)
      `uvm_info(get_name(), $sformatf("OUTPUT COVERAGE = %0f", output_cg.get_coverage()), UVM_NONE)
    endfunction
  endclass