.PHONY: all

$(D)DISK=$(B)TAKI.DSK

# Start of taki (.ORG), in decimal

$(D)PROGRAMS = $(B)taki $(B)printer
$(D)PROGRAMS_od = $(patsubst %,%.od,$(PROGRAMS))
$(D)PROGRAMS_add = $(patsubst %,%.add,$(PROGRAMS))

$(D)taki_START = 3328
$(D)printer_START = 768

#$(foreach prog,$(PROGRAMS),$(eval $(prog)_START_HEX = $(shell printf '%02X\n' "$($(prog)_START)")))
define $(D)define_start
$(D)$(1)_START_HEX = $$(shell printf '%02X\n' "$$($(D)$(1)_START)")
#$$(info $(D)$(1)_START is $$($(D)$(1)_START))
#$$(info $(D)$(1)_START_HEX is $$($(D)$(1)_START_HEX))
endef
$(foreach prog,$($(D)PROGRAMS),$(eval $(call $(D)define_start,$(notdir $(prog)))))
$(D)GETHEX=$($(D)$(subst .add,,$@)_START_HEX)

# $D00
$(D)PROGSTART = $($(D)taki_START)
$(D)HEXPROGSTART = $($(D)taki_START_HEX)

.PHONY: $(D)all
$(D)all: $($(D)PROGRAMS_add)

.SECONDARY:

$(B)%.add: %.od $($(D)DISK)
	dos33 -y -a 0x$($(D)GETHEX) $($(D)DISK) BSAVE $(basename $@).raw $(shell echo $(basename $@) | tr '[:lower:]' '[:upper:]')
	touch $@

$($(D)DISK): $(D)empty.dsk $(B)HELLO $B
	cp $< $@
	dos33 -y $@ SAVE A $(B)HELLO

$(B)HELLO: $(B)hello.bas $B
	tokenize_asoft < $< > $@ || { rm $@; exit 1; }

$(B)hello.bas: $(D)hello.bas.in $(D)Makefile $(B)taki.raw $B
	TAKISZ=$$(stat -f '%z' $(B)taki.raw); \
	TAKIEND=$$(( $($(D)PROGSTART) + $$TAKISZ )); \
	PAGE=$$(( $$TAKIEND / 256 + 1 )); \
	sed >| $@ "s/@@PAGE@@/$${PAGE}/g" $<

$(D)%.od:
$(D)%.od: $(B)%.raw $B
	od -t u1 $< >| $@

$(B)%.raw: $(B)%.o
	ld65 -t none -o $@ $^

$(B)%.o $(B)%.list: $(D)%.s $(B)progstart.inc $B
	INC=$(B); \
	: $${INC:=.}; \
	ca65 -I"$$INC" -o $@ --listing $(subst .list,,$(subst .o,,$@)).list $<

$(B)progstart.inc: D := $D
$(B)progstart.inc: $(D)Makefile $B
	exec >| $@; \
	echo '    ; Automatically generated from Makefile.';    \
	echo '    ; DO NOT EDIT.';                              \
	echo; \
	echo 'TAKISTART = $$$($(D)HEXPROGSTART)'; \
	echo '    .org $$$($(D)HEXPROGSTART)'

.PHONY: $(D)check
$(D)check: $(D)test/check

.PHONY: $(D)clean
$(D)clean: $(D)test/clean
	rm -f *.add *.o *.list *.od *.raw $($(D)DISK)
	rm -f progstart.inc hello.bas HELLO

# ---- Include test/Makefile ----

OLD_D := $(D)
OLD_B := $(B)
D := $(D)test/
B := $(B)test/

$(D)% $(B)%: D := $(D)
$(D)% $(B)%: B := $(B)

.SECONDARY: $(B)
$(B): B := $(B)
$(B): OLD_B := $(OLD_B)
$(B): $(OLD_B)
	mkdir -p $(B)

include $(D)Makefile

D := $(OLD_D)
B := $(OLD_B)
OLD_D := __SRC_XXX__
OLD_B := __SRC_XXX__
