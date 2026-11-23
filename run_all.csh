#!/bin/csh -f
source /fetools/synopsys/source/source.sh

# Compiles once, runs every individual test + the full regression,
# merges all coverage into one urgReport.
set CM = line+cond+fsm+tgl+branch+assert
rm -rf cov.vdb urgReport

# ---- Compile: wait for a license, retry every 2 minutes ----
while (1)
  vcs -licwait 2 -sverilog -full64 +v2k -debug_access+all -ntb_opts uvm-1.2 \
      -timescale=1ns/1ps -f filelist.f \
      -cm $CM -cm_dir ./cov.vdb -cm_hier cm_hier.cfg \
      -o simv -l comp.log
  if ($status == 0) break

  grep -qi "Failed to obtain license" comp.log
  if ($status == 0) then
    echo "[`date`] No VCS license available - retrying in 2 minutes..."
    sleep 120
  else
    echo "COMPILE FAILED (not a license problem) - see comp.log"
    exit 1
  endif
end

mkdir -p logs
foreach T ( \
  tc01_reset_test tc02_byte_write_test tc03_ready_indication_test \
  tc04_add_test tc05_sub_test tc06_handshake_test tc07_lat_normal_test \
  tc08_lat_special_test tc09_readout_test tc10_norm_carry_test \
  tc11_norm_lshift_test tc12_zero_op_test tc13_exact_cancel_test \
  tc14_mixed_test tc15_inf_test tc16_nan_test tc17_denormal_test \
  tc18_err_clear_test tc19_start_before_ready_test \
  tc20_write_while_busy_test tc21_overflow_test tc22_underflow_test \
  tc23_large_exp_diff_test tc24_b2b_start_test tc25_partial_reload_test \
  tc26_reset_during_op_test tc_rd_wr_prio_test tc_rd_start_prio_test \
  fpu_regression_test )
  echo "=== Running $T ==="
  ./simv +vcs+lic+wait +UVM_TESTNAME=$T +UVM_VERBOSITY=UVM_LOW \
      -cm $CM -cm_dir ./cov.vdb -cm_name $T -l logs/sim_$T.log
end

urg -full64 -dir ./cov.vdb -report urgReport -format both
echo "Per-test logs in ./logs  |  Merged coverage: urgReport/dashboard.html"
echo "Quick summary:"
grep -H "SCB_REPORT" logs/*.log
