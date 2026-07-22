#!/usr/bin/env bash
source setvars.sh
gdb --args /nfs/home/yanglucheng/workspace/test/AxiInfra/ut/AxiReorder/build/verilator/sim/sim_build/Vtb_top 2>&1 | tee run.log