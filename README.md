# FPU UVM Testbench (tt_um_project_fpu) - 26-TC regression version

Class code is identical to the single-file source; it is only split one class per file.

## Layout
rtl/tt_um_project_fpu.v   DUT (tt_um_project_fpu + fpu_core in one file, unchanged)
tb/dut_if.sv              interface + clocking blocks + SVA
tb/fpu_pkg.sv             package; `include`s every file below in this order
tb/top.sv                 top module (default test: fpu_regression_test)
filelist.f  cm_hier.cfg  run.csh  run_all.csh

Package include order (tb/):
sequence_item, fp_kind_e (typedef), fpu_base_seq, tc01..tc26_*_seq,
driver, sequencer, inp_monitor, out_monitor, agent, scoreboard, subscriber,
environment, fpu_seq_base_test, fpu_tc_tests (DEFINE_FPU_TEST macro + 26 tests),
fpu_regression_test

## Compile order (filelist.f)
dut_if.sv -> fpu_pkg.sv -> top.sv -> RTL.
RTL is last on purpose: it ends with `default_nettype none, which would otherwise
carry into the TB files compiled after it.

## Run
    ./run.csh                          # fpu_regression_test + coverage report
    ./run.csh tc05_sub_test            # one test
    ./run_all.csh                      # all 26 tests + regression, merged coverage

## Hierarchy
top
 +- dut_if vif ---- tt_um_project_fpu dut
 +- uvm_test_top (fpu_regression_test / tcNN_*_test)
     +- env
         +- agent1 (ACTIVE):  seqr -> drv,  inp_mon --+--> scb.in_fifo1,  sub.in_fifo2
         +- agent2 (PASSIVE): out_mon ----------------+--> scb.out_fifo1, sub.out_fifo2
         +- scb (scoreboard)   +- sub (subscriber)
