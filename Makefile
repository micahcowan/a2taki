.PHONY: all

SUBDIRS=test

BUILDDIR=build

all: TAKI.DSK

define SetupSubdirTargets
D = $(1)/
B = $$(BUILDDIR)/$$D

$$(D)% $$(B)%: D := $$(D)
$$(D)% $$(B)%: B := $$(B)

.SECONDARY: $$(B)
$$(B): B := $$(B)
$$(B):
	mkdir -p $$(B)

include $(1)/Makefile
endef
$(foreach dir,$(SUBDIRS),$(eval $(call SetupSubdirTargets,$(dir))))
D := __XXX__
B := __XXX__

build/Makefile:
	mkdir -p build
	#ln -sf ../src/Makefile build/Makefile
	echo >|$@ VPATH=../src
	echo >>$@ include ../src/Makefile

TAKI.DSK: build/TAKI.DSK
	cp build/TAKI.DSK .

build/TAKI.DSK: build/Makefile
	cd build && make VPATH=../src all

clean: build/Makefile
	rm -f TAKI.DSK
	rm -fr build

check: test/check
