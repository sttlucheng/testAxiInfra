// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Implementation of DPI export functions.
//
#include "Vtb_top.h"
#include "Vtb_top__Syms.h"
#include "verilated_dpi.h"


void Vtb_top::simulation_initializeTrace(const char* traceFilePath) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_top___024root::simulation_initializeTrace\n"); );
    // Init
    static thread_local std::string traceFilePath__Vcvt;
    // Body
    static int __Vfuncnum = -1;
    if (VL_UNLIKELY(__Vfuncnum == -1)) __Vfuncnum = Verilated::exportFuncNum("simulation_initializeTrace");
    const VerilatedScope* __Vscopep = Verilated::dpiScope();
    Vtb_top__Vcb_simulation_initializeTrace_t __Vcb = (Vtb_top__Vcb_simulation_initializeTrace_t)(VerilatedScope::exportFind(__Vscopep, __Vfuncnum));
    traceFilePath__Vcvt = VL_CVT_N_CSTR(traceFilePath);
    (*__Vcb)((Vtb_top__Syms*)(__Vscopep->symsp()), traceFilePath__Vcvt);
}

void Vtb_top::simulation_enableTrace() {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_top___024root::simulation_enableTrace\n"); );
    // Body
    static int __Vfuncnum = -1;
    if (VL_UNLIKELY(__Vfuncnum == -1)) __Vfuncnum = Verilated::exportFuncNum("simulation_enableTrace");
    const VerilatedScope* __Vscopep = Verilated::dpiScope();
    Vtb_top__Vcb_simulation_enableTrace_t __Vcb = (Vtb_top__Vcb_simulation_enableTrace_t)(VerilatedScope::exportFind(__Vscopep, __Vfuncnum));
    (*__Vcb)((Vtb_top__Syms*)(__Vscopep->symsp()));
}

void Vtb_top::simulation_disableTrace() {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_top___024root::simulation_disableTrace\n"); );
    // Body
    static int __Vfuncnum = -1;
    if (VL_UNLIKELY(__Vfuncnum == -1)) __Vfuncnum = Verilated::exportFuncNum("simulation_disableTrace");
    const VerilatedScope* __Vscopep = Verilated::dpiScope();
    Vtb_top__Vcb_simulation_disableTrace_t __Vcb = (Vtb_top__Vcb_simulation_disableTrace_t)(VerilatedScope::exportFind(__Vscopep, __Vfuncnum));
    (*__Vcb)((Vtb_top__Syms*)(__Vscopep->symsp()));
}
