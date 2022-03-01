;; Scan Effect
;;
;; Highlights each letter of its source, in turn

.macpack apple2

.include "taki-effect.inc"
.include "taki-public.inc"
.include "a2-monitor.inc"

TakiBuiltinEffect_ TE_Scan

.import _TakiIoDoubledOut ; XXX

kLocBase	= 0
kLocNumChars	= kLocBase + 2
kLocHilitePos	= kLocNumChars + 1
kNeeded		= kLocHilitePos + 1

pTag:
	scrcode "SCAN"
pTagEnd:
	.byte pTagEnd - pTag 
	.word $0000 ; flags
TE_Scan:
	cmp #TAKI_DSP_INIT	; init?
        bne NoInit		; no: check more modes
        ; INIT: save BASL/H and reserve two bytes
        ldy #$0
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
NoInit: cmp #TAKI_DSP_COLLECT	; collect?
	bne NoCollect		; no: check more modes
	; COLLECT
        ; TODO: sanity-check character value
	; increment numChars by 1
	lda #$0
        sec ; so, 1
        ldy #kLocNumChars
	adc (TAKI_ZP_EFF_STORAGE_L),y
	sta (TAKI_ZP_EFF_STORAGE_L),y
        lda TAKI_ZP_ACC
        jmp _TakiIoDoubledOut ; XXX
NoCollect:
	cmp #TAKI_DSP_TICK	; tick?
        bne NoTick		; no: check more modes
	; TICK
        lda #$0
        sec ; so, 1
        ldy #kLocHilitePos
	adc (TAKI_ZP_EFF_STORAGE_L),y
        dey ; kLocNumChars
        cmp (TAKI_ZP_EFF_STORAGE_L),y
        bne @NoReset
        lda #0 ; reset hilitePos if past numChars
@NoReset:
        iny
	sta (TAKI_ZP_EFF_STORAGE_L),y
        rts
NoTick:	cmp #TAKI_DSP_DRAW	; draw?
	bne NoModesFound	; no: exit
        ; DRAW!
        ; Adjust "Base" by which page is coming
        ldy #kLocBase+1
        lda (TAKI_ZP_EFF_STORAGE_L),y
        and #$03 ; remove page info
        ora TakiVarNextPageBase ; add it back in
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
	ldy #kLocHilitePos
        lda (TAKI_ZP_EFF_STORAGE_L),y
        tay
        lda (TAKI_ZP_EFF_SPECIAL_0),y
        and #$3f
        sta (TAKI_ZP_EFF_SPECIAL_0),y
        rts
NoModesFound:
	rts
