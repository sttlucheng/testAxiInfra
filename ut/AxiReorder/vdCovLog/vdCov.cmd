verdiWindowResize -win $_vdCoverage_1 "719" "349" "1913" "1335"
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
gui_open_cov  -hier /nfs/home/yanglucheng/workspace/test/AxiInfra/ut/AxiReorder/build/vcs/sim/cov/coverage.vdb -testdir {} -test {/nfs/home/yanglucheng/workspace/test/AxiInfra/ut/AxiReorder/build/vcs/sim/cov/coverage/002} -merge MergedTest -db_max_tests 10 -fsm transition
gui_list_select -id CoverageTable.1 -list covtblInstancesList { tb_top   }
gui_list_expand -id  CoverageTable.1   -list {covtblInstancesList} tb_top
gui_list_select -id CoverageTable.1 -list covtblInstancesList { tb_top  tb_top.u_AxiReorder   }
gui_list_select -id CoverageTable.1 -list covtblInstancesList { tb_top.u_AxiReorder  tb_top.u_others   }
gui_list_select -id CoverageTable.1 -list covtblInstancesList { tb_top.u_others  tb_top.u_AxiReorder   }
gui_covtable_show -show  { Module List } -id  CoverageTable.1  -test  MergedTest
gui_list_select -id CoverageTable.1 -list covtblModulesList { /Queue1_AxiWEtrBundle_1   } -type { Module  }
gui_list_expand -id  CoverageTable.1   -list {covtblModulesList} /Queue1_AxiWEtrBundle_1
gui_list_expand -id CoverageTable.1   /Queue1_AxiWEtrBundle_1
gui_list_action -id  CoverageTable.1 -list {covtblModulesList} /Queue1_AxiWEtrBundle_1  -type {Module}  -column {Condition} 
gui_summarybar_goto -id  CovSrc.1   282
gui_list_select -id CoverageTable.1 -list covtblModulesList { /Queue1_AxiWEtrBundle_1   } -type { Module  }
verdiWindowResize -win $_vdCoverage_1 "709" "341" "2432" "1335"
verdiWindowResize -win $_vdCoverage_1 "709" "31" "2432" "1645"
verdiWindowResize -win $_vdCoverage_1 "709" "31" "2491" "1645"
gui_covtable_show -show  { Module List } -id  CoverageTable.1  -test  MergedTest
gui_list_expand -id  CoverageTable.1   -list {covtblModulesList} /Queue1_AxiWEtrBundle
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Line_pos} -value {6}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Line_width} -value {100}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Line} -value {true}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Line_U+C_pos} -value {7}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Line_U+C_width} -value {0}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Line_U+C} -value {false}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Line_U_pos} -value {8}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Line_U_width} -value {0}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Line_U} -value {false}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Line_C_pos} -value {9}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Line_C_width} -value {0}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Line_C} -value {false}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Line_X_pos} -value {10}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Line_X_width} -value {0}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Line_X} -value {false}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Toggle_pos} -value {11}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Toggle_width} -value {100}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Toggle} -value {true}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Toggle_U+C_pos} -value {12}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Toggle_U+C_width} -value {0}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Toggle_U+C} -value {false}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Toggle_U_pos} -value {13}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Toggle_U_width} -value {0}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Toggle_U} -value {false}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Toggle_C_pos} -value {14}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Toggle_C_width} -value {0}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Toggle_C} -value {false}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Toggle_X_pos} -value {15}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Toggle_X_width} -value {0}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Toggle_X} -value {false}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_FSM_pos} -value {16}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_FSM_width} -value {100}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_FSM} -value {true}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_FSM_U+C_pos} -value {17}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_FSM_U+C_width} -value {0}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_FSM_U+C} -value {false}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_FSM_U_pos} -value {18}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_FSM_U_width} -value {0}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_FSM_U} -value {false}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_FSM_C_pos} -value {19}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_FSM_C_width} -value {0}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_FSM_C} -value {false}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_FSM_X_pos} -value {20}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_FSM_X_width} -value {0}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_FSM_X} -value {false}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Condition_pos} -value {21}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Condition_width} -value {100}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Condition} -value {true}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Condition_U+C_pos} -value {22}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Condition_U+C_width} -value {0}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Condition_U+C} -value {false}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Condition_U_pos} -value {23}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Condition_U_width} -value {0}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Condition_U} -value {false}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Condition_C_pos} -value {24}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Condition_C_width} -value {0}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Condition_C} -value {false}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Condition_X_pos} -value {25}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Condition_X_width} -value {0}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Condition_X} -value {false}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Branch_pos} -value {26}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Branch_width} -value {100}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Branch} -value {true}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Branch_U+C_pos} -value {27}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Branch_U+C_width} -value {0}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Branch_U+C} -value {false}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Branch_U_pos} -value {28}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Branch_U_width} -value {0}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Branch_U} -value {false}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Branch_C_pos} -value {29}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Branch_C_width} -value {0}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Branch_C} -value {false}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Branch_X_pos} -value {30}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Branch_X_width} -value {0}
gui_set_pref_value -category {ColumnCfg} -key {covtblInstancesList_V1.1_Branch_X} -value {false}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Line_pos} -value {6}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Line_width} -value {100}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Line} -value {true}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Line_U+C_pos} -value {7}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Line_U+C_width} -value {0}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Line_U+C} -value {false}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Line_U_pos} -value {8}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Line_U_width} -value {0}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Line_U} -value {false}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Line_C_pos} -value {9}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Line_C_width} -value {0}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Line_C} -value {false}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Line_X_pos} -value {10}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Line_X_width} -value {0}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Line_X} -value {false}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Toggle_pos} -value {11}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Toggle_width} -value {100}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Toggle} -value {true}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Toggle_U+C_pos} -value {12}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Toggle_U+C_width} -value {0}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Toggle_U+C} -value {false}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Toggle_U_pos} -value {13}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Toggle_U_width} -value {0}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Toggle_U} -value {false}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Toggle_C_pos} -value {14}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Toggle_C_width} -value {0}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Toggle_C} -value {false}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Toggle_X_pos} -value {15}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Toggle_X_width} -value {0}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Toggle_X} -value {false}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_FSM_pos} -value {16}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_FSM_width} -value {100}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_FSM} -value {true}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_FSM_U+C_pos} -value {17}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_FSM_U+C_width} -value {0}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_FSM_U+C} -value {false}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_FSM_U_pos} -value {18}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_FSM_U_width} -value {0}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_FSM_U} -value {false}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_FSM_C_pos} -value {19}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_FSM_C_width} -value {0}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_FSM_C} -value {false}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_FSM_X_pos} -value {20}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_FSM_X_width} -value {0}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_FSM_X} -value {false}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Condition_pos} -value {21}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Condition_width} -value {100}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Condition} -value {true}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Condition_U+C_pos} -value {22}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Condition_U+C_width} -value {0}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Condition_U+C} -value {false}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Condition_U_pos} -value {23}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Condition_U_width} -value {0}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Condition_U} -value {false}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Condition_C_pos} -value {24}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Condition_C_width} -value {0}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Condition_C} -value {false}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Condition_X_pos} -value {25}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Condition_X_width} -value {0}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Condition_X} -value {false}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Branch_pos} -value {26}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Branch_width} -value {100}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Branch} -value {true}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Branch_U+C_pos} -value {27}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Branch_U+C_width} -value {0}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Branch_U+C} -value {false}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Branch_U_pos} -value {28}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Branch_U_width} -value {0}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Branch_U} -value {false}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Branch_C_pos} -value {29}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Branch_C_width} -value {0}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Branch_C} -value {false}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Branch_X_pos} -value {30}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Branch_X_width} -value {0}
gui_set_pref_value -category {ColumnCfg} -key {covtblModulesList_V1.1_Branch_X} -value {false}
gui_set_pref_value -category {ColumnCfg} -key {covtblClassList_flat_V1.1_Line_pos} -value {6}
gui_set_pref_value -category {ColumnCfg} -key {covtblClassList_flat_V1.1_Line_width} -value {100}
gui_set_pref_value -category {ColumnCfg} -key {covtblClassList_flat_V1.1_Line} -value {true}
gui_set_pref_value -category {ColumnCfg} -key {covtblClassList_flat_V1.1_Line_U+C_pos} -value {7}
gui_set_pref_value -category {ColumnCfg} -key {covtblClassList_flat_V1.1_Line_U+C_width} -value {0}
gui_set_pref_value -category {ColumnCfg} -key {covtblClassList_flat_V1.1_Line_U+C} -value {false}
gui_set_pref_value -category {ColumnCfg} -key {covtblClassList_flat_V1.1_Line_U_pos} -value {8}
gui_set_pref_value -category {ColumnCfg} -key {covtblClassList_flat_V1.1_Line_U_width} -value {0}
gui_set_pref_value -category {ColumnCfg} -key {covtblClassList_flat_V1.1_Line_U} -value {false}
gui_set_pref_value -category {ColumnCfg} -key {covtblClassList_flat_V1.1_Line_C_pos} -value {9}
gui_set_pref_value -category {ColumnCfg} -key {covtblClassList_flat_V1.1_Line_C_width} -value {0}
gui_set_pref_value -category {ColumnCfg} -key {covtblClassList_flat_V1.1_Line_C} -value {false}
gui_set_pref_value -category {ColumnCfg} -key {covtblClassList_flat_V1.1_Line_X_pos} -value {10}
gui_set_pref_value -category {ColumnCfg} -key {covtblClassList_flat_V1.1_Line_X_width} -value {0}
gui_set_pref_value -category {ColumnCfg} -key {covtblClassList_flat_V1.1_Line_X} -value {false}
gui_set_pref_value -category {ColumnCfg} -key {covtblClassList_hier_V1.1_Line_pos} -value {6}
gui_set_pref_value -category {ColumnCfg} -key {covtblClassList_hier_V1.1_Line_width} -value {100}
gui_set_pref_value -category {ColumnCfg} -key {covtblClassList_hier_V1.1_Line} -value {true}
gui_set_pref_value -category {ColumnCfg} -key {covtblClassList_hier_V1.1_Line_U+C_pos} -value {7}
gui_set_pref_value -category {ColumnCfg} -key {covtblClassList_hier_V1.1_Line_U+C_width} -value {0}
gui_set_pref_value -category {ColumnCfg} -key {covtblClassList_hier_V1.1_Line_U+C} -value {false}
gui_set_pref_value -category {ColumnCfg} -key {covtblClassList_hier_V1.1_Line_U_pos} -value {8}
gui_set_pref_value -category {ColumnCfg} -key {covtblClassList_hier_V1.1_Line_U_width} -value {0}
gui_set_pref_value -category {ColumnCfg} -key {covtblClassList_hier_V1.1_Line_U} -value {false}
gui_set_pref_value -category {ColumnCfg} -key {covtblClassList_hier_V1.1_Line_C_pos} -value {9}
gui_set_pref_value -category {ColumnCfg} -key {covtblClassList_hier_V1.1_Line_C_width} -value {0}
gui_set_pref_value -category {ColumnCfg} -key {covtblClassList_hier_V1.1_Line_C} -value {false}
gui_set_pref_value -category {ColumnCfg} -key {covtblClassList_hier_V1.1_Line_X_pos} -value {10}
gui_set_pref_value -category {ColumnCfg} -key {covtblClassList_hier_V1.1_Line_X_width} -value {0}
gui_set_pref_value -category {ColumnCfg} -key {covtblClassList_hier_V1.1_Line_X} -value {false}
vdCovExit -noprompt
