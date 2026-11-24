#!/bin/csh -f
source /fetools/synopsys/source/source.sh

# Runs fpu_regression_test across 10 different random seeds,
# auto-cleans old outputs on every run, and merges all coverage into urgReport.
set TEST     = fpu_regression_test
set NUM_RUNS = 10
set CM       = line+cond+fsm+tgl+branch+assert

# ---- Auto-clean previous run data (forces fresh compile & clean cov.vdb) ----
rm -rf cov.vdb urgReport logs simv simv.daidir csrc comp.log ucli.key dump.vcd

# ---- Compile once: wait for a license, retry every 2 minutes ----
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

# ---- Run 10 iterations with distinct automatic random seeds ----
mkdir -p logs
set i = 1
while ($i <= $NUM_RUNS)
  set RUN_ID = `printf "%02d" $i`
  echo "=== Running $TEST (Run $RUN_ID / $NUM_RUNS) ==="
  ./simv +vcs+lic+wait +UVM_TESTNAME=$TEST +UVM_VERBOSITY=UVM_LOW \
      +ntb_random_seed_automatic \
      -cm $CM -cm_dir ./cov.vdb -cm_name ${TEST}_run${RUN_ID} \
      -l logs/sim_${TEST}_run${RUN_ID}.log
  @ i = $i + 1
end

# ---- Merge coverage from all 10 runs into one URG report ----
urg -full64 -dir ./cov.vdb -report urgReport -format both

echo ""
echo "Logs: ./logs/sim_${TEST}_run*.log  |  Merged coverage: urgReport/dashboard.html"
echo "=== Regression Summary (Seeds, Scoreboard & Errors) ==="
grep -H -E "random seed|SCB_REPORT|UVM_ERROR :|UVM_FATAL :" logs/sim_${TEST}_run*.log
