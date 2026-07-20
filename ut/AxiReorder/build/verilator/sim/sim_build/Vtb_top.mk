# Verilated -*- Makefile -*-
# DESCRIPTION: Verilator output: Makefile for building Verilated archive or executable
#
# Execute this makefile from the object directory:
#    make -f Vtb_top.mk

default: Vtb_top

### Constants...
# Perl executable (from $PERL, defaults to 'perl' if not set)
PERL = perl
# Python3 executable (from $PYTHON3, defaults to 'python3' if not set)
PYTHON3 = python3
# Path to Verilator kit (from $VERILATOR_ROOT)
VERILATOR_ROOT = /nfs/share/opt/verilator/share/verilator
# SystemC include directory with systemc.h (from $SYSTEMC_INCLUDE)
SYSTEMC_INCLUDE ?= 
# SystemC library directory with libsystemc.a (from $SYSTEMC_LIBDIR)
SYSTEMC_LIBDIR ?= 

### Switches...
# C++ code coverage  0/1 (from --prof-c)
VM_PROFC = 0
# SystemC output mode?  0/1 (from --sc)
VM_SC = 0
# Legacy or SystemC output mode?  0/1 (from --sc)
VM_SP_OR_SC = $(VM_SC)
# Deprecated
VM_PCLI = 1
# Deprecated: SystemC architecture to find link library path (from $SYSTEMC_ARCH)
VM_SC_TARGET_ARCH = linux

### Vars...
# Design prefix (from --prefix)
VM_PREFIX = Vtb_top
# Module prefix (from --prefix)
VM_MODPREFIX = Vtb_top
# User CFLAGS (from -CFLAGS on Verilator command line)
VM_USER_CFLAGS = \
	-DNORMAL_MODE \
	-std=c++20 \
	-I/nfs/home/yanglucheng/tools/verilua/v3.4.0/luajit-pro/luajit2.1/include \
	-I/nfs/home/yanglucheng/tools/verilua/v3.4.0/luajit-pro/luajit2.1/include/luajit-2.1 \
	-I/nfs/home/yanglucheng/tools/verilua/v3.4.0/src/include \
	-I/nfs/home/yanglucheng/tools/verilua/v3.4.0/conan_installed/include \

# User LDLIBS (from -LDFLAGS on Verilator command line)
VM_USER_LDLIBS = \
	-flto \
	-u coverageCtrl -u getCoverageCount -u getCoverage -u getCondCoverage \
	-L/nfs/home/yanglucheng/tools/verilua/v3.4.0/luajit-pro/luajit2.1/lib \
	-L/nfs/home/yanglucheng/tools/verilua/v3.4.0/shared \
	-L/nfs/home/yanglucheng/tools/verilua/v3.4.0/conan_installed/lib \
	-Wl,-rpath,/nfs/home/yanglucheng/tools/verilua/v3.4.0/luajit-pro/luajit2.1/lib \
	-Wl,-rpath,/nfs/home/yanglucheng/tools/verilua/v3.4.0/shared \
	-Wl,-rpath,/nfs/home/yanglucheng/tools/verilua/v3.4.0/conan_installed/lib \
	-lverilua_verilator \
	-Wl,--no-as-needed -Wl,--whole-archive -lluajit-5.1 -Wl,--no-whole-archive -Wl,--as-needed \

# User .cpp files (from .cpp's on Verilator command line)
VM_USER_CLASSES = \
	lightsss \
	verilator_main \

# User .cpp directories (from .cpp's on Verilator command line)
VM_USER_DIR = \
	../../../.. \
	../../../../../../../../../tools/verilua/v3.4.0/src/verilator \


### Default rules...
# Include list of all generated classes
include Vtb_top_classes.mk
# Include global rules
include $(VERILATOR_ROOT)/include/verilated.mk

### Executable rules... (from --exe)
VPATH += $(VM_USER_DIR)

lightsss.o: /nfs/home/yanglucheng/tools/verilua/v3.4.0/src/verilator/lightsss.cpp 
	$(OBJCACHE) $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(OPT_FAST)  -c -o $@ $<
verilator_main.o: /nfs/home/yanglucheng/tools/verilua/v3.4.0/src/verilator/verilator_main.cpp 
	$(OBJCACHE) $(CXX) $(CXXFLAGS) $(CPPFLAGS) $(OPT_FAST)  -c -o $@ $<

### Link rules... (from --exe)
Vtb_top: $(VK_USER_OBJS) $(VK_GLOBAL_OBJS) $(VM_PREFIX)__ALL.a $(VM_HIER_LIBS)
	$(LINK) $(LDFLAGS) $^ $(LOADLIBES) $(LDLIBS) $(LIBS) $(SC_LIBS) -o $@


# Verilated -*- Makefile -*-
