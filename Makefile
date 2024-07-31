BASIC=$(wildcard *.BAS)
BASIC_NO_STARTUP=$(filter-out STARTUP.BAS,$(BASIC))

define save-basic
	{ echo 'NEW'; cat $(2); echo 'SAVE $(3)'; } | \
	  bobbin -m plus --disk1 $(1)

endef

all: TAKI-CASSETTE TAKI-PRODOS.dsk TAKI-DOS.dsk

TAKI-PRODOS.dsk: TAKI-PRODOS PRODOS.dsk Makefile $(BASIC)
	rm -f $@
	cp PRODOS.dsk $@
	#prodos -t BIN -a 0x6000 $@ SAVE $< TAKI
	sz=$$(ls -l $< | awk '{print $$5}'); \
	printf 'BSAVE TAKI,A$$6000,L%u' "$$sz" | \
	bobbin -m plus --disk1 $@ --load $< --load-at 6000 \
		--delay-until INPUT >/dev/null
	$(foreach B,$(BASIC_NO_STARTUP),$(call save-basic,$@,$B,$(subst .BAS,,$B)))
	$(call save-basic,$@,STARTUP.BAS,STARTUP)

TAKI-DOS.dsk: TAKI-DOS DOS33.dsk Makefile $(BASIC)
	rm -f $@
	cp DOS33.dsk $@
	#dos33 -t BIN -a 0x6000 $@ BSAVE $< TAKI
	sz=$$(ls -l $< | awk '{print $$5}'); \
	printf 'BSAVE TAKI,A$$6000,L%u' "$$sz" | \
	bobbin -m plus --disk1 $@ --load $< --load-at 6000 \
		--delay-until INPUT >/dev/null
	$(foreach B,$(BASIC_NO_STARTUP),$(call save-basic,$@,$B,$(subst .BAS,,$B)))
	$(call save-basic,$@,STARTUP.BAS,HELLO)

TAKI-CASSETTE TAKI-PRODOS: *.s *.inc Makefile
	./build.sh

.PHONY: clean
clean:
	rm -f TAKI-PRODOS.dsk TAKI-DOS.dsk TAKI-CASSETTE TAKI-PRODOS calc-bounce bin/taki.s.rom *.o *.lst
