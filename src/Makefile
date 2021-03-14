.PHONY: all

$(D)DISK=$(B)TAKI.DSK
$(D)TMPDISK=$(B)taki-tmp.dsk

# Start of taki (.ORG), in decimal

$(D)PROGRAMS = $(B)taki $(B)printer
$(D)PROGRAMS_od = $(patsubst %,%.od,$($(D)PROGRAMS))
$(D)PROGRAMS_add := $(foreach PROG,$($(D)PROGRAMS),$(PROG).add)

.PHONY: $(D)all
$(D)all: $($(D)DISK) $(D)test/all

$(D)TAKISTART = D00
$(B)taki.add $(B)taki.raw $(B)hello.bas: GETHEX := $($(D)TAKISTART)
$(B)printer.add $(B)printer.raw: GETHEX := 2000

$(B)%.add: $(B)%.raw $($(D)TMPDISK) $(D)Makefile
	dos33 -y -a 0x$(GETHEX) $($(D)TMPDISK) BSAVE $(basename $@).raw $(shell echo $(notdir $(basename $@)) | tr '[:lower:]' '[:upper:]')
	touch $@

$($(D)TMPDISK): $(D)empty.dsk $(B)HELLO $B
	cp $< $@
	dos33 -y $@ SAVE A $(B)HELLO

$($(D)DISK): $($(D)PROGRAMS_add)
	cp $($(D)TMPDISK) $@

$(B)HELLO: $(B)hello.bas $B
	tokenize_asoft < $< > $@ || { rm $@; exit 1; }

$(B)hello.bas: $(D)hello.bas.in $(D)Makefile $(B)taki.raw $B
	@set -x; \
	TAKISZ=$$(ls -l $(B)taki.raw | awk '{print $$5}'); \
	TAKIEND=$$(( 0 + 0x$(GETHEX) + $$TAKISZ )); \
	PAGE=$$(( $$TAKIEND / 256 + 1 )); \
	sed >| $@ "s/@@PAGE@@/$${PAGE}/g" $<

$(D)%.od:
$(D)%.od: $(B)%.raw $B
	od -t u1 $< >| $@

$(B)taki.raw: $(B)taki.o $(D)taki.cfg $(D)Makefile
	ld65 -C $(D)taki.cfg -S '$$$(GETHEX)' -D __TAKI_START__='$$$($(D)TAKISTART)' -o $@ $<

$(B)printer.raw: $(B)printer.o $(D)Makefile
	ld65 -t none -S '$$$(GETHEX)' -D __TAKI_START__='$$$($(D)TAKISTART)' -o $@ $<

$(B)%.o $(B)%.list: $(D)%.s
	mkdir -p $B
	INC=$(B); \
	: $${INC:=.}; \
	ca65 -I"$$INC" -o $@ --listing $(subst .list,,$(subst .o,,$@)).list $<

ifdef NOTDEF
$(B)progstart.inc: D := $D
$(B)progstart.inc: $(D)Makefile $B
	exec >| $@; \
	echo '    ; Automatically generated from Makefile.';    \
	echo '    ; DO NOT EDIT.';                              \
	echo; \
	echo 'TAKISTART = $$$($(D)HEXPROGSTART)'; \
	echo '    .org $$$($(D)HEXPROGSTART)'
endif

.PHONY: $(D)check
$(D)check: $(D)test/check

.PHONY: $(D)clean
$(D)clean: $(D)test/clean
	rm -f *.add *.o *.list *.od *.raw $($(D)DISK)
	rm -f progstart.inc hello.bas HELLO $($(D)TMPDISK)

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
