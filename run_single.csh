#!/bin/csh -f
source /fetools/synopsys/source/source.sh

# Usage: ./run_single.csh <UVM_TESTNAME>
if ($#argv >= 1) then
  set T = $1
else
  set T = tc04_add_test   # Default test if no argument is given
endif

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

# ---- Run single test ----
mkdir -p logs
echo "=== Running $T ==="
./simv +vcs+lic+wait +UVM_TESTNAME=$T +UVM_VERBOSITY=UVM_LOW \
    -cm $CM -cm_dir ./cov.vdb -cm_name $T -l logs/sim_${T}.log

# ---- Coverage & Summary ----
urg -full64 -dir ./cov.vdb -report urgReport -format both
echo "Log: logs/sim_${T}.log  |  Coverage: urgReport/dashboard.html"
echo "Quick summary:"
grep -H -E "SCB_REPORT|UVM_ERROR :|UVM_FATAL :" logs/sim_${T}.log
