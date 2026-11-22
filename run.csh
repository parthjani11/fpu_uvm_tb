#!/bin/csh -f
source /fetools/synopsys/source/source.sh

set TEST = fpu_regression_test
if ($#argv > 0) set TEST = $argv[1]

set CM = line+cond+fsm+tgl+branch+assert

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

./simv +vcs+lic+wait +UVM_TESTNAME=$TEST +UVM_VERBOSITY=UVM_LOW \
    -cm $CM -cm_dir ./cov.vdb -cm_name $TEST -l sim_$TEST.log

urg -full64 -dir ./cov.vdb -report urgReport -format both
echo "Log: sim_$TEST.log | Coverage: urgReport/dashboard.html"