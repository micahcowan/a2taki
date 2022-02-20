;; Scan Effect
;;
;; Highlights each letter of its source, in turn

.macpack apple2

.include "taki-effect.inc"
.include "a2-monitor.inc"

.import TakiVarNextPageBase ; XXX use draw API
.import _TakiIoDoubledOut ; XXX

kLocBase	= 0
kLocNumChars	= kLocBase + 2
kLocHilitePos= kLocNumChars + 1
kNeeded		= kLocHilitePos = 1

.export TE_Scan
TE_Scan:
	cmp #TAKI_DSP_INIT	; init?
        bne NoInit		; no: check more modes
        ; INIT: save BASL/H and reserve two bytes
        ldy #$0
        lda Mon_BASL
        sta (TAKI_ZP_EFF_STORAGE_L),y
        iny
        lda Mon_BASH
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
	; TODO: sanity-check character value
	; increment numChars by 1
	lda #$0
        sec ; so, 1
        ldy #kLocNumChars
	adc (TAKI_ZP_EFF_STORAGE_L),y
	sta (TAKI_ZP_EFF_STORAGE_L),y
        lda TAKI_ZP_ACC
        jmp _TakiIoDoubledOut
NoCollect:
	cmp #TAKI_DSP_TICK	; tick?
        bne NoTick		; no: check more modes
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
        lda TAKI_ZP_ACC
        jmp _TakiIoDoubledOut	; output as normal
        rts
NoTick:	cmp #TAKI_DSP_DRAW	; draw?
	bne NoModesFound	; no: exit
        ; XXX
        rts
NoModesFound:
	rts
