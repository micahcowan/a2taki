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
	rm -f $($(D)PROGS) $(B)*.s $(B)*.o

#$($(D)PROGS): $@.o
$(B)%: $(B)%.o
	$($(D)LD) $($(D)LDFLAGS) -o $@ $^ sim6502.lib

$(B)%.o: $(B)%.s
	$($(D)AS) $($(D)ASFLAGS) $(@:.o=.s)

#$(B)%.s: D := $D
$(B)%.s: $(D)%.c $B
	$($(D)CC) -o $(@:.o=.s) $<
