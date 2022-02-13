; write a byte literal to a memory loc
.macro writeByte dst, src
	lda #src
        sta dst
.endMacro

; write a word literal to a memory loc
.macro writeWord dst, src
	writeByte dst, <src
	writeByte {dst+1}, >src
.endMacro

; copy a word from one location to another
.macro copyWord dst, src
	lda src
        sta dst
        lda src+1
        sta dst+1
.endMacro


.macro tstr str
	.repeat .strlen (str)-1, i
        	.byte .strat(str, i)
        .endrepeat
        .byte .strat(str, .strlen(str)-1)+128
.endmacro