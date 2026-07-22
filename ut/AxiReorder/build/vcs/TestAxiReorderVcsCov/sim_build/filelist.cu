LDVERSION= $(shell $(PIC_LD) -v | grep -q 2.30 ;echo $$?)
ifeq ($(LDVERSION), 0)
     LD_NORELAX_FLAG= --no-relax
endif

ARCHIVE_OBJS=
ARCHIVE_OBJS += _2810882_archive_1.so
_2810882_archive_1.so : archive.0/_2810882_archive_1.a
	@$(AR) -s $<
	@$(PIC_LD) -shared  -Bsymbolic $(LD_NORELAX_FLAG)  -o .//simv.daidir//_2810882_archive_1.so --whole-archive $< --no-whole-archive
	@rm -f $@
	@ln -sf .//simv.daidir//_2810882_archive_1.so $@


ARCHIVE_OBJS += _2811043_archive_1.so
_2811043_archive_1.so : archive.0/_2811043_archive_1.a
	@$(AR) -s $<
	@$(PIC_LD) -shared  -Bsymbolic $(LD_NORELAX_FLAG)  -o .//simv.daidir//_2811043_archive_1.so --whole-archive $< --no-whole-archive
	@rm -f $@
	@ln -sf .//simv.daidir//_2811043_archive_1.so $@


ARCHIVE_OBJS += _2811045_archive_1.so
_2811045_archive_1.so : archive.0/_2811045_archive_1.a
	@$(AR) -s $<
	@$(PIC_LD) -shared  -Bsymbolic $(LD_NORELAX_FLAG)  -o .//simv.daidir//_2811045_archive_1.so --whole-archive $< --no-whole-archive
	@rm -f $@
	@ln -sf .//simv.daidir//_2811045_archive_1.so $@


ARCHIVE_OBJS += _2811051_archive_1.so
_2811051_archive_1.so : archive.0/_2811051_archive_1.a
	@$(AR) -s $<
	@$(PIC_LD) -shared  -Bsymbolic $(LD_NORELAX_FLAG)  -o .//simv.daidir//_2811051_archive_1.so --whole-archive $< --no-whole-archive
	@rm -f $@
	@ln -sf .//simv.daidir//_2811051_archive_1.so $@


ARCHIVE_OBJS += _2811054_archive_1.so
_2811054_archive_1.so : archive.0/_2811054_archive_1.a
	@$(AR) -s $<
	@$(PIC_LD) -shared  -Bsymbolic $(LD_NORELAX_FLAG)  -o .//simv.daidir//_2811054_archive_1.so --whole-archive $< --no-whole-archive
	@rm -f $@
	@ln -sf .//simv.daidir//_2811054_archive_1.so $@


ARCHIVE_OBJS += _2811056_archive_1.so
_2811056_archive_1.so : archive.0/_2811056_archive_1.a
	@$(AR) -s $<
	@$(PIC_LD) -shared  -Bsymbolic $(LD_NORELAX_FLAG)  -o .//simv.daidir//_2811056_archive_1.so --whole-archive $< --no-whole-archive
	@rm -f $@
	@ln -sf .//simv.daidir//_2811056_archive_1.so $@




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

