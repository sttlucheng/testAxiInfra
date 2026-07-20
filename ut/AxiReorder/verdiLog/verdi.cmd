simSetSimulator "-vcssv" -exec \
           "/nfs/home/yanglucheng/workspace/test/AxiInfra/ut/AxiReorder/build/vcs/sim/sim_build/simv" \
           -args \
           "+notimingcheck -cm line+cond+tgl+fsm+branch+assert -cm_dir /nfs/home/yanglucheng/workspace/test/AxiInfra/ut/AxiReorder/build/vcs/sim/cov/coverage.vdb -cm_name 004 +vcs+initreg+0"
debImport "-dbdir" \
          "/nfs/home/yanglucheng/workspace/test/AxiInfra/ut/AxiReorder/build/vcs/sim/sim_build/simv.daidir"
debLoadSimResult \
           /nfs/home/yanglucheng/workspace/test/AxiInfra/ut/AxiReorder/build/vcs/sim/004.vcd.fsdb
wvCreateWindow
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
debExit
