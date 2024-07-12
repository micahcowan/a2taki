;; Fluorescent Light effect
;;
;; Stutters the captured text on and off,
;; like an annoying fluorescent light

.macpack apple2

.include "taki-effect.inc"
.include "taki-public.inc"
.include "a2-monitor.inc"

kLocSelect = 0                  ; which countdown we're on
kLocCount  = kLocSelect + 1     ; the countdown
kLocCH     = kLocCount + 1      ; the horiz cursor position at capture start
kLocCV     = kLocCH    + 1      ; the vert cursor position at capture start
kLocBAS    = kLocCV + 1         ; BASL/BASH at capture start
kLocVisible= kLocBAS + 2        ; 0 = hidden, non-0 = visible
kNeeded    = kLocVisible + 1

kLocTextStart = kNeeded

TAKI_EFFECT TE_Fluorescent, "FLUORESCENT", 0, 0
	cmp #TAKI_DSP_INIT	; init?
        bne CkColl
        ;; INIT
        ; Allocate the space we will need
        effAllocate kNeeded

        lda #0
        effSetVar kLocSelect
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
CkColl: cmp #TAKI_DSP_COLLECT	; collect?
        bne CkCollectEnd

        ;; COLLECT
        lda TAKI_ZP_ACC
        effAppendByte
        jmp TakiIoScreenOut
CkCollectEnd:
	cmp #TAKI_DSP_ENDCOLLECT
        bne CkTick

        ;; END COLLECT
        lda #0
        effAppendByte
UnsupportedMode:
        rts
CkTick:
	cmp #TAKI_DSP_TICK	; tick?
        bne UnsupportedMode

        ;; TICK
        effGetVar kLocCount
        sec
        sbc #1                  ; countdown over?
        sta (TAKI_ZP_EFF_STORAGE_L), y ;effSetVar kLocCount
        bne StillCounting       ; no: just print for current state
CountdownDone:
        effGetVar kLocSelect
        clc
        adc #1                  ; increment to next timer
        cmp #blinkTimingsSize
        bne :+
        ; out of timers, start at first again
        lda #0
:
        effSetVar kLocSelect
        tay
        lda blinkTimings,y
        effSetVar kLocCount

        ; now toggle visibility
        effGetVar kLocVisible
        eor #$FF
        effSetVar kLocVisible
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
        effGetVar kLocCH
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
        adc #kLocTextStart
        sta TAKI_ZP_EFF_SPECIAL_0
        lda TAKI_ZP_EFF_STORAGE_H
        adc #0
        sta TAKI_ZP_EFF_SPECIAL_1
        effGetVar kLocTextStart
        beq TickCleanup
        effGetVar kLocVisible
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
