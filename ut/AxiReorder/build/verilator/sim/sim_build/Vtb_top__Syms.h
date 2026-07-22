// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table internal header
//
// Internal details; most calling programs do not need this header,
// unless using verilator public meta comments.

#ifndef VERILATED_VTB_TOP__SYMS_H_
#define VERILATED_VTB_TOP__SYMS_H_  // guard

#include "verilated.h"

// INCLUDE MODEL CLASS

#include "Vtb_top.h"

// INCLUDE MODULE CLASSES
#include "Vtb_top___024root.h"

// DPI TYPES for DPI Export callbacks (Internal use)
using Vtb_top__Vcb_simulation_disableTrace_t = void (*) (Vtb_top__Syms* __restrict vlSymsp);
using Vtb_top__Vcb_simulation_enableTrace_t = void (*) (Vtb_top__Syms* __restrict vlSymsp);
using Vtb_top__Vcb_simulation_initializeTrace_t = void (*) (Vtb_top__Syms* __restrict vlSymsp, std::string traceFilePath);

// SYMS CLASS (contains all model state)
class alignas(VL_CACHE_LINE_BYTES)Vtb_top__Syms final : public VerilatedSyms {
  public:
    // INTERNAL STATE
    Vtb_top* const __Vm_modelp;
    VlDeleter __Vm_deleter;
    bool __Vm_didInit = false;

    // MODULE INSTANCE STATE
    Vtb_top___024root              TOP;

    // SCOPE NAMES
    VerilatedScope __Vscope_TOP;
    VerilatedScope __Vscope_tb_top;
    VerilatedScope __Vscope_tb_top__u_AxiReorder;
    VerilatedScope __Vscope_tb_top__u_AxiReorder__awq;
    VerilatedScope __Vscope_tb_top__u_AxiReorder__awq__unnamedblk1;
    VerilatedScope __Vscope_tb_top__u_AxiReorder__awq__unnamedblk2;
    VerilatedScope __Vscope_tb_top__u_AxiReorder__unnamedblk1;
    VerilatedScope __Vscope_tb_top__u_AxiReorder__unnamedblk1__unnamedblk2;
    VerilatedScope __Vscope_tb_top__u_AxiReorder__unnamedblk1__unnamedblk3;
    VerilatedScope __Vscope_tb_top__u_AxiReorder__unnamedblk1__unnamedblk4;
    VerilatedScope __Vscope_tb_top__u_AxiReorder__unnamedblk1__unnamedblk5;
    VerilatedScope __Vscope_tb_top__u_AxiReorder__unnamedblk6;
    VerilatedScope __Vscope_tb_top__u_AxiReorder__wbitsq;
    VerilatedScope __Vscope_tb_top__u_AxiReorder__wbitsq__driver;
    VerilatedScope __Vscope_tb_top__u_AxiReorder__wbitsq__driver__unnamedblk1;
    VerilatedScope __Vscope_tb_top__u_AxiReorder__wbitsq__driver__unnamedblk2;
    VerilatedScope __Vscope_tb_top__u_AxiReorder__wbitsq__holder;
    VerilatedScope __Vscope_tb_top__u_AxiReorder__wbitsq__holder__unnamedblk1;
    VerilatedScope __Vscope_tb_top__u_AxiReorder__wbitsq__holder__unnamedblk2;
    VerilatedScope __Vscope_tb_top__u_AxiReorder__wbitsq__unnamedblk1;
    VerilatedScope __Vscope_tb_top__u_AxiReorder__wbitsq__unnamedblk2;
    VerilatedScope __Vscope_tb_top__u_AxiReorder__wq;
    VerilatedScope __Vscope_tb_top__u_AxiReorder__wq__driver;
    VerilatedScope __Vscope_tb_top__u_AxiReorder__wq__driver__unnamedblk1;
    VerilatedScope __Vscope_tb_top__u_AxiReorder__wq__driver__unnamedblk2;
    VerilatedScope __Vscope_tb_top__u_AxiReorder__wq__holder;
    VerilatedScope __Vscope_tb_top__u_AxiReorder__wq__holder__unnamedblk1;
    VerilatedScope __Vscope_tb_top__u_AxiReorder__wq__holder__unnamedblk2;
    VerilatedScope __Vscope_tb_top__u_AxiReorder__wq__unnamedblk1;
    VerilatedScope __Vscope_tb_top__u_AxiReorder__wq__unnamedblk2;
    VerilatedScope __Vscope_tb_top__u_others;

    // SCOPE HIERARCHY
    VerilatedHierarchy __Vhier;

    // CONSTRUCTORS
    Vtb_top__Syms(VerilatedContext* contextp, const char* namep, Vtb_top* modelp);
    ~Vtb_top__Syms();

    // METHODS
    const char* name() { return TOP.name(); }
};

#endif  // guard
