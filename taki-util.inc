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


.macro tstr str
	.repeat .strlen (str)-1, i
        	.byte .strat(str, i)
        .endrepeat
        .byte .strat(str, .strlen(str)-1)+128
.endmacro

;;;; Less general, more Taki-specific facilities

kZpCurEffStorageL	= TAKI_ZP_EFF_STORAGE_L	; $6
kZpCurEffStorageH	= TAKI_ZP_EFF_STORAGE_H	; $7
kZpCurEffStorageEndL	= TAKI_ZP_EFF_STORAGE_END_L ; $8
kZpCurEffStorageEndH	= TAKI_ZP_EFF_STORAGE_END_H ; $9
kZpCmdbufL		= TAKI_ZP_CMDBUF_L ; $0A
kZpCmdbufH		= TAKI_ZP_CMDBUF_H ; $0B
kZpDispatchMode		= TAKI_ZP_DSP_MODE ; $0C
kZpCurEffect		= $0D
kZpEffTablesStart	= $0E
kZpEffAllocTbl		= kZpEffTablesStart
kZpEffCtrValTbl		= kZpEffTablesStart + 2
kZpEffCtrInitTbl	= kZpEffTablesStart + 4
kZpEffDispatchTbl	= kZpEffTablesStart + 6

kZpEffTablesEnd		= kZpEffTablesStart + 8
kZpEnd			= kZpEffTablesEnd


; make space in zero page for effect stuff
;   NOTE: users of this macro must import the relevant
;   symbols
.macro TakiEffectDo_ fn
	pha
        
	lda #<fn
        sta _TakiEffectSetupFn
        lda #>fn
        sta _TakiEffectSetupFn+1
        jsr _TakiEffectSetupAndDo
        
        pla
.endmacro

.endif ; _TAKI_UTIL_INC_
