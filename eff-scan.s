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

declVar varPause, 2
declVar varBase, 2
declVar varNumChars, 1
declVar varHilitePos, 1

TAKI_EFFECT TE_Scan, "SCAN", 0, config
    cmp #TAKI_DSP_INIT      ; init?
    bne CkColl

    effAllocate kVarSpaceNeeded

    ; INIT: save BASL/H and reserve two bytes
    lda #0
    effSetVar varPause
    lda #0
    effSetNext
    iny
    clc
    lda Mon_BASL
    adc Mon_CH ; add current horiz. pos.
    effSetVar varBase
    lda Mon_BASH
    adc #$0 ; for carry bit
    effSetNext
    lda #$0
    effSetVar varNumChars
    effSetVar varHilitePos
    rts
CkColl:
    cmp #TAKI_DSP_COLLECT   ; collect?
    bne CkTick
    ; COLLECT
    ; TODO: sanity-check character value
    ; increment numChars by 1
    lda #$0
    sec ; so, 1
    effOpVar adc, varNumChars
    effSetCur
    lda TAKI_ZP_ACC
    jmp TakiIoFastOut
CkTick:
    cmp #TAKI_DSP_TICK      ; tick?
    bne NoModesFound
    ; TICK
    lda #$0
    sec ; so, 1
    effOpVar adc, varHilitePos
    effOpVar cmp, varNumChars
    bne @NotEq ; y != numChars? skip to @notEq
@Eq:
    ; if we get here, we're "at" numChars.
    ; This state means highlight nothing.
    pha
    tya
    pha
    ; copy Pause to counter {
    effGetVar varPause+1
    pha ; high
    effGetVar varPause
    tay; low
    pla; high
    jsr TakiMySetCounter
    ; } copy Pause
    pla
    tay
    pla
    bne @Stor ; always
@NotEq:
    bcc @InWord
    lda #0 ; reset hilitePos if past numChars
@InWord:
@Stor:
    effSetVar varHilitePos
    ; DRAW!
    effGetVar varBase
    sta TAKI_ZP_EFF_SPECIAL_0
    effGetNext
    sta TAKI_ZP_EFF_SPECIAL_1

    ; DRAW: loop over the characters, setting
    ; to "plain"
    ; XXX: should really just be able to update
    ; the last couple positions instead, but
    ; anyhoo
    effGetVar varNumChars
    tay
@Loop:
    dey ; start with rightmost char first
    cpy #$ff
    beq @Done
    lda (TAKI_ZP_EFF_SPECIAL_0),y
    ora #$80
    ; XXX might need to adjust punctuation row
    sta (TAKI_ZP_EFF_SPECIAL_0),y
    jmp @Loop
@Done:  ; Now set inverse on the char we're interested in
    effGetVar varNumChars
    sta TAKI_ZP_EFF_SPECIAL_2
    effGetVar varHilitePos
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
