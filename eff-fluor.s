;; Fluorescent Light effect
;;
;; Stutters the captured text on and off,
;; like an annoying fluorescent light

.macpack apple2

.include "taki-effect.inc"
.include "taki-public.inc"
.include "a2-monitor.inc"

declVar varSelect, 1          ; which countdown we're on
declVar varCount, 1           ; the countdown
declVar varCH, 1              ; the horiz cursor position at capture start
declVar varCV, 1              ; the vert cursor position at capture start
declVar varBAS, 2             ; BASL/BASH at capture start
declVar varVisible, 1         ; 0 = hidden, non-0 = visible

varTextStart = kVarSpaceNeeded

TAKI_EFFECT TE_Fluorescent, "FLUORESCENT", 0, 0
    cmp #TAKI_DSP_INIT      ; init?
    bne CkColl
    ;; INIT
    ; Allocate the space we will need
    effAllocate kVarSpaceNeeded

    lda #0
    effSetVar varSelect
    lda blinkTimings
    effSetNext
    ; save cursor X and Y
    lda Mon_CH
    effSetNext
    lda Mon_CV
    effSetNext
    lda Mon_BASL
    effSetNext
    lda Mon_BASH
    effSetNext
    lda #$FF
    effSetNext
    rts
CkColl:
    cmp #TAKI_DSP_COLLECT   ; collect?
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
    cmp #TAKI_DSP_TICK      ; tick?
    bne UnsupportedMode

    ;; TICK
    effGetVar varCount
    sec
    sbc #1                  ; countdown over?
    sta (TAKI_ZP_EFF_STORAGE_L), y ;effSetVar varCount
    bne StillCounting       ; no: just print for current state
CountdownDone:
    effGetVar varSelect
    clc
    adc #1                  ; increment to next timer
    cmp #blinkTimingsSize
    bne :+
    ; out of timers, start at first again
    lda #0
:
    effSetVar varSelect
    tay
    lda blinkTimings,y
    .if 0
    ; No, use random instead!
    jsr TakiIoNextRandom
    lda TakiVarRandomWord
    and #$03
    sec
    adc #0
    .endif
    effSetVar varCount

    ; now toggle visibility
    effGetVar varVisible
    eor #$FF
    effSetVar varVisible
StillCounting:
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
    ; Is the text visible?
    ; print it
    lda TAKI_ZP_EFF_STORAGE_L
    clc
    adc #varTextStart
    sta TAKI_ZP_EFF_SPECIAL_0
    lda TAKI_ZP_EFF_STORAGE_H
    adc #0
    sta TAKI_ZP_EFF_SPECIAL_1
    effGetVar varTextStart
    beq TickCleanup
    effGetVar varVisible
    beq PrintInvis
PrintVis:
    jsr TakiIoFastPrintStr
    jmp TickCleanup
PrintInvis:
    jsr TakiIoFastPrintSpace
    ; fall through
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

blinkTimings:
    .byte 4,5,1,3,1,1,5,1,5
blinkTimingsEnd:
blinkTimingsSize = blinkTimingsEnd - blinkTimings
