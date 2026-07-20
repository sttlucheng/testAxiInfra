#!/usr/bin/env bash
source setvars.sh
/nfs/home/yanglucheng/workspace/test/AxiInfra/ut/AxiReorder/build/vcs/sim/sim_build/simv +vcs+initreg+0 +notimingcheck 2>&1 | tee run.log