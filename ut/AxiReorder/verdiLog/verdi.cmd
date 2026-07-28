simSetSimulator "-vcssv" -exec \
           "/nfs/home/yanglucheng/workspace/test/AxiInfra/ut/AxiReorder/build/vcs/TestAxiReorder/sim_build/simv" \
           -args "+notimingcheck +vcs+lic+wait"
debImport "-dbdir" \
          "/nfs/home/yanglucheng/workspace/test/AxiInfra/ut/AxiReorder/build/vcs/TestAxiReorder/sim_build/simv.daidir"
debLoadSimResult \
           /nfs/home/yanglucheng/workspace/test/AxiInfra/ut/AxiReorder/build/vcs/TestAxiReorder/003.vcd.fsdb
wvCreateWindow
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
wvGetSignalOpen -win $_nWave2
wvGetSignalSetScope -win $_nWave2 "/tb_top"
verdiSetActWin -win $_nWave2
wvSetPosition -win $_nWave2 {("G1" 8)}
wvSetPosition -win $_nWave2 {("G1" 8)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/tb_top/io_slv_aw_bits_id\[11:0\]} \
{/tb_top/io_slv_aw_ready} \
{/tb_top/io_slv_aw_valid} \
{/tb_top/io_slv_b_bits_id\[11:0\]} \
{/tb_top/io_slv_b_ready} \
{/tb_top/io_slv_b_valid} \
{/tb_top/io_slv_w_ready} \
{/tb_top/io_slv_w_valid} \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 1 2 3 4 5 6 7 8 )} 
wvSetPosition -win $_nWave2 {("G1" 8)}
wvSelectGroup -win $_nWave2 {G2}
wvZoom -win $_nWave2 67016399663.826012 69114880590.856628
wvZoom -win $_nWave2 67018262496.422775 68449849351.658493
wvSetCursor -win $_nWave2 67815706572.461197 -snap {("G2" 0)}
wvSelectSignal -win $_nWave2 {( "G1" 4 )} 
wvSetPosition -win $_nWave2 {("G1" 4)}
wvSetPosition -win $_nWave2 {("G1" 6)}
wvSetPosition -win $_nWave2 {("G1" 8)}
wvSetPosition -win $_nWave2 {("G2" 0)}
wvMoveSelected -win $_nWave2
wvSetPosition -win $_nWave2 {("G2" 1)}
wvSetPosition -win $_nWave2 {("G2" 1)}
wvSelectSignal -win $_nWave2 {( "G1" 1 )} 
wvSetPosition -win $_nWave2 {("G1" 1)}
wvSetPosition -win $_nWave2 {("G1" 2)}
wvSetPosition -win $_nWave2 {("G1" 5)}
wvSetPosition -win $_nWave2 {("G1" 6)}
wvSetPosition -win $_nWave2 {("G1" 7)}
wvSetPosition -win $_nWave2 {("G2" 0)}
wvSetPosition -win $_nWave2 {("G2" 1)}
wvSetPosition -win $_nWave2 {("G3" 0)}
wvSetPosition -win $_nWave2 {("G2" 1)}
wvMoveSelected -win $_nWave2
wvSetPosition -win $_nWave2 {("G2" 2)}
wvZoom -win $_nWave2 68354707690.668480 68453196799.661613
wvSetPosition -win $_nWave2 {("G2" 0)}
wvMoveSelected -win $_nWave2
wvSetPosition -win $_nWave2 {("G2" 0)}
wvSetPosition -win $_nWave2 {("G2" 1)}
wvSelectSignal -win $_nWave2 {( "G2" 2 )} 
wvSetCursor -win $_nWave2 68355887986.240479 -snap {("G2" 2)}
wvSelectSignal -win $_nWave2 {( "G2" 2 )} 
wvSelectSignal -win $_nWave2 {( "G2" 2 )} 
wvSetPosition -win $_nWave2 {("G2" 2)}
wvExpandBus -win $_nWave2
wvSelectSignal -win $_nWave2 {( "G2" 2 )} 
wvSetPosition -win $_nWave2 {("G2" 2)}
wvCollapseBus -win $_nWave2
wvSetPosition -win $_nWave2 {("G2" 2)}
srcHBSelect "tb_top.u_AxiReorder" -win $_nTrace1
srcSetScope "tb_top.u_AxiReorder" -delim "." -win $_nTrace1
srcHBSelect "tb_top.u_AxiReorder" -win $_nTrace1
verdiSetActWin -dock widgetDock_<Inst._Tree>
srcDeselectAll -win $_nTrace1
srcSelect -signal "io_slv_b_bits_id" -line 119 -pos 1 -win $_nTrace1
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
srcDeselectAll -win $_nTrace1
srcSelect -signal "io_slv_b_bits_id" -line 119 -pos 1 -win $_nTrace1
srcActiveTrace "tb_top.u_AxiReorder.io_slv_b_bits_id\[11:0\]" -win $_nTrace1
srcActiveTrace "tb_top.io_slv_b_bits_id\[11:0\]" -win $_nTrace1
srcActiveTrace "tb_top.io_slv_b_bits_id\[11:0\]" -win $_nTrace1
srcBackwardHistory -win $_nTrace1
srcHBSelect "tb_top" -win $_nTrace1
srcForwardHistory -win $_nTrace1
srcHBSelect "tb_top" -win $_nTrace1
srcHBSelect "tb_top" -win $_nTrace1
srcActiveTrace "tb_top.io_slv_b_bits_id\[11:0\]" -win $_nTrace1
srcTraceLoad "tb_top.io_slv_b_bits_id\[11:0\]" -win $_nTrace1
wvZoomOut -win $_nWave2
verdiSetActWin -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoom -win $_nWave2 68250881022.768028 68423991041.237984
srcDeselectAll -win $_nTrace1
srcSelect -signal "io_mst_b_bits_id_0" -line 1885 -pos 1 -win $_nTrace1
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
srcTraceLoad "tb_top.u_AxiReorder.io_mst_b_bits_id_0\[11:0\]" -win $_nTrace1
srcActiveTrace "tb_top.u_AxiReorder.io_mst_b_bits_id_0\[11:0\]" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "_GEN_0\[io_slv_b_bits_id\[5:0\]\]" -line 1885 -pos 1 \
          -partailSelPos 15 -win $_nTrace1
srcTraceLoad "tb_top.u_AxiReorder.io_slv_b_bits_id\[5:0\]" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "_GEN_0\[io_slv_b_bits_id\[5:0\]\]" -line 1885 -pos 1 \
          -partailSelPos 10 -win $_nTrace1
srcActiveTrace "tb_top.u_AxiReorder.io_slv_b_bits_id\[5:0\]" -win $_nTrace1
srcShowDefine -win $_nTrace1
srcActiveTrace "tb_top.io_slv_b_bits_id\[11:0\]" -win $_nTrace1
srcHBSelect "tb_top.u_AxiReorder" -win $_nTrace1
srcSetScope "tb_top.u_AxiReorder" -delim "." -win $_nTrace1
srcHBSelect "tb_top.u_AxiReorder" -win $_nTrace1
verdiSetActWin -dock widgetDock_<Inst._Tree>
srcDeselectAll -win $_nTrace1
srcSelect -signal "io_mst_b_bits_id" -line 80 -pos 1 -win $_nTrace1
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
srcDeselectAll -win $_nTrace1
srcSelect -signal "io_slv_b_bits_id" -line 119 -pos 1 -win $_nTrace1
srcActiveTrace "tb_top.u_AxiReorder.io_slv_b_bits_id\[11:0\]" -win $_nTrace1
srcActiveTrace "tb_top.io_slv_b_bits_id\[11:0\]" -win $_nTrace1
srcHBSelect "tb_top.u_AxiReorder" -win $_nTrace1
srcSetScope "tb_top.u_AxiReorder" -delim "." -win $_nTrace1
srcHBSelect "tb_top.u_AxiReorder" -win $_nTrace1
verdiSetActWin -dock widgetDock_<Inst._Tree>
srcDeselectAll -win $_nTrace1
srcSelect -signal "io_slv_b_bits_id" -line 119 -pos 1 -win $_nTrace1
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
srcShowDefine -win $_nTrace1
srcPrevTraced -scope
srcHBSelect "tb_top" -win $_nTrace1
srcHBSelect "tb_top.u_AxiReorder" -win $_nTrace1
srcSetScope "tb_top.u_AxiReorder" -delim "." -win $_nTrace1
srcHBSelect "tb_top.u_AxiReorder" -win $_nTrace1
verdiSetActWin -dock widgetDock_<Inst._Tree>
srcDeselectAll -win $_nTrace1
srcSelect -signal "io_slv_b_bits_id" -line 119 -pos 1 -win $_nTrace1
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
srcDeselectAll -win $_nTrace1
srcSelect -signal "io_slv_b_bits_id" -line 119 -pos 1 -win $_nTrace1
srcAction -pos 118 9 13 -win $_nTrace1 -name "io_slv_b_bits_id" -ctrlKey off
srcDeselectAll -win $_nTrace1
srcSelect -signal "io_slv_b_bits_id" -line 208 -pos 1 -win $_nTrace1
srcAction -pos 207 1 8 -win $_nTrace1 -name "io_slv_b_bits_id" -ctrlKey off
srcDeselectAll -win $_nTrace1
srcSelect -signal "io_slv_b_bits_id" -line 208 -pos 1 -win $_nTrace1
srcAction -pos 207 1 8 -win $_nTrace1 -name "io_slv_b_bits_id" -ctrlKey off
srcDeselectAll -win $_nTrace1
srcSelect -signal "io_slv_b_bits_id" -line 293 -pos 1 -win $_nTrace1
srcTraceLoad "tb_top.u_AxiReorder.io_slv_b_bits_id\[11:0\]" -win $_nTrace1
srcHBSelect "tb_top.u_AxiReorder.awq" -win $_nTrace1
srcSetScope "tb_top.u_AxiReorder.awq" -delim "." -win $_nTrace1
srcHBSelect "tb_top.u_AxiReorder.awq" -win $_nTrace1
verdiSetActWin -dock widgetDock_<Inst._Tree>
srcHBSelect "tb_top.u_AxiReorder" -win $_nTrace1
srcSetScope "tb_top.u_AxiReorder" -delim "." -win $_nTrace1
srcHBSelect "tb_top.u_AxiReorder" -win $_nTrace1
srcHBSelect "tb_top" -win $_nTrace1
srcSetScope "tb_top" -delim "." -win $_nTrace1
srcHBSelect "tb_top" -win $_nTrace1
srcHBSelect "tb_top.u_AxiReorder" -win $_nTrace1
srcHBSelect "tb_top.u_AxiReorder" -win $_nTrace1
srcHBSelect "tb_top.u_AxiReorder" -win $_nTrace1
srcSetScope "tb_top.u_AxiReorder" -delim "." -win $_nTrace1
srcHBSelect "tb_top.u_AxiReorder" -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "io_mst_aw_bits_id" -line 51 -pos 1 -win $_nTrace1
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
wvSetPosition -win $_nWave2 {("G3" 0)}
wvAddSignal -win $_nWave2 "/tb_top/u_AxiReorder/io_mst_aw_bits_id\[11:0\]"
wvSetPosition -win $_nWave2 {("G3" 0)}
wvSetPosition -win $_nWave2 {("G3" 1)}
wvSetPosition -win $_nWave2 {("G3" 1)}
srcDeselectAll -win $_nTrace1
srcSelect -signal "io_mst_b_bits_id" -line 80 -pos 1 -win $_nTrace1
wvSetPosition -win $_nWave2 {("G2" 2)}
wvSetPosition -win $_nWave2 {("G3" 0)}
wvSetPosition -win $_nWave2 {("G3" 1)}
wvSetPosition -win $_nWave2 {("G4" 0)}
wvAddSignal -win $_nWave2 "/tb_top/u_AxiReorder/io_mst_b_bits_id\[11:0\]"
wvSetPosition -win $_nWave2 {("G4" 0)}
wvSetPosition -win $_nWave2 {("G4" 1)}
wvSetPosition -win $_nWave2 {("G4" 1)}
wvSetCursor -win $_nWave2 61693292191.716667 -snap {("G5" 0)}
verdiSetActWin -win $_nWave2
srcDeselectAll -win $_nTrace1
srcSelect -signal "io_mst_b_ready" -line 78 -pos 1 -win $_nTrace1
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
srcSelect -win $_nTrace1 -range {78 79 2 4 12 11}
srcDeselectAll -win $_nTrace1
srcSelect -signal "io_mst_b_ready" -line 78 -pos 1 -win $_nTrace1
srcSelect -signal "io_mst_b_valid" -line 79 -pos 1 -win $_nTrace1
wvSetPosition -win $_nWave2 {("G2" 2)}
wvSetPosition -win $_nWave2 {("G5" 0)}
wvSetPosition -win $_nWave2 {("G4" 1)}
wvAddSignal -win $_nWave2 "/tb_top/u_AxiReorder/io_mst_b_ready" \
           "/tb_top/u_AxiReorder/io_mst_b_valid"
wvSetPosition -win $_nWave2 {("G4" 1)}
wvSetPosition -win $_nWave2 {("G4" 3)}
verdiSetActWin -win $_nWave2
wvZoom -win $_nWave2 61738932383.004349 61742850985.286629
wvSetCursor -win $_nWave2 61741642184.311935 -snap {("G4" 3)}
wvZoom -win $_nWave2 61741619573.646301 61741659577.131653
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoom -win $_nWave2 61741335030.426270 61742225938.052101
wvSelectSignal -win $_nWave2 {( "G2" 2 )} 
wvSetPosition -win $_nWave2 {("G2" 2)}
wvSetPosition -win $_nWave2 {("G3" 0)}
wvSetPosition -win $_nWave2 {("G3" 1)}
wvSetPosition -win $_nWave2 {("G4" 0)}
wvSetPosition -win $_nWave2 {("G4" 1)}
wvSetPosition -win $_nWave2 {("G4" 2)}
wvSetPosition -win $_nWave2 {("G4" 3)}
wvMoveSelected -win $_nWave2
wvSetPosition -win $_nWave2 {("G4" 4)}
wvSelectSignal -win $_nWave2 {( "G3" 1 )} 
wvSetPosition -win $_nWave2 {("G3" 1)}
wvSetPosition -win $_nWave2 {("G3" 0)}
wvSetPosition -win $_nWave2 {("G2" 1)}
wvMoveSelected -win $_nWave2
wvSetPosition -win $_nWave2 {("G2" 1)}
wvSetPosition -win $_nWave2 {("G2" 2)}
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
srcDeselectAll -win $_nTrace1
srcSelect -signal "io_mst_aw_ready" -line 49 -pos 1 -win $_nTrace1
srcDeselectAll -win $_nTrace1
srcSelect -signal "io_mst_aw_valid" -line 50 -pos 1 -win $_nTrace1
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
srcDeselectAll -win $_nTrace1
srcSelect -signal "io_mst_aw_ready" -line 49 -pos 1 -win $_nTrace1
srcSelect -signal "io_mst_aw_valid" -line 50 -pos 1 -win $_nTrace1
wvSetPosition -win $_nWave2 {("G1" 1)}
wvSetPosition -win $_nWave2 {("G1" 3)}
wvSetPosition -win $_nWave2 {("G1" 4)}
wvSetPosition -win $_nWave2 {("G1" 5)}
wvSetPosition -win $_nWave2 {("G4" 4)}
wvSetPosition -win $_nWave2 {("G2" 2)}
wvSetPosition -win $_nWave2 {("G3" 0)}
wvSetPosition -win $_nWave2 {("G2" 2)}
wvAddSignal -win $_nWave2 "/tb_top/u_AxiReorder/io_mst_aw_ready" \
           "/tb_top/u_AxiReorder/io_mst_aw_valid"
wvSetPosition -win $_nWave2 {("G2" 2)}
wvSetPosition -win $_nWave2 {("G2" 4)}
srcDeselectAll -win $_nTrace1
srcSelect -signal "io_slv_aw_ready" -line 88 -pos 1 -win $_nTrace1
srcSelect -signal "io_slv_aw_valid" -line 89 -pos 1 -win $_nTrace1
wvSetPosition -win $_nWave2 {("G1" 0)}
wvSetPosition -win $_nWave2 {("G1" 1)}
wvSetPosition -win $_nWave2 {("G1" 3)}
wvSetPosition -win $_nWave2 {("G1" 4)}
wvSetPosition -win $_nWave2 {("G1" 5)}
wvSetPosition -win $_nWave2 {("G1" 6)}
wvSetPosition -win $_nWave2 {("G2" 0)}
wvAddSignal -win $_nWave2 "/tb_top/u_AxiReorder/io_slv_aw_ready" \
           "/tb_top/u_AxiReorder/io_slv_aw_valid"
wvSetPosition -win $_nWave2 {("G2" 0)}
wvSetPosition -win $_nWave2 {("G2" 2)}
verdiSetActWin -win $_nWave2
wvZoom -win $_nWave2 61675792897.953812 61683688878.190208
wvSetCursor -win $_nWave2 61678985635.631027 -snap {("G2" 5)}
wvSetCursor -win $_nWave2 61679497314.776390 -snap {("G2" 2)}
wvSetCursor -win $_nWave2 61679276521.720512 -snap {("G2" 3)}
wvSetCursor -win $_nWave2 61679248484.507072 -snap {("G2" 3)}
wvSetCursor -win $_nWave2 61679283531.023880 -snap {("G2" 3)}
wvSetCursor -win $_nWave2 61679472782.214630 -snap {("G2" 2)}
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoom -win $_nWave2 68395189118.339394 68507337972.118774
wvZoom -win $_nWave2 68425254767.545601 68429336527.869576
wvZoom -win $_nWave2 68426823699.826088 68427070091.039612
wvSetCursor -win $_nWave2 68426969806.638138 -snap {("G4" 3)}
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoom -win $_nWave2 68405487565.878235 68410274970.122894
wvSetCursor -win $_nWave2 68408572923.598915 -snap {("G2" 5)}
wvSetCursor -win $_nWave2 68408874659.685356 -snap {("G2" 2)}
