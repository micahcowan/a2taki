;; Sine Animation effect
;;
;; Uses a primitive stack-based language
;; to describe animated positions using the
;; trigonometric sine function

.macpack apple2

.include "taki-effect.inc"
.include "taki-public.inc"
.include "a2-monitor.inc"
.include "math-ca65.inc"

.import SineCalcRun, SineCalcTimersAdvance

declVar varMode, 1
declVar varCH, 1
declVar varCV, 1
declVar varPrevBAS, 2
declVar varTimersAddr, 2    ; same as start of storage + kVarSpaceNeeded,
                            ;  but anyway
declVar varHAnimAddr, 2
declVar varVAnimAddr, 2
declVar varTextAddr, 2

; When we're processing animation code (during
; collection), regardless of whether it's going
; to be horizontal or vertical coordinate animation,
; we use varVAnimAddr to point at the start of
; the processed code
varAnimStartAddr = varVAnimAddr

kModeText       = 0
kModeTimers     = 1
kModeHAnim      = 2
kModeVAnim      = 3
kModeSkip       = 4
kModeTextAlt    = 5 ; alternative text mode value

TAKI_EFFECT TE_SineAnim, "SANIM", 0, 0
    cmp #TAKI_DSP_INIT      ; init?
    bne CkColl
    ;; INIT
    ; Allocate the space we will need
    effAllocate kVarSpaceNeeded
    ;
    lda #kModeTimers
    effSetVar varMode
    ; save cursor X and Y
    lda Mon_CH
    pha
    effSetNext
    lda Mon_CV
    effSetNext
    ; save BASL + CH
    pla
    clc
    adc Mon_BASL
    effSetNext
    lda Mon_BASH
    adc #0 ; (for carry, though shouldn't be necessary)
    effSetNext
    ; Point timers at the end of current storage
    lda TAKI_ZP_EFF_STORAGE_END_L
    effSetNext
    lda TAKI_ZP_EFF_STORAGE_END_H
    effSetNext
    ; initialize the basic timer:
    ; 1 timer: 1,1,0,0
    lda #1
    effAppendByte
    lda #4
    effAppendByte
    lda #1
    effAppendByte
    lda #0
    effAppendByte
    effAppendByte
    rts
CkColl:
    cmp #TAKI_DSP_COLLECT   ; collect?
    beq :+
    jmp CkCollectEnd
:
    ;; COLLECT
    effGetVar varMode
    bne :+
    jmp CollectText
:
    tax
    dex
    beq CollectTimers
    dex
    beq CollectHAnim
    dex
    beq CollectVAnim
    dex
    beq CollectSkipToCr
    dex
    bne @rts
    ; Alternative text mode: set it to 0
    ; for (slightly) faster processing
    ; next time!
    lda #0
    sta (TAKI_ZP_EFF_STORAGE_L),y ; Y set from effGetVar: "mode"
    beq CollectText
    ; Mode not recognized!
@rts:
    rts
CollectTimers:
CollectSkipToCr:
    lda TAKI_ZP_ACC
    cmp #$8D ; carriage return?
    bne @rts ; nope, check next one
    ; bump mode to the next one
    effGetVar varMode
    clc
    adc #1
    sta (TAKI_ZP_EFF_STORAGE_L),y ; Y set from effGetVar: "mode"
    cmp #kModeHAnim
    bne @rts
    ; If we're entering animation processing,
    ; set up anim code-start pointer, and decimal
    ; state byte
    lda TAKI_ZP_EFF_STORAGE_END_L
    effSetVar varAnimStartAddr
    lda TAKI_ZP_EFF_STORAGE_END_H
    effSetNext
    ; set up decimal processing state
    ; (0 = nothing in progress), and a byte for
    ; a work-in-progress number being processed.
    ; We don't adjust the storage-space end for it,
    ; nothing will overwrite it while we're
    ; collecting, and we don't use
    ; it once collecting is over.
    ldy #0
    lda #0
    sta (TAKI_ZP_EFF_STORAGE_END_L),y
    iny
    sta (TAKI_ZP_EFF_STORAGE_END_L),y
@rts:
    rts
CollectHAnim:
CollectVAnim:
    jsr ProcessProgramChar
    beq @handleR ; char == 'R'? -> handle it
    rts
@handleR:
    effGetVar varMode
    cmp #kModeVAnim
    beq @vDone
@hDone:
    ; We're exiting horizontal animation code.
    ; Copy the start addr for hAnim
    effGetVar varAnimStartAddr+1
    effSetVar varHAnimAddr+1
    effGetVar varAnimStartAddr
    effSetVar varHAnimAddr
    ; And set the start addr for vAnim to current
    ; end of storage
    lda TAKI_ZP_EFF_STORAGE_END_L
    effSetVar varAnimStartAddr
    lda TAKI_ZP_EFF_STORAGE_END_H
    effSetNext
    jmp @nextMode
@vDone:
    ; We're exiting vertical animation code.
    ; Copy current end of storage as start of text
    lda TAKI_ZP_EFF_STORAGE_END_L
    effSetVar varTextAddr
    lda TAKI_ZP_EFF_STORAGE_END_H
    effSetNext
@nextMode:
    ; bump mode to the next mode
    effGetVar varMode
    clc
    adc #1
    sta (TAKI_ZP_EFF_STORAGE_L),y ; Y set from effGetVar: "mode"
@rts:
    rts
CollectText:
    lda TAKI_ZP_ACC
    effAppendByte
    jmp TakiIoFastOut
CkCollectEnd:
    cmp #TAKI_DSP_ENDCOLLECT
    bne CkTick
    lda #0 ; zero-terminate the message string
    effAppendByte
    rts
CkTick:
    cmp #TAKI_DSP_TICK      ; tick?
    beq :+
    rts ; No modes found: exit
    :
    ;; DRAW TICK
    ; Set up calculation structure for horiz SineCalc
    effGetVar varTimersAddr
    sta SineCalcStruct+2
    effGetNext
    sta SineCalcStruct+3
    effGetNext
    sta SineCalcStruct
    effGetNext
    sta SineCalcStruct+1
    ; Tick timers
    lda SineCalcStruct+2
    ldy SineCalcStruct+3
    jsr SineCalcTimersAdvance
    ; Save BAS, CH, CV
    lda Mon_CH
    sta SavedCH
    lda Mon_CV
    sta SavedCV
    lda Mon_BASL
    sta SavedBAS
    lda Mon_BASH
    sta SavedBAS+1
    ; Calculate new CH
    lda #<SineCalcStruct
    ldy #>SineCalcStruct
    jsr SineCalcRun
    sta Mon_CH
    ; add our original CH
    effGetVar varCH
    clc
    adc Mon_CH
    sta Mon_CH
    ; Calculate new CV
    effGetVar varVAnimAddr
    sta SineCalcStruct
    effGetNext
    sta SineCalcStruct+1
    lda #<SineCalcStruct
    ldy #>SineCalcStruct
    jsr SineCalcRun
    sta Mon_CV
    ; add our original CV
    effGetVar varCV
    clc
    adc Mon_CV
    sta Mon_CV
    ; Calculate BAS
    jsr Mon_BASCALC
    ; adjust for CH (so we can detect change)
    lda Mon_BASL
    clc
    adc Mon_CH
    sta Mon_BASL ; carry should never happen
    lda #0
    sta Mon_CH
    ; Save new BAS
    lda Mon_BASL
    sta NewBAS
    lda Mon_BASH
    sta NewBAS+1
    ; Restore old, for erase
    effGetVar varPrevBAS
    sta Mon_BASL
    effGetNext
    sta Mon_BASH
    ; Set up text message ptr for fast-print
    effGetVar varTextAddr
    sta TAKI_ZP_EFF_SPECIAL_0
    effGetNext
    sta TAKI_ZP_EFF_SPECIAL_1
    ; Has BAS changed from prev calculation?
    effGetVar varPrevBAS
    cmp NewBAS
    bne @different
    effGetNext
    cmp NewBAS+1
    bne @different
@same:
    ; Reprint our message instead of erasing it,
    ; so the timing stays roughly the same without
    ; disrupting video
    jsr TakiIoFastPrintStr
    jmp @print
@different:
    jsr TakiIoFastPrintSpace
@print:
    ; Set up "new" BAS for printing,
    ; and save as "prev" BAS for next tick
    lda NewBAS
    sta Mon_BASL
    effSetVar varPrevBAS
    lda NewBAS+1
    sta Mon_BASH
    effSetNext
    ; Print the text
    jsr TakiIoFastPrintStr
@finish:
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
NewBAS:
    .word 0
SineCalcStruct:
    .word 0
    .word 0

ProcessProgramChar:
    ; Get processing mode and number-in-progress
    ldy #1
    lda (TAKI_ZP_EFF_STORAGE_END_L),y
    sta vNumInProgress
    dey
    lda (TAKI_ZP_EFF_STORAGE_END_L),y
    sta vProcessMode
    
    ; Is a number in progress?
    bne :+
    jmp @normalMode ; no -> process normally
:
    ; yes. Did we get another digit?
    lda TAKI_ZP_ACC
    jsr IsDigit
    bcs @handleDigit
    ; not a digit: finish handling number-in-progress,
    ; and then handle the new thing we got.
    
    ; First, set the processing mode to indicate
    ; we're done doing a number
    lda #0
    sta vProcessMode
    lda vNumInProgress
    bmi @bigNum ; large number? (high bit set)
                ; yes: go handle specially
    ; If the number is positive (high bit clear)
    ; then just safe the byte out directly
    effAppendByte
    jmp @normalModeNotDig ; now go handle the char
@bigNum:
    ; The number is too large to fit in a 7-bit byte,]
    ; and all 8-bit values are reserved for commands.
    ; Write it out as a sequence of additions.
    sec
    sbc #$7F
    pha
        lda #$7F
        effAppendByte
    ; In the specific case where our num-in-progress
    ; was #$FF, it takes 2 additions; otherwise just one.
    pla
    cmp #$80
    bne @finishBigNum
    ; If we're here, num-in-progress was #$FF (255).
    lda #$7F
    effAppendByte
    lda #'+' | $80
    effAppendByte
    lda #$01
    effAppendByte
    lda #'+' | $80
    effAppendByte
    jmp @normalModeNotDig ; now go handle the new char
@finishBigNum:
    effAppendByte
    lda #'+' | $80
    effAppendByte
    jmp @normalModeNotDig ; now go handle the new char
@handleDigit:
    ; We got a digit, multiply number-in-progress
    ;  by 10 and add the new one
    ; bring new digit into 0-10 range
    eor #$B0
    sta TAKI_ZP_ACC
    lda #0 ; high byte of a word
    ldy vNumInProgress
    jsr mul10w_AY
    tya
    clc
    adc TAKI_ZP_ACC
    sta vNumInProgress
    jmp @finish
@normalMode:
    lda TAKI_ZP_ACC
    jsr IsDigit
    bcc @normalModeNotDig
    ; Got a digit: set up number processing
    ; and store the first 
    eor #$B0
    sta vNumInProgress
    lda #$80
    sta vProcessMode
    bne @finish ; always
@normalModeNotDig:
    ; Is it a space, colon, CR or comma?
    ; Then skip it.
    lda TAKI_ZP_ACC
    cmp #$A0 ; space
    beq @finish
    cmp #$8D ; CR
    beq @finish
    cmp #':' | $80
    beq @finish
    cmp #',' | $80
    beq @finish
    ; Otherwise, append the command char
    effAppendByte
@finish:
    ; re-save any number-processing state.
    ldy #0
    lda vProcessMode
    sta (TAKI_ZP_EFF_STORAGE_END_L),y
    iny
    lda vNumInProgress
    sta (TAKI_ZP_EFF_STORAGE_END_L),y
    ; did the program end? set Z flag if so
    ; (and clear, otherwise)
    lda TAKI_ZP_ACC
    cmp #('R' | $80)
    rts
vProcessMode:
    .byte 0
vNumInProgress:
    .byte 0

IsDigit:
    cmp #$BA ; Is it > '9'?
    bcs @fail; Yes, so not a digit
    cmp #$B0 ; Is it >= '0'?
    rts      ; yes = is digit, no = not a digit
@fail:
    clc
    rts
