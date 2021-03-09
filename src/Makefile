.PHONY: all

DISK=TAKI.DSK

# Start of taki (.ORG), in decimal

PROGRAMS = taki printer
PROGRAMS_od = $(patsubst %,%.od,$(PROGRAMS))
PROGRAMS_add = $(patsubst %,%.add,$(PROGRAMS))

taki_START = 3328
printer_START = 768

#$(foreach prog,$(PROGRAMS),$(eval $(prog)_START_HEX = $(shell printf '%02X\n' "$($(prog)_START)")))
define define_start
$(1)_START_HEX = $$(shell printf '%02X\n' "$$($(1)_START)")
#$$(info $(1)_START is $$($(1)_START))
#$$(info $(1)_START_HEX is $$($(1)_START_HEX))
endef
$(foreach prog,$(PROGRAMS),$(eval $(call define_start,$(prog))))
GETHEX=$($(subst .add,,$@)_START_HEX)

# $D00
PROGSTART = $(taki_START)
HEXPROGSTART = $(taki_START_HEX)

all: $(PROGRAMS_add)

.SECONDARY:

%.add: %.od $(DISK)
	dos33 -y -a 0x$(GETHEX) $(DISK) BSAVE $(basename $@).raw $(shell echo $(basename $@) | tr '[:lower:]' '[:upper:]')
	touch $@

$(DISK): empty.dsk HELLO
	cp $< $@
	dos33 -y $@ SAVE A HELLO

HELLO: hello.bas
	tokenize_asoft < $< > $@ || { rm $@; exit 1; }

hello.bas: hello.bas.in Makefile taki.raw
	TAKISZ=$$(stat -f '%z' taki.raw); \
	TAKIEND=$$(( $(PROGSTART) + $$TAKISZ )); \
	PAGE=$$(( $$TAKIEND / 256 + 1 )); \
	sed >| $@ "s/@@PAGE@@/$${PAGE}/g" $<

%.od:
%.od: %.raw
	od -t u1 $< >| $@

%.raw: %.o
	ld65 -t none -o $@ $^

%.o %.list: %.s progstart.inc
	ca65 -I. -o $@ --listing $(subst .list,,$(subst .o,,$@)).list $<

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
	rm -f progstart.inc hello.bas HELLO
