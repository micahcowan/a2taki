BUILDDIR=build

.PHONY: all
all: TAKI.DSK

TAKI.DSK: build/TAKI.DSK src/all
	cp build/TAKI.DSK .

clean:
	rm -f TAKI.DSK
	rm -fr build

check: src/check

# ---- Include src/Makefile ----

D := src/
B := $(BUILDDIR)/

$(D)% $(B)%: D := $(D)
$(D)% $(B)%: B := $(B)

.SECONDARY: $(B)
$(B): B := $(B)
$(B):
	mkdir $(B)

include $(D)Makefile

D := __XXX__
B := __XXX__
