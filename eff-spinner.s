;; Spinner Effect
;;
;; Animates a little spinner in a corner of the screen

.macpack apple2

.include "taki-effect.inc"
.include "a2-monitor.inc"

.import TakiVarNextPageBase ; XXX

pvTickIter:
	.byte $00
pvTickChars:
	scrcode "!/-\"
pvTickCharsEnd:

.export TE_Spinner
TE_Spinner:
	cmp #TAKI_DSP_INIT	; check if "init" mode,
        bne @notInit		; no: check other modes
        ; reserve one byte of storage
        inc TAKI_ZP_EFF_STORAGE_END_L
        bne @skipHi
        inc TAKI_ZP_EFF_STORAGE_END_H
@skipHi:rts
@notInit:
	cmp #TAKI_DSP_TICK	; check if tick
        bne @notTick		; no: check other modes
        ldy pvTickIter		; yes: DRAW
        iny
        cpy #(pvTickCharsEnd - pvTickChars)
        bne @StY
        ldy #0
@StY:	sty pvTickIter
	rts
@notTick:
	cmp #TAKI_DSP_DRAW	; check if draw
        bne @noModesHandled
        ; DRAW!
        lda Mon_BASL
        sta @DrawSta+1
        lda Mon_BASH
        and #$03
        ora TakiVarNextPageBase
        sta @DrawSta+2	; modify upcoming sta dest
        ldy pvTickIter
        lda pvTickChars,y
        ldy Mon_CH
@DrawSta:
        sta $7F0,y
@noModesHandled:
	rts
