.PHONY: all

all: TAKI.DSK
build/Makefile:
	mkdir -p build
	#ln -sf ../src/Makefile build/Makefile
	echo >|$@ VPATH=../src
	echo >>$@ include ../src/Makefile

TAKI.DSK: build/Makefile
	cd build && make VPATH=../src all
	mv build/TAKI.DSK .

clean: build/Makefile
	rm -f TAKI.DSK
	cd build && make VPATH=../src $@
	rm -f build/Makefile
	rmdir build
