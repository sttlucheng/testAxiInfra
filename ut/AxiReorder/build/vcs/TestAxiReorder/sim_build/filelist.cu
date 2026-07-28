LDVERSION= $(shell $(PIC_LD) -v | grep -q 2.30 ;echo $$?)
ifeq ($(LDVERSION), 0)
     LD_NORELAX_FLAG= --no-relax
endif

ARCHIVE_OBJS=
ARCHIVE_OBJS += _495986_archive_1.so
_495986_archive_1.so : archive.0/_495986_archive_1.a
	@$(AR) -s $<
	@$(PIC_LD) -shared  -Bsymbolic $(LD_NORELAX_FLAG)  -o .//simv.daidir//_495986_archive_1.so --whole-archive $< --no-whole-archive
	@rm -f $@
	@ln -sf .//simv.daidir//_495986_archive_1.so $@


ARCHIVE_OBJS += _496415_archive_1.so
_496415_archive_1.so : archive.0/_496415_archive_1.a
	@$(AR) -s $<
	@$(PIC_LD) -shared  -Bsymbolic $(LD_NORELAX_FLAG)  -o .//simv.daidir//_496415_archive_1.so --whole-archive $< --no-whole-archive
	@rm -f $@
	@ln -sf .//simv.daidir//_496415_archive_1.so $@


ARCHIVE_OBJS += _496416_archive_1.so
_496416_archive_1.so : archive.0/_496416_archive_1.a
	@$(AR) -s $<
	@$(PIC_LD) -shared  -Bsymbolic $(LD_NORELAX_FLAG)  -o .//simv.daidir//_496416_archive_1.so --whole-archive $< --no-whole-archive
	@rm -f $@
	@ln -sf .//simv.daidir//_496416_archive_1.so $@


ARCHIVE_OBJS += _496417_archive_1.so
_496417_archive_1.so : archive.0/_496417_archive_1.a
	@$(AR) -s $<
	@$(PIC_LD) -shared  -Bsymbolic $(LD_NORELAX_FLAG)  -o .//simv.daidir//_496417_archive_1.so --whole-archive $< --no-whole-archive
	@rm -f $@
	@ln -sf .//simv.daidir//_496417_archive_1.so $@


ARCHIVE_OBJS += _496418_archive_1.so
_496418_archive_1.so : archive.0/_496418_archive_1.a
	@$(AR) -s $<
	@$(PIC_LD) -shared  -Bsymbolic $(LD_NORELAX_FLAG)  -o .//simv.daidir//_496418_archive_1.so --whole-archive $< --no-whole-archive
	@rm -f $@
	@ln -sf .//simv.daidir//_496418_archive_1.so $@


ARCHIVE_OBJS += _496419_archive_1.so
_496419_archive_1.so : archive.0/_496419_archive_1.a
	@$(AR) -s $<
	@$(PIC_LD) -shared  -Bsymbolic $(LD_NORELAX_FLAG)  -o .//simv.daidir//_496419_archive_1.so --whole-archive $< --no-whole-archive
	@rm -f $@
	@ln -sf .//simv.daidir//_496419_archive_1.so $@


ARCHIVE_OBJS += _496420_archive_1.so
_496420_archive_1.so : archive.0/_496420_archive_1.a
	@$(AR) -s $<
	@$(PIC_LD) -shared  -Bsymbolic $(LD_NORELAX_FLAG)  -o .//simv.daidir//_496420_archive_1.so --whole-archive $< --no-whole-archive
	@rm -f $@
	@ln -sf .//simv.daidir//_496420_archive_1.so $@




VCS_CU_ARC_OBJS = 


O0_OBJS =

$(O0_OBJS) : %.o: %.c
	$(CC_CG) $(CFLAGS_O0) -c -o $@ $<


%.o: %.c
	$(CC_CG) $(CFLAGS_CG) -c -o $@ $<
CU_UDP_OBJS = \


CU_LVL_OBJS = \
SIM_l.o 

MAIN_OBJS = \
objs/amcQw_d.o 

CU_OBJS = $(MAIN_OBJS) $(ARCHIVE_OBJS) $(CU_UDP_OBJS) $(CU_LVL_OBJS)

