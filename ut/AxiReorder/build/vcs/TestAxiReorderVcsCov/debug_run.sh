#!/usr/bin/env bash
source setvars.sh
gdb --args /nfs/home/yanglucheng/workspace/test/AxiInfra/ut/AxiReorder/build/vcs/TestAxiReorderVcsCov/sim_build/simv  +notimingcheck 2>&1 | tee run.log