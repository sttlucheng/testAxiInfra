verdiWindowResize -win $_vdCoverage_1 "0" "23" "2560" "1369"
gui_set_pref_value -category {coveragesetting} -key {geninfodumping} -value 1
gui_exclusion -set_force true
gui_assert_mode -mode flat
gui_class_mode -mode hier
gui_column_config -id   -list  covtblCcexList  -col  C  -show 
gui_column_config -id   -list  covtblCcexList  -col  C  -on   -show 
gui_column_config -id   -list  covtblCcexList  -col  X  -on   -show 
gui_excl_mgr_flat_list -on  0
gui_covdetail_select -id  CovDetail.1   -name   Line
verdiWindowWorkMode -win $_vdCoverage_1 -coverageAnalysis
gui_open_cov  -hier build/vcs/TestAxiReorderVcsCov/sim_build/simv.vdb -testdir {} -test {build/vcs/TestAxiReorderVcsCov/sim_build/simv/TC_007_SEED_default_MODE_default build/vcs/TestAxiReorderVcsCov/sim_build/simv/TC_006_SEED_default_MODE_default build/vcs/TestAxiReorderVcsCov/sim_build/simv/TC_001_SEED_default_MODE_default build/vcs/TestAxiReorderVcsCov/sim_build/simv/TC_012_SEED_default_MODE_default build/vcs/TestAxiReorderVcsCov/sim_build/simv/TC_004_SEED_default_MODE_default build/vcs/TestAxiReorderVcsCov/sim_build/simv/TC_005_SEED_default_MODE_default build/vcs/TestAxiReorderVcsCov/sim_build/simv/TC_003_SEED_default_MODE_default build/vcs/TestAxiReorderVcsCov/sim_build/simv/TC_008_SEED_default_MODE_default build/vcs/TestAxiReorderVcsCov/sim_build/simv/TC_002_SEED_default_MODE_default build/vcs/TestAxiReorderVcsCov/sim_build/simv/TC_000_SEED_default_MODE_default build/vcs/TestAxiReorderVcsCov/sim_build/simv/TC_009_SEED_default_MODE_default} -merge MergedTest -db_max_tests 10 -fsm transition
gui_list_select -id CoverageTable.1 -list covtblInstancesList { tb_top   }
gui_list_expand -id  CoverageTable.1   -list {covtblInstancesList} tb_top
gui_list_expand -id CoverageTable.1   tb_top
gui_list_action -id  CoverageTable.1 -list {covtblInstancesList} tb_top  -column {Toggle} 
gui_list_select -id CoverageTable.1 -list covtblInstancesList { tb_top  tb_top.u_AxiReorder   }
gui_list_expand -id  CoverageTable.1   -list {covtblInstancesList} tb_top.u_AxiReorder
gui_list_expand -id CoverageTable.1   tb_top.u_AxiReorder
gui_list_action -id  CoverageTable.1 -list {covtblInstancesList} tb_top.u_AxiReorder  -column {Toggle} 
gui_list_select -id CovDetail.1 -list tgl { io_mst_aw_bits_lock  {io_mst_aw_bits_cache[3:0]}   }
gui_list_action -id  CovDetail.1 -list {tgl} {io_mst_aw_bits_cache[3:0]}
