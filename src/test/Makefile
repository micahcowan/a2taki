ifndef D
    D := ./
endif

$(D)TESTS = $(B)hello $(B)flashinv
$(D)CMDS  = $(B)test $(B)zp
$(D)PROGS = $($(D)TESTS) $($(D)CMDS)

.PHONY: $(D)all
$(D)all: $($(D)CMDS) $(B)rndtest

.PHONY: $(D)check
$(D)check: $($(D)TESTS)
	@$(D)run-tests $($(D)TESTS)

$(D)CC:=cc65
$(D)AS:=ca65
$(D)LD:=ld65
$(D)CFLAGS:=-Werror,-unused-param -I$(D)
$(D)LDFLAGS=--config $(D)test.cfg
$(D)LIBS=$(B)testlib.o

# Assumes we were invoked from ../Makefile
$(D)TAKI_O = $(shell dirname $B)/taki.o

$(D)BUILT_S = $(patsubst %.c,%.s,$(patsubst %/,$(B),$(wildcard $(D)*.c)))

%.o: %.c
%.o: %.s

.PHONY: $(D)clean
$(D)clean:
	rm -f $($(D)PROGS) $($(D)BUILT_S) $(B)*.o $(B)*.list $(B)rndtest

#$(B)%: $(B)%.o $(D)test.cfg $(B)patchhdr.o $(B)testlib.o $(B)testlib-asm.o $(B)a2rom.o
#	mkdir -p $B
#	$($(D)LD) $($(D)LDFLAGS) -o $@ $(B)patchhdr.o $< $(B)testlib-asm.o $(B)testlib.o $(B)a2rom.o sim6502.lib

# The above rule gets applied once but
# not to the next program (??). Here's
# a workaround.
define $(D)workaround
$(1): $(1).o $($(D)TAKI_O) $(B)patchhdr.o $(D)test.cfg $(B)testlib.o $(B)testlib-asm.o $(B)a2rom.o $$B
	$$($(D)LD) $$($(D)LDFLAGS) -o $$@ $(B)patchhdr.o $($(D)TAKI_O) $$< $(B)testlib-asm.o $(B)testlib.o $(B)a2rom.o sim6502.lib
endef
$(foreach prog,$($(D)PROGS),$(eval $(call $(D)workaround,$(prog))))

$(B)rndtest: rndtest.o rnd.o $B
	$($(D)LD) -o $@ -t sim6502 $(B)rndtest.o $(B)rnd.o sim6502.lib

$(B)%.o: $(D)%.s $B $(D)Makefile
	$($(D)AS) $($(D)ASFLAGS) --listing $(@:.o=.list) -o $@ $<

$(B)%.o: $(D)%.c $(D)testlib.h $B $(D)Makefile
	$($(D)CC) $($(D)CFLAGS) -o $(@:.o=.s) $<
	$($(D)AS) $($(D)ASFLAGS) --listing $(@:.o=.list) $(@:.o=.s)
