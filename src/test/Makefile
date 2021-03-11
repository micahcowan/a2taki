$(D)TESTS = $(B)zp $(B)hello
$(D)CMDS  = $(B)test
$(D)PROGS = $($(D)TESTS) $($(D)CMDS)

ifndef D
    D := ./
endif

.PHONY: $(D)all
$(D)all: $($(D)CMDS)

.PHONY: $(D)check
$(D)check: $($(D)TESTS)
	@$(D)run-tests $($(D)TESTS)

$(D)CC:=cc65
$(D)AS:=ca65
$(D)LD:=ld65
$(D)CFLAGS:=-Werror,-unused-param -I$(D)
$(D)LDFLAGS=--config $(D)test.cfg
$(D)LIBS=$(B)testlib.o

.PHONY: $(D)clean
$(D)clean:
	rm -f $($(D)PROGS) $(B)*.s $(B)*.o $(B)*.list

#$(B)%: $(B)%.o $(D)test.cfg $(B)testlib.o $(B)testlib-asm.o $B
#	$($(D)LD) $($(D)LDFLAGS) -o $@ $< $(B)testlib.o sim6502.lib

# The above rule gets applied once but
# not to the next program (??). Here's
# a workaround.
define $(D)workaround
$(1): $(1).o $(D)test.cfg $(B)testlib.o $(B)testlib-asm.o $$B
	$$($(D)LD) $$($(D)LDFLAGS) -o $$@ $$< $(B)testlib-asm.o $(B)testlib.o sim6502.lib
endef
$(foreach prog,$($(D)PROGS),$(eval $(call $(D)workaround,$(prog))))

$(B)%.o: $(D)%.s $B $(D)Makefile
	$($(D)AS) $($(D)ASFLAGS) --listing $(@:.o=.list) -o $@ $<

$(B)%.o: $(D)%.c $(D)testlib.h $B $(D)Makefile
	$($(D)CC) $($(D)CFLAGS) -o $(@:.o=.s) $<
	$($(D)AS) $($(D)ASFLAGS) --listing $(@:.o=.list) $(@:.o=.s)
