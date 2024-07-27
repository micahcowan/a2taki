.import Sine
.export SineCalcRun, SineCalcTimersAdvance

InstrPtr = $0
TimersPtr= $2

;; NOT RE-ENTRANT
SineCalcRun:
    sta SavedA
    stx SavedX
    sty SavedY
    jsr SaveAndInstallZp
    ;
    ldy #0
    sty StackCtr
    jmp FirstIter
NextInstr:
    inc InstrPtr
    bne FirstIter
    inc InstrPtr+1
FirstIter:
    ; Get an instruction
    ldy #0
    lda (InstrPtr),y
    cmp #$80 ; is it an isntruction?
    bcs IsInstr ; yes -> handle
    ; Not an instruction: push to internal stack
    jsr PushVal
    jmp NextInstr
IsInstr:
    ; If we get here, it's an instruction.
    and #$7F ; just get at ASCII val of instr
    cmp #'T'
    bne :+
    jmp TimerPop
:   cmp #'+'
    bne :+
    jmp HandleAdd
:   cmp #'-'
    bne :+
    jmp HandleSub
:   cmp #'S'
    bne :+
    jmp HandleSine
:   ; 'R' or unrecognized cmd: fall thru
SineCalcOut:
    ;
    jsr RestoreZp
    ldx SavedX
    jsr PopVal
    rts
SavedA:
    .byte 0
SavedX:
    .byte 0
SavedY:
    .byte 0
StackCtr:
    .byte 0
    
SaveAndInstallZp:
    jsr SaveZp
    ; First, copy A, Y addr into ZP
    lda SavedA
    sta $0
    ldy SavedY
    sty $1
    ; Copy timers addr into ZP
    ldy #TimersPtr
    lda ($0),y
    sta $2
    iny
    lda ($0),y
    sta $3
    ; Now copy commands addr, overwriting $0
    ldy #InstrPtr
    lda ($0),y
    tax
    iny
    lda ($0),y
    stx $0
    sta $1
    rts

SaveZp:
    ldx #0
@lp:
    lda $0,x
    sta SavedZp, x
    inx
    cpx #SavedZpLen
    bcc @lp
@out:
    rts
    
RestoreZp:
    ldx #0
@lp:
    lda SavedZp, x
    sta $0,x
    inx
    cpx #SavedZpLen
    bcc @lp
@out:
    rts

SineCalcTimersAdvance:
    sta SavedA
    sty SavedY
    lda TimersPtr
    pha
    lda TimersPtr+1
    pha
        lda SavedA
        sta TimersPtr
        lda SavedY
        sta TimersPtr+1
        ; Load how many timers
        ldy #0
        lda (TimersPtr),y
        sta NumTimers
        ; Bump the TimersPtr to point at 1st tmr
        inc TimersPtr
        bne @nextTimer
        inc TimersPtr+1
@nextTimer:
        ; Load this timer's info
        ldy #0
@nextFld:
        lda (TimersPtr),y
        sta TimerRise,y
        iny
        cpy #4
        bne @nextFld
        ; done copying, back up a couple fields
        dey
        dey
        ; Advance the timer by rise/run
        lda TimerRise
        clc
        adc TimerRem
        sec
@recheck:
        sbc TimerRun
        bcc @timerDone
        ; If we're here, carry is set and
        ;  our rise has met or exceeded run.
        ; increment the timer.
        inc TimerVal
        ; Circle back and check if it
        ; still succeeds!
        jmp @recheck
@timerDone:
        ; We exceeded the divisor. Add back
        ; and then save.
        adc TimerRun ; carry guaranteed unset
        pha
        lda TimerVal
        sta (TimersPtr),y
        ; Store the remainder
        pla
        iny
        sta (TimersPtr),y
        ; Are we out of timers?
        dec NumTimers
        beq @allTimersDone ; Yes: branch
        ; No: adjust TimersPtr and loop back
        lda TimersPtr
        clc
        adc #4
        sta TimersPtr
        lda TimersPtr+1
        adc #0 ; for carry
        sta TimersPtr+1
        bne @nextTimer ; always
@allTimersDone:
    pla
    sta TimersPtr+1
    pla
    sta TimersPtr
    rts
NumTimers:
    .byte 0
TimerRise:
    .byte 0
TimerRun:
    .byte 0
TimerVal:
    .byte 0
TimerRem:
    .byte 0

PushVal:
    ;; WARNING: unguarded stack access!
    ldy StackCtr
    sta SCStack, y
    inc StackCtr
    rts

PopVal:
    ;; WARNING: unguarded stack access!
    dec StackCtr
    ldy StackCtr
    lda SCStack, y
    rts

;;;; Instruction Handlers ;;;;

; Input: TIM#
; Output: TVAL
TimerPop:
    jsr PopVal
    ; Multiply by 4
    asl
    asl
    clc
    adc #3
    tay
    ;
    lda (TimersPtr),y
    jsr PushVal
    jmp NextInstr

; Input: AMP PHASE
; Output: SINE
HandleSine:
    jsr PopVal
    tax
    jsr PopVal
    jsr Sine
    jsr PushVal
    jmp NextInstr

; Input: A B
; Output: SUM
HandleAdd:
    jsr PopVal
    sta @tmp
    jsr PopVal
    clc
    adc @tmp
    jsr PushVal
    jmp NextInstr
@tmp:
    .byte 0

; Input: A B
; Output: DIFF
HandleSub:
    jsr PopVal
    sta @tmp
    jsr PopVal
    sec
    sbc @tmp
    jsr PushVal
    jmp NextInstr
@tmp:
    .byte 0

;;;;

SavedZp:
    .res 4
SavedZpLen = * - SavedZp

SCStack:
    .res 16
SCStackLen = * - SCStack
