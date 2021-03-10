$(D)PROGS = $(B)test $(B)zp

.PHONY: $(D)all
$(D)all: $(D)check

.PHONY: $(D)check
$(D)check: $($(D)PROGS)

$(D)CC:=cc65
$(D)AS:=ca65
$(D)LD:=ld65
$(D)LDFLAGS=--config $(D)test.cfg

.PHONY: $(D)clean
$(D)clean:
	rm -f $($(D)PROGS) $(B)*.s $(B)*.o $(B)*.list

$(B)%: $(B)%.o $B
	$($(D)LD) $($(D)LDFLAGS) -o $@ $< sim6502.lib

# The above rule gets applied once but
# not to the next program (??). Here's
# a workaround.
define $(D)workaround
$(1): $(1).o $$B
	$$($(D)LD) $$($(D)LDFLAGS) -o $$@ $$< sim6502.lib
endef
$(foreach prog,$($(D)PROGS),$(eval $(call $(D)workaround,$(prog))))

$(B)%.o: $(B)%.s $B
	$($(D)AS) $($(D)ASFLAGS) $(@:.o=.s)

$(B)%.o: $(D)%.c $B
	$($(D)CC) -o $(@:.o=.s) $<
	$($(D)AS) $($(D)ASFLAGS) $(@:.o=.s)

$(B)%.s: $(D)%.c $B
	$($(D)CC) -o $(@:.c=.s) $<
