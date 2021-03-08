.PHONY: all

DISK=TAKI.DSK

# Start of taki (.ORG), in decimal

# $C00
PROGSTART := 3072
HEXPROGSTART := $(shell printf '%02X\n' "$(PROGSTART)")

PROGRAMS = taki
PROGRAMS_od = $(patsubst %,%.od,$(PROGRAMS))
PROGRAMS_add = $(patsubst %,%.add,$(PROGRAMS))

all: $(PROGRAMS_add)

.SECONDARY:

%.add: %.od $(DISK)
	dos33 -y -a 0x$(HEXPROGSTART) $(DISK) BSAVE $(basename $@).raw $(shell echo $(basename $@) | tr '[:lower:]' '[:upper:]')
	touch $@

$(DISK): empty.dsk HELLO
	cp empty.dsk $(DISK)
	dos33 -y $(DISK) SAVE A HELLO

HELLO: hello.bas
	tokenize_asoft < $< > $@ || { rm $@; exit 1; }

hello.bas: hello.bas.in Makefile taki.raw
	TAKISZ=$$(stat -f '%z' taki.raw); \
	TAKIEND=$$(( $(PROGSTART) + $$TAKISZ )); \
	PAGE=$$(( $$TAKIEND / 256 + 1 )); \
	sed >| $@ "s/@@PAGE@@/$${PAGE}/g" hello.bas.in

%.od:
%.od: %.raw
	od -t u1 $< >| $@

%.raw: %.o
	ld65 -t none -o $@ $^

%.o %.list: %.s progstart.inc
	ca65 --listing $(basename $@).list $(basename $@).s

progstart.inc: Makefile
	exec >| $@; \
	echo '    ; Automatically generated from Makefile.';    \
	echo '    ; DO NOT EDIT.';                              \
	echo; \
	echo 'TAKISTART = $$$(HEXPROGSTART)'; \
	echo '    .org $$$(HEXPROGSTART)'

.PHONY: clean
clean:
	rm -f *.add *.o *.list *.od *.raw $(DISK)
	rm -f progstart.inc hello.bas
