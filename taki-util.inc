.ifndef _TAKI_UTIL_INC_
_TAKI_UTIL_INC_ = 1

.include "taki-effect.inc"

;; Any module importing this include must also have:
; .import TakiEffectTablesStart, TakiEffectTablesEnd

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
.macro TakiEffectDispatchStart_
.scope
	; Save various things to stack
        pha		; Save registers
        tya
        pha
        txa
        pha
        ldy #$00	; Save ZP items
@Lp:    lda $00,y
        pha
        iny
        cpy #kZpEnd
        bne @Lp
        
        ; Copy various things to ZP
        ldy #$00
@LpZp:	lda TakiEffectTablesStart,y
        sta kZpEffTablesStart,y
        cpy 1 + kZpEffTablesEnd - kZpEffTablesStart
        bne @LpZp
.endscope
.endmacro

.macro TakiEffectInitializeDirect_ effAddr
.scope
	lda _TakiVarActiveEffectsNum
        asl	; times 2 to count words
        
        ;; Set values in tables:
        ; dispatch handler in table
        lda #<effAddr
        sta @DispatchCall+1
        sta (kZpEffDispatchTbl),y
        iny
        lda #>effAddr
        sta @DispatchCall+2
        sta (kZpEffDispatchTbl),y
        ; y is now 1 past
        
        ; end of allocation - initialize with
        ;  start of storage area if eff.num == 0,
        ; otherwise with whatever the end of
        ; allocation was for the previous effect
        ; (which is also the start of the new
        ; effect's allocation, since it hasn't
        ; allocated anything yet)
        cpy #1 ; y is one past, so 1 if we're at 0
        bne @PrevEffAlloc
        ; we're effect 0, use start of storage
        lda TakiVarEffectsAllocStartPage
        sta TAKI_ZP_EFF_STORAGE_END_H
        dey
        lda #$00
        sta TAKI_ZP_EFF_STORAGE_END_L
        dey ; y = 0 (cur eff low byte)
        beq @FinishAlloc ; always
@PrevEffAlloc:
	dey ; y -= 2, to get prev eff's end
        dey
        lda (kZpEffAllocTbl),y
        sta TAKI_ZP_EFF_STORAGE_L
        iny
        lda (kZpEffAllocTbl),y
        sta TAKI_ZP_EFF_STORAGE_H
        iny ; y at cur eff low byte
@FinishAlloc:
	; Now actually store to effect's alloc entry
	lda TAKI_ZP_EFF_STORAGE_L
        sta TAKI_ZP_EFF_STORAGE_END_L
        sta (kZpEffAllocTbl),y
        iny
        lda TAKI_ZP_EFF_STORAGE_H
        sta TAKI_ZP_EFF_STORAGE_END_H
        sta (kZpEffAllocTbl),y
        ; y is one past
        
        ; Initialize counter init and counter
        lda TakiVarDefaultCountdown+1
        sta (kZpEffCtrValTbl),y
        sta (kZpEffCtrInitTbl),y
        dey
        lda TakiVarDefaultCountdown
        sta (kZpEffCtrValTbl),y
        sta (kZpEffCtrInitTbl),y
        ; y is at eff
       	tya ; save y to stack
        sta kZpCurEffect ; and also  to ZP
        pha
        
        ; Increment number of effects
        inc _TakiVarActiveEffectsNum
        
        lda TAKI_DSP_INIT
        ; Call effect's dispatch handler
@DispatchCall:
	jsr $1000 ; address is overwritten
        pla
        tay ; restore y, is at eff
        
        ; Save any allocation change
        lda TAKI_ZP_EFF_STORAGE_END_L
        sta (kZpEffAllocTbl),y
        iny
        lda TAKI_ZP_EFF_STORAGE_END_H
        sta (kZpEffAllocTbl),y
.endscope
.endmacro

; restore zero page 
.macro TakiEffectDispatchEnd_
.scope
	; Restore various things to stack
        ldy #kZpEnd-1	; Restore ZP items
@Lp:    pla
        sta $00,y
        dey
        bpl @Lp
        pla		; Restore registers
        tax
        pla
        tay
        pla
.endscope
.endmacro

.endif ; _TAKI_UTIL_INC_
