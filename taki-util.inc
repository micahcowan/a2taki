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


.macro tstr str
	.repeat .strlen (str)-1, i
        	.byte .strat(str, i)
        .endrepeat
        .byte .strat(str, .strlen(str)-1)+128
.endmacro