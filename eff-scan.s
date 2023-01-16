;; Scan Effect
;;
;; Highlights each letter of its source, in turn

.macpack apple2

.include "taki-effect.inc"
.include "taki-public.inc"
.include "a2-monitor.inc"

.import _TakiIoDoubledOut ; XXX

config: .byte 1
types:  .byte TAKI_CFGTY_WORD
words:
	scrcode "PAUSE"
        .byte $00

kLocPause	= 0
kLocBase	= kLocPause + 2
kLocNumChars	= kLocBase + 2
kLocHilitePos	= kLocNumChars + 1
kNeeded		= kLocHilitePos + 1

TAKI_EFFECT TE_Scan, "SCAN", 0, config
	cmp #TAKI_DSP_INIT	; init?
        bne CkColl
        ; INIT: save BASL/H and reserve two bytes
        ldy #kLocPause
        lda #0
        sta (TAKI_ZP_EFF_STORAGE_L),y
        iny
        lda #0
        sta (TAKI_ZP_EFF_STORAGE_L),y
        iny
        clc
        lda Mon_BASL
        adc Mon_CH ; add current horiz. pos.
        sta (TAKI_ZP_EFF_STORAGE_L),y
        iny
        lda Mon_BASH
        adc #$0 ; for carry bit
        sta (TAKI_ZP_EFF_STORAGE_L),y
        iny
        lda #$0
        sta (TAKI_ZP_EFF_STORAGE_L),y
        iny
        sta (TAKI_ZP_EFF_STORAGE_L),y
        clc
        ; mark the storage used
        lda TAKI_ZP_EFF_STORAGE_END_L
        adc #kNeeded
        sta TAKI_ZP_EFF_STORAGE_END_L
        bcc @NoHigh
        inc TAKI_ZP_EFF_STORAGE_END_H
@NoHigh:
	rts
CkColl: cmp #TAKI_DSP_COLLECT	; collect?
	bne CkTick
	; COLLECT
        ; TODO: sanity-check character value
	; increment numChars by 1
	lda #$0
        sec ; so, 1
        ldy #kLocNumChars
	adc (TAKI_ZP_EFF_STORAGE_L),y
	sta (TAKI_ZP_EFF_STORAGE_L),y
        lda TAKI_ZP_ACC
        jmp TakiIoScreenOut ; XXX
CkTick:
	cmp #TAKI_DSP_TICK	; tick?
        bne NoModesFound
	; TICK
        lda #$0
        sec ; so, 1
        ldy #kLocHilitePos
	adc (TAKI_ZP_EFF_STORAGE_L),y
        dey ; kLocNumChars
        cmp (TAKI_ZP_EFF_STORAGE_L),y
        bne @NotEq ; y != numChars? skip to @notEq
@Eq:
        ; if we get here, we're "at" numChars.
        ; This state means highlight nothing.
        pha
        tya
        pha
        ; copy Pause to counter {
        effGetVar kLocPause+1
        pha ; high
        dey
        lda (TAKI_ZP_EFF_STORAGE_L),y
        tay; low
        pla; high
        jsr TakiMySetCounter
        ; } copy Pause
        pla
        tay
        pla
        bne @Stor ; always
@NotEq: bcc @InWord
        lda #0 ; reset hilitePos if past numChars
@InWord:
@Stor:
        iny
	sta (TAKI_ZP_EFF_STORAGE_L),y
        ; DRAW!
        ; Adjust "Base" by which page is coming
        ldy #kLocBase+1
        lda (TAKI_ZP_EFF_STORAGE_L),y
        ;and #$03 ; remove page info
        ;ora TakiVarNextPageBase ; add it back in
        sta TAKI_ZP_EFF_SPECIAL_1
        dey ; Now copy the low byte of "Base"
        lda (TAKI_ZP_EFF_STORAGE_L),y
        sta TAKI_ZP_EFF_SPECIAL_0
        ; DRAW: loop over the characters, setting
        ; to "plain"
        ; XXX: should really just be able to update
        ; the last couple positions instead, but
        ; anyhoo
        ldy #kLocNumChars
        lda (TAKI_ZP_EFF_STORAGE_L),y
        tay
@Loop:  dey ; start with rightmost char first
        cpy #$ff
        beq @Done
        lda (TAKI_ZP_EFF_SPECIAL_0),y
        ora #$80
        ; XXX might need to adjust punctuation row
        sta (TAKI_ZP_EFF_SPECIAL_0),y
        jmp @Loop
@Done:  ; Now set inverse on the char we're interested in
	ldy #kLocNumChars
        lda (TAKI_ZP_EFF_STORAGE_L),y
        sta TAKI_ZP_EFF_SPECIAL_2
	ldy #kLocHilitePos
        lda (TAKI_ZP_EFF_STORAGE_L),y
        cmp TAKI_ZP_EFF_SPECIAL_2
        beq @rts ; hilitePos == numChars, hilite nothing
        tay
        lda (TAKI_ZP_EFF_SPECIAL_0),y
        and #$3f
        sta (TAKI_ZP_EFF_SPECIAL_0),y
@rts:
        rts
NoModesFound:
	rts
