`timescale 1ns/1ps


// ---------------------------------------------------------
// Top Module
// ---------------------------------------------------------
module top;
  import uvm_pkg::*;
  import fpu_pkg::*;

  bit clk = 0;
  always #20 clk = ~clk;

  dut_if vif(clk);

  tt_um_project_fpu dut(
    .ui_in  (vif.ui_in),
    .uo_out (vif.uo_out),
    .uio_in (vif.uio_in),
    .uio_out(vif.uio_out),
    .uio_oe (vif.uio_oe),
    .ena    (1'b1),
    .clk    (clk),
    .rst_n  (vif.rst_n)
  );

  initial begin
    uvm_config_db#(virtual dut_if)::set(null, "*", "vif", vif);
    run_test("fpu_regression_test");
  end

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, top);
  end
endmodule
