# FPU UVM Testbench (tt_um_project_fpu) - 28-TC regression + functional coverage

Code is split one class per file; package `fpu_pkg.sv` `include`s them in order.

## Layout
rtl/tt_um_project_fpu.v   DUT (tt_um_project_fpu + fpu_core in one file)
tb/dut_if.sv              interface + clocking blocks + 7 SVA
tb/fpu_pkg.sv             package (num_of_transaction define + all includes)
tb/top.sv                 top (default test: fpu_regression_test)
tb/*_seq.sv               fpu_base_seq, tc01..tc26, tc_rd_wr_prio, tc_rd_start_prio
tb/subscriber.sv          functional coverage (input_cg, output_cg)
tb/fpu_tc_tests.sv        DEFINE_FPU_TEST macro + 28 individual tests
filelist.f  cm_hier.cfg  run.csh  run_all.csh  .gitignore

## Compile order (filelist.f)
dut_if.sv -> fpu_pkg.sv -> top.sv -> RTL  (RTL last: it ends with `default_nettype none)

## Run
    ./run.csh                          # fpu_regression_test + coverage report
    ./run.csh tc_rd_start_prio_test    # one test
    ./run_all.csh                      # all 28 tests + regression, merged coverage
Both scripts retry the compile every 2 minutes while no VCS license is free.

## Note
Transactions per sequence = `num_of_transaction (currently 1, set in tb/fpu_pkg.sv).
The OE-priority checks (uio_oe = FF only when read_en=1, write_en=0, busy=0) need an RTL
with that behaviour; copy your latest RTL into rtl/ if it differs.
