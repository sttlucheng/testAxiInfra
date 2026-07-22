// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtb_top.h for the primary calling header

#include "Vtb_top__pch.h"
#include "Vtb_top__Syms.h"
#include "Vtb_top___024root.h"

void Vtb_top___024root____Vdpiexp_tb_top__DOT__simulation_initializeTrace_TOP(Vtb_top__Syms* __restrict vlSymsp, std::string traceFilePath) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_top___024root____Vdpiexp_tb_top__DOT__simulation_initializeTrace_TOP\n"); );
    // Init
    // Body
    VL_WRITEF_NX("[INFO] @%0t [/nfs/home/yanglucheng/workspace/test/AxiInfra/ut/AxiReorder/build/verilator/sim/tb_top.sv:        317] simulation_initializeTrace trace type => VCD\n",0,
                 64,VL_TIME_UNITED_Q(1000),-9);
    vlSymsp->_vm_contextp__->dumpfile(VL_CVT_PACK_STR_NN(traceFilePath));
    VL_PRINTF_MT("-Info: /nfs/home/yanglucheng/workspace/test/AxiInfra/ut/AxiReorder/build/verilator/sim/tb_top.sv:319: $dumpvar ignored, as Verilated without --trace\n");
}

void Vtb_top___024root____Vdpiexp_tb_top__DOT__simulation_enableTrace_TOP(Vtb_top__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_top___024root____Vdpiexp_tb_top__DOT__simulation_enableTrace_TOP\n"); );
    // Init
    // Body
    VL_WRITEF_NX("[INFO] @%0t [/nfs/home/yanglucheng/workspace/test/AxiInfra/ut/AxiReorder/build/verilator/sim/tb_top.sv:        409] simulation_enableTrace trace type => VCD\n",0,
                 64,VL_TIME_UNITED_Q(1000),-9);
}

void Vtb_top___024root____Vdpiexp_tb_top__DOT__simulation_disableTrace_TOP(Vtb_top__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_top___024root____Vdpiexp_tb_top__DOT__simulation_disableTrace_TOP\n"); );
    // Init
    // Body
    VL_WRITEF_NX("[INFO] @%0t [/nfs/home/yanglucheng/workspace/test/AxiInfra/ut/AxiReorder/build/verilator/sim/tb_top.sv:        440] simulation_disableTrace trace type => VCD\n",0,
                 64,VL_TIME_UNITED_Q(1000),-9);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_top___024root___dump_triggers__ico(Vtb_top___024root* vlSelf);
#endif  // VL_DEBUG

void Vtb_top___024root___eval_triggers__ico(Vtb_top___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_top___024root___eval_triggers__ico\n"); );
    Vtb_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VicoTriggered.setBit(0U, (IData)(vlSelfRef.__VicoFirstIteration));
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vtb_top___024root___dump_triggers__ico(vlSelf);
    }
#endif
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_top___024root___dump_triggers__act(Vtb_top___024root* vlSelf);
#endif  // VL_DEBUG

void Vtb_top___024root___eval_triggers__act(Vtb_top___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_top___024root___eval_triggers__act\n"); );
    Vtb_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VactTriggered.setBit(0U, ((IData)(vlSelfRef.clock) 
                                          & (~ (IData)(vlSelfRef.__Vtrigprevexpr___TOP__clock__0))));
    vlSelfRef.__Vtrigprevexpr___TOP__clock__0 = vlSelfRef.clock;
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vtb_top___024root___dump_triggers__act(vlSelf);
    }
#endif
}
