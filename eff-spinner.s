;; Spinner Effect
;;
;; Animates a little spinner in a corner of the screen

.macpack apple2

.include "taki-effect.inc"
.include "taki-public.inc"
.include "a2-monitor.inc"

pvTickChars:
	scrcode "!/-\" ; "
pvTickCharsEnd:

TAKI_EFFECT TE_Spinner, "SPINR", 0, 0
	cmp #TAKI_DSP_INIT	; check if "init" mode,
        bne @checkTick		; no: check other modes
        ; reserve one byte of storage
        inc TAKI_ZP_EFF_STORAGE_END_L
        bne @skipHi
        inc TAKI_ZP_EFF_STORAGE_END_H
@skipHi:rts
@checkTick:
	cmp #TAKI_DSP_TICK	; check if tick
        bne @checkDraw		; no: check other modes
        ldy #0			; yes: DRAW
        lda (TAKI_ZP_EFF_STORAGE_L),y ; load iterator
        clc
        adc #1			; and advance
	cmp #(pvTickCharsEnd - pvTickChars)
        bne @Store
        lda #0
@Store:	sta (TAKI_ZP_EFF_STORAGE_L),y
	rts
@checkDraw:
	cmp #TAKI_DSP_DRAW	; check if draw
        bne @noModesHandled
        TF_ST_BRANCH_UNLESS_FLG TF_ST_IN_INPUT, @noModesHandled
        ; DRAW!
        lda Mon_BASL
        sta @DrawSta+1
        lda Mon_BASH
        and #$03
        ora TakiVarNextPageBase ; XXX
        sta @DrawSta+2	; modify upcoming sta dest
        ldy #0
        lda (TAKI_ZP_EFF_STORAGE_L),y
        tay
        lda pvTickChars,y
        ldy Mon_CH
@DrawSta:
        sta $7F0,y
@noModesHandled:
	rts
