// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtb_top.h for the primary calling header

#include "Vtb_top__pch.h"
#include "Vtb_top___024root.h"

VL_ATTR_COLD void Vtb_top___024root___eval_static(Vtb_top___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_top___024root___eval_static\n"); );
    Vtb_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__Vtrigprevexpr___TOP__clock__0 = vlSelfRef.clock;
}

VL_ATTR_COLD void Vtb_top___024root___eval_initial__TOP(Vtb_top___024root* vlSelf);

VL_ATTR_COLD void Vtb_top___024root___eval_initial(Vtb_top___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_top___024root___eval_initial\n"); );
    Vtb_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    Vtb_top___024root___eval_initial__TOP(vlSelf);
}

extern const VlWide<8>/*255:0*/ Vtb_top__ConstPool__CONST_h9e67c271_0;

VL_ATTR_COLD void Vtb_top___024root___eval_initial__TOP(Vtb_top___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_top___024root___eval_initial__TOP\n"); );
    Vtb_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.tb_top__DOT__cycles = 0ULL;
    vlSelfRef.tb_top__DOT__io_mst_aw_valid = 0U;
    vlSelfRef.tb_top__DOT__io_mst_aw_bits_id = 0U;
    vlSelfRef.tb_top__DOT__io_mst_aw_bits_addr = 0ULL;
    vlSelfRef.tb_top__DOT__io_mst_aw_bits_len = 0U;
    vlSelfRef.tb_top__DOT__io_mst_aw_bits_size = 0U;
    vlSelfRef.tb_top__DOT__io_mst_aw_bits_burst = 0U;
    vlSelfRef.tb_top__DOT__io_mst_aw_bits_lock = 0U;
    vlSelfRef.tb_top__DOT__io_mst_aw_bits_cache = 0U;
    vlSelfRef.tb_top__DOT__io_mst_aw_bits_prot = 0U;
    vlSelfRef.tb_top__DOT__io_mst_aw_bits_qos = 0U;
    vlSelfRef.tb_top__DOT__io_mst_aw_bits_region = 0U;
    vlSelfRef.tb_top__DOT__io_mst_ar_valid = 0U;
    vlSelfRef.tb_top__DOT__io_mst_ar_bits_id = 0U;
    vlSelfRef.tb_top__DOT__io_mst_ar_bits_addr = 0ULL;
    vlSelfRef.tb_top__DOT__io_mst_ar_bits_len = 0U;
    vlSelfRef.tb_top__DOT__io_mst_ar_bits_size = 0U;
    vlSelfRef.tb_top__DOT__io_mst_ar_bits_burst = 0U;
    vlSelfRef.tb_top__DOT__io_mst_ar_bits_lock = 0U;
    vlSelfRef.tb_top__DOT__io_mst_ar_bits_cache = 0U;
    vlSelfRef.tb_top__DOT__io_mst_ar_bits_prot = 0U;
    vlSelfRef.tb_top__DOT__io_mst_ar_bits_qos = 0U;
    vlSelfRef.tb_top__DOT__io_mst_ar_bits_region = 0U;
    vlSelfRef.tb_top__DOT__io_mst_w_valid = 0U;
    vlSelfRef.tb_top__DOT__io_mst_w_bits_data[0U] = 
        Vtb_top__ConstPool__CONST_h9e67c271_0[0U];
    vlSelfRef.tb_top__DOT__io_mst_w_bits_data[1U] = 
        Vtb_top__ConstPool__CONST_h9e67c271_0[1U];
    vlSelfRef.tb_top__DOT__io_mst_w_bits_data[2U] = 
        Vtb_top__ConstPool__CONST_h9e67c271_0[2U];
    vlSelfRef.tb_top__DOT__io_mst_w_bits_data[3U] = 
        Vtb_top__ConstPool__CONST_h9e67c271_0[3U];
    vlSelfRef.tb_top__DOT__io_mst_w_bits_data[4U] = 
        Vtb_top__ConstPool__CONST_h9e67c271_0[4U];
    vlSelfRef.tb_top__DOT__io_mst_w_bits_data[5U] = 
        Vtb_top__ConstPool__CONST_h9e67c271_0[5U];
    vlSelfRef.tb_top__DOT__io_mst_w_bits_data[6U] = 
        Vtb_top__ConstPool__CONST_h9e67c271_0[6U];
    vlSelfRef.tb_top__DOT__io_mst_w_bits_data[7U] = 
        Vtb_top__ConstPool__CONST_h9e67c271_0[7U];
    vlSelfRef.tb_top__DOT__io_mst_w_bits_strb = 0U;
    vlSelfRef.tb_top__DOT__io_mst_w_bits_last = 0U;
    vlSelfRef.tb_top__DOT__io_mst_b_ready = 0U;
    vlSelfRef.tb_top__DOT__io_mst_r_ready = 0U;
    vlSelfRef.tb_top__DOT__io_slv_aw_ready = 0U;
    vlSelfRef.tb_top__DOT__io_slv_ar_ready = 0U;
    vlSelfRef.tb_top__DOT__io_slv_w_ready = 0U;
    vlSelfRef.tb_top__DOT__io_slv_b_valid = 0U;
    vlSelfRef.tb_top__DOT__io_slv_b_bits_id = 0U;
    vlSelfRef.tb_top__DOT__io_slv_b_bits_resp = 0U;
    vlSelfRef.tb_top__DOT__io_slv_r_valid = 0U;
    vlSelfRef.tb_top__DOT__io_slv_r_bits_id = 0U;
    vlSelfRef.tb_top__DOT__io_slv_r_bits_data[0U] = 
        Vtb_top__ConstPool__CONST_h9e67c271_0[0U];
    vlSelfRef.tb_top__DOT__io_slv_r_bits_data[1U] = 
        Vtb_top__ConstPool__CONST_h9e67c271_0[1U];
    vlSelfRef.tb_top__DOT__io_slv_r_bits_data[2U] = 
        Vtb_top__ConstPool__CONST_h9e67c271_0[2U];
    vlSelfRef.tb_top__DOT__io_slv_r_bits_data[3U] = 
        Vtb_top__ConstPool__CONST_h9e67c271_0[3U];
    vlSelfRef.tb_top__DOT__io_slv_r_bits_data[4U] = 
        Vtb_top__ConstPool__CONST_h9e67c271_0[4U];
    vlSelfRef.tb_top__DOT__io_slv_r_bits_data[5U] = 
        Vtb_top__ConstPool__CONST_h9e67c271_0[5U];
    vlSelfRef.tb_top__DOT__io_slv_r_bits_data[6U] = 
        Vtb_top__ConstPool__CONST_h9e67c271_0[6U];
    vlSelfRef.tb_top__DOT__io_slv_r_bits_data[7U] = 
        Vtb_top__ConstPool__CONST_h9e67c271_0[7U];
    vlSelfRef.tb_top__DOT__io_slv_r_bits_resp = 0U;
    vlSelfRef.tb_top__DOT__io_slv_r_bits_last = 0U;
    vlSelfRef.tb_top__DOT__u_AxiReorder__DOT____Vxrand_h87972694__1 
        = (7U & VL_RAND_RESET_ASSIGN_I(3));
    vlSelfRef.tb_top__DOT__u_AxiReorder__DOT____Vxrand_h87972694__0 
        = (7U & VL_RAND_RESET_ASSIGN_I(3));
    vlSelfRef.tb_top__DOT__u_AxiReorder__DOT____Vxrand_h7b2f88ed__0 
        = (0xffffffffffffULL & VL_RAND_RESET_ASSIGN_Q(48));
    vlSelfRef.tb_top__DOT__u_AxiReorder__DOT____Vxrand_h8791c8f2__6 
        = (0xfffU & VL_RAND_RESET_ASSIGN_I(12));
    vlSelfRef.tb_top__DOT__u_AxiReorder__DOT____Vxrand_h8791c8f2__5 
        = (0xfffU & VL_RAND_RESET_ASSIGN_I(12));
    vlSelfRef.tb_top__DOT__u_AxiReorder__DOT____Vxrand_h8791c8f2__4 
        = (0xfffU & VL_RAND_RESET_ASSIGN_I(12));
    vlSelfRef.tb_top__DOT__u_AxiReorder__DOT____Vxrand_h8791c8f2__3 
        = (0xfffU & VL_RAND_RESET_ASSIGN_I(12));
    vlSelfRef.tb_top__DOT__u_AxiReorder__DOT____Vxrand_h8791c8f2__2 
        = (0xfffU & VL_RAND_RESET_ASSIGN_I(12));
    vlSelfRef.tb_top__DOT__u_AxiReorder__DOT____Vxrand_h8791c8f2__1 
        = (0xfffU & VL_RAND_RESET_ASSIGN_I(12));
    vlSelfRef.tb_top__DOT__u_AxiReorder__DOT____Vxrand_h8791c8f2__0 
        = (0xfffU & VL_RAND_RESET_ASSIGN_I(12));
}

VL_ATTR_COLD void Vtb_top___024root___eval_final(Vtb_top___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_top___024root___eval_final\n"); );
    Vtb_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_top___024root___dump_triggers__stl(Vtb_top___024root* vlSelf);
#endif  // VL_DEBUG
VL_ATTR_COLD bool Vtb_top___024root___eval_phase__stl(Vtb_top___024root* vlSelf);

VL_ATTR_COLD void Vtb_top___024root___eval_settle(Vtb_top___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_top___024root___eval_settle\n"); );
    Vtb_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    IData/*31:0*/ __VstlIterCount;
    CData/*0:0*/ __VstlContinue;
    // Body
    __VstlIterCount = 0U;
    vlSelfRef.__VstlFirstIteration = 1U;
    __VstlContinue = 1U;
    while (__VstlContinue) {
        if (VL_UNLIKELY(((0x64U < __VstlIterCount)))) {
#ifdef VL_DEBUG
            Vtb_top___024root___dump_triggers__stl(vlSelf);
#endif
            VL_FATAL_MT("/nfs/home/yanglucheng/workspace/test/AxiInfra/ut/AxiReorder/build/verilator/sim/tb_top.sv", 16, "", "Settle region did not converge.");
        }
        __VstlIterCount = ((IData)(1U) + __VstlIterCount);
        __VstlContinue = 0U;
        if (Vtb_top___024root___eval_phase__stl(vlSelf)) {
            __VstlContinue = 1U;
        }
        vlSelfRef.__VstlFirstIteration = 0U;
    }
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_top___024root___dump_triggers__stl(Vtb_top___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_top___024root___dump_triggers__stl\n"); );
    Vtb_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1U & (~ vlSelfRef.__VstlTriggered.any()))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelfRef.__VstlTriggered.word(0U))) {
        VL_DBG_MSGF("         'stl' region trigger index 0 is active: Internal 'stl' trigger - first iteration\n");
    }
}
#endif  // VL_DEBUG

void Vtb_top___024root___ico_sequent__TOP__0(Vtb_top___024root* vlSelf);

VL_ATTR_COLD void Vtb_top___024root___eval_stl(Vtb_top___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_top___024root___eval_stl\n"); );
    Vtb_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VstlTriggered.word(0U))) {
        Vtb_top___024root___ico_sequent__TOP__0(vlSelf);
    }
}

VL_ATTR_COLD void Vtb_top___024root___eval_triggers__stl(Vtb_top___024root* vlSelf);

VL_ATTR_COLD bool Vtb_top___024root___eval_phase__stl(Vtb_top___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_top___024root___eval_phase__stl\n"); );
    Vtb_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Init
    CData/*0:0*/ __VstlExecute;
    // Body
    Vtb_top___024root___eval_triggers__stl(vlSelf);
    __VstlExecute = vlSelfRef.__VstlTriggered.any();
    if (__VstlExecute) {
        Vtb_top___024root___eval_stl(vlSelf);
    }
    return (__VstlExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_top___024root___dump_triggers__ico(Vtb_top___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_top___024root___dump_triggers__ico\n"); );
    Vtb_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1U & (~ vlSelfRef.__VicoTriggered.any()))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelfRef.__VicoTriggered.word(0U))) {
        VL_DBG_MSGF("         'ico' region trigger index 0 is active: Internal 'ico' trigger - first iteration\n");
    }
}
#endif  // VL_DEBUG

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_top___024root___dump_triggers__act(Vtb_top___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_top___024root___dump_triggers__act\n"); );
    Vtb_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1U & (~ vlSelfRef.__VactTriggered.any()))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelfRef.__VactTriggered.word(0U))) {
        VL_DBG_MSGF("         'act' region trigger index 0 is active: @(posedge clock)\n");
    }
}
#endif  // VL_DEBUG

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_top___024root___dump_triggers__nba(Vtb_top___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_top___024root___dump_triggers__nba\n"); );
    Vtb_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1U & (~ vlSelfRef.__VnbaTriggered.any()))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelfRef.__VnbaTriggered.word(0U))) {
        VL_DBG_MSGF("         'nba' region trigger index 0 is active: @(posedge clock)\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void Vtb_top___024root___ctor_var_reset(Vtb_top___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_top___024root___ctor_var_reset\n"); );
    Vtb_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelf->clock = VL_RAND_RESET_I(1);
    vlSelf->reset = VL_RAND_RESET_I(1);
    vlSelf->cycles_o = VL_RAND_RESET_Q(64);
    vlSelf->tb_top__DOT__clock = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__reset = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__cycles_o = VL_RAND_RESET_Q(64);
    vlSelf->tb_top__DOT__cycles = VL_RAND_RESET_Q(64);
    vlSelf->tb_top__DOT__io_mst_aw_ready = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__io_mst_aw_valid = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__io_mst_aw_bits_id = VL_RAND_RESET_I(12);
    vlSelf->tb_top__DOT__io_mst_aw_bits_addr = VL_RAND_RESET_Q(48);
    vlSelf->tb_top__DOT__io_mst_aw_bits_len = VL_RAND_RESET_I(8);
    vlSelf->tb_top__DOT__io_mst_aw_bits_size = VL_RAND_RESET_I(3);
    vlSelf->tb_top__DOT__io_mst_aw_bits_burst = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__io_mst_aw_bits_lock = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__io_mst_aw_bits_cache = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__io_mst_aw_bits_prot = VL_RAND_RESET_I(3);
    vlSelf->tb_top__DOT__io_mst_aw_bits_qos = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__io_mst_aw_bits_region = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__io_mst_ar_ready = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__io_mst_ar_valid = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__io_mst_ar_bits_id = VL_RAND_RESET_I(12);
    vlSelf->tb_top__DOT__io_mst_ar_bits_addr = VL_RAND_RESET_Q(48);
    vlSelf->tb_top__DOT__io_mst_ar_bits_len = VL_RAND_RESET_I(8);
    vlSelf->tb_top__DOT__io_mst_ar_bits_size = VL_RAND_RESET_I(3);
    vlSelf->tb_top__DOT__io_mst_ar_bits_burst = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__io_mst_ar_bits_lock = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__io_mst_ar_bits_cache = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__io_mst_ar_bits_prot = VL_RAND_RESET_I(3);
    vlSelf->tb_top__DOT__io_mst_ar_bits_qos = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__io_mst_ar_bits_region = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__io_mst_w_ready = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__io_mst_w_valid = VL_RAND_RESET_I(1);
    VL_RAND_RESET_W(256, vlSelf->tb_top__DOT__io_mst_w_bits_data);
    vlSelf->tb_top__DOT__io_mst_w_bits_strb = VL_RAND_RESET_I(32);
    vlSelf->tb_top__DOT__io_mst_w_bits_last = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__io_mst_b_ready = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__io_mst_b_valid = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__io_mst_b_bits_id = VL_RAND_RESET_I(12);
    vlSelf->tb_top__DOT__io_mst_b_bits_resp = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__io_mst_r_ready = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__io_mst_r_valid = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__io_mst_r_bits_id = VL_RAND_RESET_I(12);
    VL_RAND_RESET_W(256, vlSelf->tb_top__DOT__io_mst_r_bits_data);
    vlSelf->tb_top__DOT__io_mst_r_bits_resp = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__io_mst_r_bits_last = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__io_slv_aw_ready = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__io_slv_aw_valid = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__io_slv_aw_bits_id = VL_RAND_RESET_I(12);
    vlSelf->tb_top__DOT__io_slv_aw_bits_addr = VL_RAND_RESET_Q(48);
    vlSelf->tb_top__DOT__io_slv_aw_bits_len = VL_RAND_RESET_I(8);
    vlSelf->tb_top__DOT__io_slv_aw_bits_size = VL_RAND_RESET_I(3);
    vlSelf->tb_top__DOT__io_slv_aw_bits_burst = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__io_slv_aw_bits_lock = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__io_slv_aw_bits_cache = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__io_slv_aw_bits_prot = VL_RAND_RESET_I(3);
    vlSelf->tb_top__DOT__io_slv_aw_bits_qos = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__io_slv_aw_bits_region = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__io_slv_ar_ready = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__io_slv_ar_valid = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__io_slv_ar_bits_id = VL_RAND_RESET_I(12);
    vlSelf->tb_top__DOT__io_slv_ar_bits_addr = VL_RAND_RESET_Q(48);
    vlSelf->tb_top__DOT__io_slv_ar_bits_len = VL_RAND_RESET_I(8);
    vlSelf->tb_top__DOT__io_slv_ar_bits_size = VL_RAND_RESET_I(3);
    vlSelf->tb_top__DOT__io_slv_ar_bits_burst = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__io_slv_ar_bits_lock = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__io_slv_ar_bits_cache = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__io_slv_ar_bits_prot = VL_RAND_RESET_I(3);
    vlSelf->tb_top__DOT__io_slv_ar_bits_qos = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__io_slv_ar_bits_region = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__io_slv_w_ready = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__io_slv_w_valid = VL_RAND_RESET_I(1);
    VL_RAND_RESET_W(256, vlSelf->tb_top__DOT__io_slv_w_bits_data);
    vlSelf->tb_top__DOT__io_slv_w_bits_strb = VL_RAND_RESET_I(32);
    vlSelf->tb_top__DOT__io_slv_w_bits_last = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__io_slv_b_ready = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__io_slv_b_valid = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__io_slv_b_bits_id = VL_RAND_RESET_I(12);
    vlSelf->tb_top__DOT__io_slv_b_bits_resp = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__io_slv_r_ready = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__io_slv_r_valid = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__io_slv_r_bits_id = VL_RAND_RESET_I(12);
    VL_RAND_RESET_W(256, vlSelf->tb_top__DOT__io_slv_r_bits_data);
    vlSelf->tb_top__DOT__io_slv_r_bits_resp = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__io_slv_r_bits_last = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT____Vxrand_h87972694__1 = VL_RAND_RESET_I(3);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT____Vxrand_h87972694__0 = VL_RAND_RESET_I(3);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT____Vxrand_h7b2f88ed__0 = VL_RAND_RESET_Q(48);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT____Vxrand_h8791c8f2__6 = VL_RAND_RESET_I(12);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT____Vxrand_h8791c8f2__5 = VL_RAND_RESET_I(12);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT____Vxrand_h8791c8f2__4 = VL_RAND_RESET_I(12);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT____Vxrand_h8791c8f2__3 = VL_RAND_RESET_I(12);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT____Vxrand_h8791c8f2__2 = VL_RAND_RESET_I(12);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT____Vxrand_h8791c8f2__1 = VL_RAND_RESET_I(12);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT____Vxrand_h8791c8f2__0 = VL_RAND_RESET_I(12);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__clock = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__reset = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_mst_aw_ready = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_mst_aw_valid = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_mst_aw_bits_id = VL_RAND_RESET_I(12);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_mst_aw_bits_addr = VL_RAND_RESET_Q(48);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_mst_aw_bits_len = VL_RAND_RESET_I(8);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_mst_aw_bits_size = VL_RAND_RESET_I(3);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_mst_aw_bits_burst = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_mst_aw_bits_lock = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_mst_aw_bits_cache = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_mst_aw_bits_prot = VL_RAND_RESET_I(3);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_mst_aw_bits_qos = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_mst_aw_bits_region = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_mst_ar_ready = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_mst_ar_valid = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_mst_ar_bits_id = VL_RAND_RESET_I(12);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_mst_ar_bits_addr = VL_RAND_RESET_Q(48);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_mst_ar_bits_len = VL_RAND_RESET_I(8);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_mst_ar_bits_size = VL_RAND_RESET_I(3);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_mst_ar_bits_burst = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_mst_ar_bits_lock = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_mst_ar_bits_cache = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_mst_ar_bits_prot = VL_RAND_RESET_I(3);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_mst_ar_bits_qos = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_mst_ar_bits_region = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_mst_w_ready = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_mst_w_valid = VL_RAND_RESET_I(1);
    VL_RAND_RESET_W(256, vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_mst_w_bits_data);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_mst_w_bits_strb = VL_RAND_RESET_I(32);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_mst_w_bits_last = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_mst_b_ready = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_mst_b_valid = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_mst_b_bits_id = VL_RAND_RESET_I(12);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_mst_b_bits_resp = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_mst_r_ready = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_mst_r_valid = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_mst_r_bits_id = VL_RAND_RESET_I(12);
    VL_RAND_RESET_W(256, vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_mst_r_bits_data);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_mst_r_bits_resp = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_mst_r_bits_last = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_slv_aw_ready = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_slv_aw_valid = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_slv_aw_bits_id = VL_RAND_RESET_I(12);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_slv_aw_bits_addr = VL_RAND_RESET_Q(48);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_slv_aw_bits_len = VL_RAND_RESET_I(8);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_slv_aw_bits_size = VL_RAND_RESET_I(3);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_slv_aw_bits_burst = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_slv_aw_bits_lock = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_slv_aw_bits_cache = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_slv_aw_bits_prot = VL_RAND_RESET_I(3);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_slv_aw_bits_qos = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_slv_aw_bits_region = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_slv_ar_ready = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_slv_ar_valid = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_slv_ar_bits_id = VL_RAND_RESET_I(12);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_slv_ar_bits_addr = VL_RAND_RESET_Q(48);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_slv_ar_bits_len = VL_RAND_RESET_I(8);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_slv_ar_bits_size = VL_RAND_RESET_I(3);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_slv_ar_bits_burst = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_slv_ar_bits_lock = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_slv_ar_bits_cache = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_slv_ar_bits_prot = VL_RAND_RESET_I(3);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_slv_ar_bits_qos = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_slv_ar_bits_region = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_slv_w_ready = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_slv_w_valid = VL_RAND_RESET_I(1);
    VL_RAND_RESET_W(256, vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_slv_w_bits_data);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_slv_w_bits_strb = VL_RAND_RESET_I(32);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_slv_w_bits_last = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_slv_b_ready = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_slv_b_valid = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_slv_b_bits_id = VL_RAND_RESET_I(12);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_slv_b_bits_resp = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_slv_r_ready = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_slv_r_valid = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_slv_r_bits_id = VL_RAND_RESET_I(12);
    VL_RAND_RESET_W(256, vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_slv_r_bits_data);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_slv_r_bits_resp = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_slv_r_bits_last = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_mst_w_ready_0 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_mst_aw_ready_0 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___wbitsq_io_enq_ready = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___wbitsq_io_deq_valid = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___wbitsq_io_deq_bits_entry = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___wq_io_enq_ready = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___wq_io_deq_valid = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___wq_io_deq_bits = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___awq_io_enq_ready = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___awq_io_deq_valid = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___awq_io_deq_bits_entry = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__rvld_0 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__rvld_0_0 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__rvld_1 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__rvld_1_0 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__rvld_2 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__rvld_2_0 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__rvld_3 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__rvld_3_0 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wvld_0 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wvld_0_0 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wvld_1 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wvld_1_0 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wvld_2 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wvld_2_0 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wvld_3 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wvld_3_0 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_0_bits_id = VL_RAND_RESET_I(12);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_0_bits_addr = VL_RAND_RESET_Q(48);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_0_bits_len = VL_RAND_RESET_I(8);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_0_bits_size = VL_RAND_RESET_I(3);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_0_bits_burst = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_0_bits_lock = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_0_bits_cache = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_0_bits_prot = VL_RAND_RESET_I(3);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_0_bits_qos = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_0_bits_region = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_0_nid = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_0_nid_0 = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_0_haveSendAR = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_1_bits_id = VL_RAND_RESET_I(12);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_1_bits_addr = VL_RAND_RESET_Q(48);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_1_bits_len = VL_RAND_RESET_I(8);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_1_bits_size = VL_RAND_RESET_I(3);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_1_bits_burst = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_1_bits_lock = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_1_bits_cache = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_1_bits_prot = VL_RAND_RESET_I(3);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_1_bits_qos = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_1_bits_region = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_1_nid = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_1_nid_0 = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_1_haveSendAR = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_2_bits_id = VL_RAND_RESET_I(12);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_2_bits_addr = VL_RAND_RESET_Q(48);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_2_bits_len = VL_RAND_RESET_I(8);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_2_bits_size = VL_RAND_RESET_I(3);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_2_bits_burst = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_2_bits_lock = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_2_bits_cache = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_2_bits_prot = VL_RAND_RESET_I(3);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_2_bits_qos = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_2_bits_region = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_2_nid = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_2_nid_0 = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_2_haveSendAR = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_3_bits_id = VL_RAND_RESET_I(12);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_3_bits_addr = VL_RAND_RESET_Q(48);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_3_bits_len = VL_RAND_RESET_I(8);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_3_bits_size = VL_RAND_RESET_I(3);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_3_bits_burst = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_3_bits_lock = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_3_bits_cache = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_3_bits_prot = VL_RAND_RESET_I(3);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_3_bits_qos = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_3_bits_region = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_3_nid = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_3_nid_0 = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arinfo_3_haveSendAR = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__awinfo_0_id = VL_RAND_RESET_I(12);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__awinfo_0_nid = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__awinfo_0_nid_0 = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__awinfo_0_haveSendAW = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__awinfo_1_id = VL_RAND_RESET_I(12);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__awinfo_1_nid = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__awinfo_1_nid_0 = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__awinfo_1_haveSendAW = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__awinfo_2_id = VL_RAND_RESET_I(12);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__awinfo_2_nid = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__awinfo_2_nid_0 = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__awinfo_2_haveSendAW = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__awinfo_3_id = VL_RAND_RESET_I(12);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__awinfo_3_nid = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__awinfo_3_nid_0 = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__awinfo_3_haveSendAW = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___arsel_res_bits_T = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___arsel_T_1 = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arsel_valid = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___arsel_res_bits_T_1 = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___awsel_res_bits_T = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___awsel_T_1 = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__awsel_valid = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___awsel_res_bits_T_1 = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__slvRHitEtr = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___rFireSlvHit_T_12 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___arMstFireHit_T_9 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___GEN = VL_RAND_RESET_Q(48);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__rWkVldReg = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__rWkEtrReg = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___bFireSlvHit_T_12 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wq_io_enq_valid = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___GEN_0 = VL_RAND_RESET_Q(48);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_mst_b_bits_id_0 = VL_RAND_RESET_I(12);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wWkVldReg = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wWkEtrReg = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__ar_mst_fire_hit_0 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___GEN_1 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___layer_probe = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___layer_probe_0 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___GEN_2 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___GEN_3 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___layer_probe_1 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___layer_probe_2 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arShouldSend_0 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__ar_mst_fire_hit_1 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___layer_probe_3 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___layer_probe_4 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___GEN_4 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___GEN_5 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___layer_probe_5 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___layer_probe_6 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arShouldSend_1 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__ar_mst_fire_hit_2 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___layer_probe_7 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___layer_probe_8 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___GEN_6 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___GEN_7 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___layer_probe_9 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___layer_probe_10 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__arShouldSend_2 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__ar_mst_fire_hit_3 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___layer_probe_11 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___layer_probe_12 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___GEN_8 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___GEN_9 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___layer_probe_13 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___layer_probe_14 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__aw_mst_fire_hit_0 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___layer_probe_15 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__aw_mst_fire_hit_1 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___layer_probe_16 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__aw_mst_fire_hit_2 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___layer_probe_17 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__aw_mst_fire_hit_3 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___layer_probe_18 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__selSendAR = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wq_io_enq_bits_hi = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wq_io_enq_bits_lo = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___wbitsq_io_enq_valid_T = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___GEN_10 = VL_RAND_RESET_I(8);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___io_slv_aw_valid_T = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__awq_io_deq_ready = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___GEN_11 = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___GEN_12 = VL_RAND_RESET_I(1);
    VL_RAND_RESET_W(192, vlSelf->tb_top__DOT__u_AxiReorder__DOT___GEN_13);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___GEN_14 = VL_RAND_RESET_I(32);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___GEN_15 = VL_RAND_RESET_I(12);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___GEN_16 = VL_RAND_RESET_I(8);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___GEN_17 = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___GEN_18 = VL_RAND_RESET_I(16);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___GEN_19 = VL_RAND_RESET_I(12);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___GEN_20 = VL_RAND_RESET_I(16);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT___GEN_21 = VL_RAND_RESET_I(16);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__io_slv_ar_valid_0 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT____Vcellinp__awq__io_enq_bits_entry = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT____Vcellinp__awq__io_enq_valid = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT____Vcellinp__wq__io_deq_ready = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wq_io_deq_valid = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT____Vcellinp__wbitsq__io_deq_ready = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__unnamedblk1__DOT__rawRNid = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__unnamedblk1__DOT__rawWNid = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__unnamedblk1__DOT__rWkVld = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__unnamedblk1__DOT__wWkVld = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__unnamedblk1__DOT___arSlvFireHit_T_9 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__unnamedblk1__DOT___GEN_22 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__unnamedblk1__DOT__unnamedblk2__DOT___GEN_23 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__unnamedblk1__DOT__unnamedblk2__DOT___GEN_24 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__unnamedblk1__DOT__unnamedblk3__DOT___GEN_25 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__unnamedblk1__DOT__unnamedblk3__DOT___GEN_26 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__unnamedblk1__DOT__unnamedblk4__DOT___GEN_27 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__unnamedblk1__DOT__unnamedblk4__DOT___GEN_28 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__unnamedblk1__DOT__unnamedblk5__DOT___GEN_29 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__unnamedblk1__DOT__unnamedblk5__DOT___GEN_30 = VL_RAND_RESET_I(1);
    for (int __Vi0 = 0; __Vi0 < 14; ++__Vi0) {
        vlSelf->tb_top__DOT__u_AxiReorder__DOT__unnamedblk6__DOT___RANDOM[__Vi0] = VL_RAND_RESET_I(32);
    }
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__awq__DOT__clock = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__awq__DOT__reset = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__awq__DOT__io_enq_ready = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__awq__DOT__io_enq_valid = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__awq__DOT__io_enq_bits_awinfo_id = VL_RAND_RESET_I(12);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__awq__DOT__io_enq_bits_awinfo_addr = VL_RAND_RESET_Q(48);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__awq__DOT__io_enq_bits_awinfo_len = VL_RAND_RESET_I(8);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__awq__DOT__io_enq_bits_awinfo_size = VL_RAND_RESET_I(3);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__awq__DOT__io_enq_bits_awinfo_burst = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__awq__DOT__io_enq_bits_awinfo_lock = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__awq__DOT__io_enq_bits_awinfo_cache = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__awq__DOT__io_enq_bits_awinfo_prot = VL_RAND_RESET_I(3);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__awq__DOT__io_enq_bits_awinfo_qos = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__awq__DOT__io_enq_bits_awinfo_region = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__awq__DOT__io_enq_bits_entry = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__awq__DOT__io_deq_ready = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__awq__DOT__io_deq_valid = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__awq__DOT__io_deq_bits_awinfo_addr = VL_RAND_RESET_Q(48);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__awq__DOT__io_deq_bits_awinfo_len = VL_RAND_RESET_I(8);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__awq__DOT__io_deq_bits_awinfo_size = VL_RAND_RESET_I(3);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__awq__DOT__io_deq_bits_awinfo_burst = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__awq__DOT__io_deq_bits_awinfo_lock = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__awq__DOT__io_deq_bits_awinfo_cache = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__awq__DOT__io_deq_bits_awinfo_prot = VL_RAND_RESET_I(3);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__awq__DOT__io_deq_bits_awinfo_qos = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__awq__DOT__io_deq_bits_awinfo_region = VL_RAND_RESET_I(4);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__awq__DOT__io_deq_bits_entry = VL_RAND_RESET_I(2);
    VL_RAND_RESET_W(91, vlSelf->tb_top__DOT__u_AxiReorder__DOT__awq__DOT__ram);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__awq__DOT__maybe_full = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__awq__DOT__io_enq_ready_0 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__awq__DOT__unnamedblk1__DOT__do_enq = VL_RAND_RESET_I(1);
    for (int __Vi0 = 0; __Vi0 < 3; ++__Vi0) {
        vlSelf->tb_top__DOT__u_AxiReorder__DOT__awq__DOT__unnamedblk2__DOT___RANDOM[__Vi0] = VL_RAND_RESET_I(32);
    }
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wq__DOT__clock = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wq__DOT__reset = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wq__DOT__io_enq_ready = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wq__DOT__io_enq_valid = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wq__DOT__io_enq_bits = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wq__DOT__io_deq_ready = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wq__DOT__io_deq_valid = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wq__DOT__io_deq_bits = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wq__DOT___holder_io_deq_valid = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wq__DOT___holder_io_deq_bits = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wq__DOT___driver_io_enq_ready = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wq__DOT___driver_io_deq_valid = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wq__DOT__waterline = VL_RAND_RESET_I(3);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wq__DOT__waterline_0 = VL_RAND_RESET_I(3);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wq__DOT__full = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wq__DOT__unnamedblk1__DOT__ptrMoveVec = VL_RAND_RESET_I(2);
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->tb_top__DOT__u_AxiReorder__DOT__wq__DOT__unnamedblk2__DOT___RANDOM[__Vi0] = VL_RAND_RESET_I(32);
    }
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wq__DOT__driver__DOT__clock = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wq__DOT__driver__DOT__reset = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wq__DOT__driver__DOT__io_enq_ready = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wq__DOT__driver__DOT__io_enq_valid = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wq__DOT__driver__DOT__io_enq_bits = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wq__DOT__driver__DOT__io_deq_ready = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wq__DOT__driver__DOT__io_deq_valid = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wq__DOT__driver__DOT__io_deq_bits = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wq__DOT__driver__DOT__maybe_full = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wq__DOT__driver__DOT__io_enq_ready_0 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wq__DOT__driver__DOT__ram = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wq__DOT__driver__DOT__unnamedblk1__DOT__do_enq = VL_RAND_RESET_I(1);
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->tb_top__DOT__u_AxiReorder__DOT__wq__DOT__driver__DOT__unnamedblk2__DOT___RANDOM[__Vi0] = VL_RAND_RESET_I(32);
    }
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wq__DOT__holder__DOT__clock = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wq__DOT__holder__DOT__reset = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wq__DOT__holder__DOT__io_enq_valid = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wq__DOT__holder__DOT__io_enq_bits = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wq__DOT__holder__DOT__io_deq_ready = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wq__DOT__holder__DOT__io_deq_valid = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wq__DOT__holder__DOT__io_deq_bits = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wq__DOT__holder__DOT__ram = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wq__DOT__holder__DOT__maybe_full = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wq__DOT__holder__DOT__io_deq_valid_0 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wq__DOT__holder__DOT__unnamedblk1__DOT__do_enq = VL_RAND_RESET_I(1);
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->tb_top__DOT__u_AxiReorder__DOT__wq__DOT__holder__DOT__unnamedblk2__DOT___RANDOM[__Vi0] = VL_RAND_RESET_I(32);
    }
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__clock = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__reset = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__io_enq_ready = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__io_enq_valid = VL_RAND_RESET_I(1);
    VL_RAND_RESET_W(256, vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__io_enq_bits_winfo_data);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__io_enq_bits_winfo_strb = VL_RAND_RESET_I(32);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__io_enq_bits_winfo_last = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__io_enq_bits_entry = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__io_deq_ready = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__io_deq_valid = VL_RAND_RESET_I(1);
    VL_RAND_RESET_W(256, vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__io_deq_bits_winfo_data);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__io_deq_bits_winfo_strb = VL_RAND_RESET_I(32);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__io_deq_bits_winfo_last = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__io_deq_bits_entry = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT___holder_io_deq_valid = VL_RAND_RESET_I(1);
    VL_RAND_RESET_W(256, vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT___holder_io_deq_bits_winfo_data);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT___holder_io_deq_bits_winfo_strb = VL_RAND_RESET_I(32);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT___holder_io_deq_bits_winfo_last = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT___holder_io_deq_bits_entry = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT___driver_io_enq_ready = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT___driver_io_deq_valid = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__waterline = VL_RAND_RESET_I(3);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__waterline_0 = VL_RAND_RESET_I(3);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__full = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__unnamedblk1__DOT__ptrMoveVec = VL_RAND_RESET_I(2);
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__unnamedblk2__DOT___RANDOM[__Vi0] = VL_RAND_RESET_I(32);
    }
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__driver__DOT__clock = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__driver__DOT__reset = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__driver__DOT__io_enq_ready = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__driver__DOT__io_enq_valid = VL_RAND_RESET_I(1);
    VL_RAND_RESET_W(256, vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__driver__DOT__io_enq_bits_winfo_data);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__driver__DOT__io_enq_bits_winfo_strb = VL_RAND_RESET_I(32);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__driver__DOT__io_enq_bits_winfo_last = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__driver__DOT__io_enq_bits_entry = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__driver__DOT__io_deq_ready = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__driver__DOT__io_deq_valid = VL_RAND_RESET_I(1);
    VL_RAND_RESET_W(256, vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__driver__DOT__io_deq_bits_winfo_data);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__driver__DOT__io_deq_bits_winfo_strb = VL_RAND_RESET_I(32);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__driver__DOT__io_deq_bits_winfo_last = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__driver__DOT__io_deq_bits_entry = VL_RAND_RESET_I(2);
    VL_RAND_RESET_W(291, vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__driver__DOT__ram);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__driver__DOT__maybe_full = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__driver__DOT__io_enq_ready_0 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__driver__DOT__unnamedblk1__DOT__do_enq = VL_RAND_RESET_I(1);
    for (int __Vi0 = 0; __Vi0 < 10; ++__Vi0) {
        vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__driver__DOT__unnamedblk2__DOT___RANDOM[__Vi0] = VL_RAND_RESET_I(32);
    }
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__holder__DOT__clock = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__holder__DOT__reset = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__holder__DOT__io_enq_valid = VL_RAND_RESET_I(1);
    VL_RAND_RESET_W(256, vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__holder__DOT__io_enq_bits_winfo_data);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__holder__DOT__io_enq_bits_winfo_strb = VL_RAND_RESET_I(32);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__holder__DOT__io_enq_bits_winfo_last = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__holder__DOT__io_enq_bits_entry = VL_RAND_RESET_I(2);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__holder__DOT__io_deq_ready = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__holder__DOT__io_deq_valid = VL_RAND_RESET_I(1);
    VL_RAND_RESET_W(256, vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__holder__DOT__io_deq_bits_winfo_data);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__holder__DOT__io_deq_bits_winfo_strb = VL_RAND_RESET_I(32);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__holder__DOT__io_deq_bits_winfo_last = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__holder__DOT__io_deq_bits_entry = VL_RAND_RESET_I(2);
    VL_RAND_RESET_W(291, vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__holder__DOT__ram);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__holder__DOT__maybe_full = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__holder__DOT__io_deq_valid_0 = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__holder__DOT__unnamedblk1__DOT__do_enq = VL_RAND_RESET_I(1);
    for (int __Vi0 = 0; __Vi0 < 10; ++__Vi0) {
        vlSelf->tb_top__DOT__u_AxiReorder__DOT__wbitsq__DOT__holder__DOT__unnamedblk2__DOT___RANDOM[__Vi0] = VL_RAND_RESET_I(32);
    }
    vlSelf->tb_top__DOT__u_others__DOT__clock = VL_RAND_RESET_I(1);
    vlSelf->tb_top__DOT__u_others__DOT__reset = VL_RAND_RESET_I(1);
    vlSelf->__Vtrigprevexpr___TOP__clock__0 = VL_RAND_RESET_I(1);
}
