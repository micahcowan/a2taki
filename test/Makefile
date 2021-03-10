PROGS = test zp

.PHONY: all
all: check

.PHONY: check
check: $(PROGS)

%: %.c
%: %.s

CC=cc65
AS=ca65
LD=ld65
LDFLAGS=--config test.cfg

.o:
	$(LD) $(LDFLAGS) -o $@ $^ sim6502.lib
.c.o:
	$(CC) $<
	$(AS) $(ASFLAGS) $(<:.c=.s)

.PHONY: clean
clean:
	rm -f $(PROGS) test.s zp.s *.o
