`timescale 1ns/1ps

// ---------------------------------------------------------
// Interface
// ---------------------------------------------------------
`ifndef DUT_IF_SV
`define DUT_IF_SV

interface dut_if(input logic clk);
  logic rst_n;
  logic [7:0] ui_in, uio_in;
  logic [7:0] uo_out, uio_out, uio_oe;

  clocking cb_drv @(posedge clk);
    default input #1 output #1;
    output rst_n, ui_in, uio_in;
    input  uo_out;
  endclocking

  clocking cb_in_mon @(posedge clk);
    default input #1 output #1;
    input rst_n, ui_in, uio_in;
  endclocking

  clocking cb_out_mon @(posedge clk);
    default input #1 output #1;
    input uo_out, uio_out, uio_oe;
  endclocking

  modport DRV(clocking cb_drv);
  modport IN_MON(clocking cb_in_mon);
  modport OUT_MON(clocking cb_out_mon);

  // =========================================================================
  // SVA ASSERTIONS (Aligned to RTL 2-stage synchronizers: wr_s, st_s, rd_s)
  // Pin map:
  //   ui_in[0] = write_en | ui_in[1] = read_en | ui_in[2] = start
  //   uo_out[0] = busy    | uo_out[1] = done   | uo_out[3] = ready
  //   uo_out[7:4] = wr_ptr
  // =========================================================================

  // 1.1 RESET CHECK: While rst_n is low, uo_out, uio_out, and uio_oe must be 8'h00
  property p_reset_check;
    @(posedge clk)
    (rst_n === 1'b0) |-> (uo_out === 8'h00 && uio_out === 8'h00 && uio_oe === 8'h00);
  endproperty
  a_reset_check: assert property (p_reset_check)
    else $error("[SVA_1.1_RESET] Outputs non-zero during reset: uo_out=%h uio_out=%h uio_oe=%h",
                uo_out, uio_out, uio_oe);

  // 2.1 START CHECK - Busy after start:
  // Valid start rising edge with ready=1 and busy=0 -> busy goes high
  property p_busy_after_start;
    @(posedge clk) disable iff (rst_n !== 1'b1)
    ($rose(ui_in[2]) && uo_out[3] && !uo_out[0]) |-> ##2 (uo_out[0] === 1'b1);
  endproperty
  a_busy_after_start: assert property (p_busy_after_start)
    else $error("[SVA_2.1_BUSY] busy (uo_out[0]) did not go high after valid start");

  // 2.2 START CHECK - Start ignored:
  // If start rises with ready=0, busy must stay low
  property p_start_ignored;
    @(posedge clk) disable iff (rst_n !== 1'b1)
    ($rose(ui_in[2]) && !uo_out[3]) |-> ##1 (uo_out[0] === 1'b0) ##1 (uo_out[0] === 1'b0);
  endproperty
  a_start_ignored: assert property (p_start_ignored)
    else $error("[SVA_2.2_START_IGN] busy asserted despite ready=0 on start");

  // 3.1 WRITE CHECK - wr_ptr increment:
  // wr_ptr increments by 1 (mod 4 for FP16) on each write rising edge when busy=0
  property p_wr_ptr_inc;
    logic [3:0] prev_ptr;
    @(posedge clk) disable iff (rst_n !== 1'b1)
    ($rose(ui_in[0]) && !uo_out[0], prev_ptr = uo_out[7:4]) ##1 (!uo_out[0])
      |=> (uo_out[7:4] === ((prev_ptr + 4'd1) % 4));
  endproperty
  a_wr_ptr_inc: assert property (p_wr_ptr_inc)
    else $error("[SVA_3.1_WR_PTR] wr_ptr (uo_out[7:4]) failed to increment on write_en");

  // 3.2 WRITE CHECK - Write while busy:
  // A write rising edge while busy=1 must not change wr_ptr
  property p_write_while_busy;
    logic [3:0] prev_ptr;
    @(posedge clk) disable iff (rst_n !== 1'b1)
    ($rose(ui_in[0]) && uo_out[0], prev_ptr = uo_out[7:4]) ##1 (uo_out[0])
      |=> (uo_out[7:4] === prev_ptr);
  endproperty
  a_write_while_busy: assert property (p_write_while_busy)
    else $error("[SVA_3.2_WR_BUSY] wr_ptr changed on write_en while busy=1");

  // 4.1 READ CHECK - Bus enable:
  // uio_oe must be 8'hFF when read_en is high and busy is low, and 8'h00 otherwise
  property p_bus_enable;
    logic rd_d;
    @(posedge clk) disable iff (rst_n !== 1'b1)
    (1'b1, rd_d = ui_in[1]) |=> (uio_oe === ((rd_d && !uo_out[0]) ? 8'hFF : 8'h00));
  endproperty
  a_bus_enable: assert property (p_bus_enable)
    else $error("[SVA_4.1_OE] uio_oe=%h mismatch (expected FF when read_en=1 & busy=0, else 00)",
                uio_oe);

  // 5.1 LATENCY CHECK:
  // After a valid start, done rises 3 cycles (special) or 4 cycles (normal) after start_pulse
  property p_latency;
    @(posedge clk) disable iff (rst_n !== 1'b1)
    ($rose(ui_in[2]) && uo_out[3] && !uo_out[0]) |-> ##[4:5] $rose(uo_out[1]);
  endproperty
  a_latency: assert property (p_latency)
    else $error("[SVA_5.1_LATENCY] done (uo_out[1]) did not rise 3-4 cycles after start_pulse");

endinterface

`endif
