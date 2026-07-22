// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Prototypes for DPI import and export functions.
//
// Verilator includes this file in all generated .cpp files that use DPI functions.
// Manually include this file where DPI .c import functions are declared to ensure
// the C functions match the expectations of the DPI imports.

#ifndef VERILATED_VTB_TOP__DPI_H_
#define VERILATED_VTB_TOP__DPI_H_  // guard

#include "svdpi.h"

#ifdef __cplusplus
extern "C" {
#endif


    // DPI EXPORTS
    // DPI export at /nfs/home/yanglucheng/workspace/test/AxiInfra/ut/AxiReorder/build/verilator/sim/tb_top.sv:438:19
    extern void simulation_disableTrace();
    // DPI export at /nfs/home/yanglucheng/workspace/test/AxiInfra/ut/AxiReorder/build/verilator/sim/tb_top.sv:407:19
    extern void simulation_enableTrace();
    // DPI export at /nfs/home/yanglucheng/workspace/test/AxiInfra/ut/AxiReorder/build/verilator/sim/tb_top.sv:313:19
    extern void simulation_initializeTrace(const char* traceFilePath);

#ifdef __cplusplus
}
#endif

#endif  // guard
