.ifndef _TAKI_UTIL_INC_
_TAKI_UTIL_INC_ = 1

.include "taki-effect.inc"

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

.macro subtractAndSave16_8 wloc, bloc
    sec
    lda wloc
    sbc bloc
    sta wloc
    lda wloc+1
    sbc #$0
    sta wloc+1
.endmacro

; needs .macpack apple2 before use
.macro tstr str
    scrcode str
    .byte 0
.endmacro

.if 0
.macro tstr str
    .repeat .strlen (str)-1, i
        .byte .strat(str, i)&$7F
    .endrepeat
    .byte .strat(str, .strlen(str)-1)|$80
.endmacro
.endif


.endif ; _TAKI_UTIL_INC_
