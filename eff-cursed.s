;; Cursed Word effect
;;
;; Replaces the letters of the captured text with new random garbage
;; every frame.

.macpack apple2

.include "taki-effect.inc"
.include "taki-public.inc"
.include "a2-monitor.inc"

declVar varCH, 1               ; the horiz cursor position at capture start
declVar varCV, 1               ; the vert cursor position at capture start
declVar varBAS, 2              ; BASL/BASH at capture start

vTextStart = kVarSpaceNeeded

TAKI_EFFECT TE_Cursed, "CURSED", 0, 0
    cmp #TAKI_DSP_INIT  ; init?
    bne CkColl
    ;; INIT
    ; Allocate the space we will need
    effAllocate kVarSpaceNeeded

    ; save cursor X and Y
    lda Mon_CH
    effSetVar varCH
    lda Mon_CV
    effSetNext
    lda Mon_BASL
    effSetNext
    lda Mon_BASH
    effSetNext
    rts
CkColl:
    cmp #TAKI_DSP_COLLECT       ; collect?
    bne CkCollectEnd

    ;; COLLECT
    lda TAKI_ZP_ACC
    effAppendByte
    jmp TakiIoFastOut
CkCollectEnd:
    cmp #TAKI_DSP_ENDCOLLECT
    bne CkTick

    ;; END COLLECT
    lda #0
    effAppendByte
UnsupportedMode:
    rts
CkTick:
    cmp #TAKI_DSP_TICK  ; tick?
    bne UnsupportedMode

    ;; TICK
    ; Save away current CH, CV, and BAS
    lda Mon_CH
    sta SavedCH
    lda Mon_CV
    sta SavedCV
    lda Mon_BASL
    sta SavedBAS
    lda Mon_BASH
    sta SavedBAS+1
    ; Set to our capture-start spot
    effGetVar varCH
    sta Mon_CH
    effGetNext
    sta Mon_CV
    effGetNext
    sta Mon_BASL
    effGetNext
    sta Mon_BASH
PrintLoop:
    effGetNext
    beq TickCleanup
    pha
        and #$DF    ; de-lowercase
        ora #$80    ; ensure normal range
        cmp #$DB    ; >  'Z'?
        bcs @prLit  ; yes -> print literal char
        cmp #$C1    ; >= 'A'?
        bcc @prLit  ; no ->  print literal char
    pla
    ; Print garbage!
    jsr RandomChar
    jsr TakiIoFastOut
    jmp PrintLoop
@prLit:
    pla
    jsr TakiIoFastOut
    jmp PrintLoop
TickCleanup:
    lda SavedCH
    sta Mon_CH
    lda SavedCV
    sta Mon_CV
    lda SavedBAS
    sta Mon_BASL
    lda SavedBAS+1
    sta Mon_BASH
    rts
SavedCH:
.byte 0
SavedCV:
.byte 0
SavedBAS:
.word 0

; Weights a bit higher toward punctuation and digits
RandomChar:
    jsr TakiIoNextRandom
    lda TakiVarRandomWord
    ora #$80
    cmp #$A1        ; is it a control character, or space?
    bcs @notCtrl    ; no -> don't adjust
    adc #$21        ; (carry never set)
@notCtrl:
    cmp #$FF        ; DEL character?
    bne @notDEL
    lda #$A1        ; replace with '!'
@notDEL:
    rts
