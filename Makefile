all: TAKI-CASSETTE TAKI-PRODOS.dsk

TAKI-PRODOS.dsk: TAKI-PRODOS PRODOS.dsk Makefile
	rm -f $@
	cp PRODOS.dsk $@
	prodos -t BIN -a 0x6000 $@ SAVE $< TAKI

TAKI-CASSETTE TAKI-PRODOS: *.s *.inc Makefile
	./build.sh

.PHONY: clean
clean:
	rm -f TAKI-PRODOS.dsk TAKI-CASSETTE TAKI-PRODOS *.o
