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

kLocMode	= 0
kLocCH		= kLocMode + 1
kLocCV		= kLocCH + 1
kLocPrevBAS     = kLocCV + 1
kLocTimersAddr  = kLocPrevBAS + 2
kLocHAnimAddr	= kLocTimersAddr + 2 ; same as start of storage + kNeeded, but anyway
kLocVAnimAddr	= kLocHAnimAddr + 2
kLocTextAddr	= kLocVAnimAddr + 2
kNeeded		= kLocTextAddr + 2

; When we're processing animation code (during
; collection), regardless of whether it's going
; to be horizontal or vertical coordinate animation,
; we use kLocVAnimAddr to point at the start of
; the processed code
kLocAnimStartAddr = kLocVAnimAddr

kModeText	= 0
kModeTimers	= 1
kModeHAnim	= 2
kModeVAnim	= 3
kModeSkip	= 4
kModeTextAlt	= 5 ; alternative text mode value

TAKI_EFFECT TE_SineAnim, "SANIM", 0, 0
	cmp #TAKI_DSP_INIT	; init?
        bne CkColl
        ;; INIT
        lda #kModeTimers
        effSetVar kLocMode
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
        adc #0 ; (for carry)
        effSetNext
        ; initialize the basic timer:
        ; 1 timer: 1,0,0,0
        lda #1
        effSetNext
        effSetNext
        lda #0
        effSetNext
        effSetNext
        effSetNext
        ; Allocate the space we used
        effAllocate kNeeded
	rts
CkColl: cmp #TAKI_DSP_COLLECT	; collect?
	beq :+
	jmp CkTick
:
        ;; COLLECT
        effGetVar kLocMode
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
@rts:	rts
CollectTimers:
CollectSkipToCr:
        lda TAKI_ZP_ACC
        cmp #$8D ; carriage return?
        bne @rts ; nope, check next one
        ; bump mode to the next one
        effGetVar kLocMode
        clc
        adc #1
        sta (TAKI_ZP_EFF_STORAGE_L),y ; Y set from effGetVar: "mode"
	cmp #kModeHAnim
        bne @rts
        ; If we're entering animation processing,
        ; set up anim code-start pointer, and decimal
        ; state byte
        lda TAKI_ZP_EFF_STORAGE_L
        clc
        adc #kNeeded
        effSetVar kLocAnimStartAddr
        lda TAKI_ZP_EFF_STORAGE_H
        adc #0 ; for carry
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
@rts:	rts
CollectHAnim:
CollectVAnim:
        jsr ProcessProgramChar
        beq @handleR ; char == 'R'? -> handle it
        rts
@handleR:
	effGetVar kLocMode
        cmp #kModeVAnim
        beq @vDone
@hDone: ; We're exiting horizontal animation code.
	; Copy the start addr for hAnim
        effGetVar kLocAnimStartAddr+1
        effSetVar kLocHAnimAddr+1
        effGetVar kLocAnimStartAddr
        effSetVar kLocHAnimAddr
        ; And set the start addr for vAnim to current
        ; end of storage
        lda TAKI_ZP_EFF_STORAGE_END_L
        effSetVar kLocAnimStartAddr
        lda TAKI_ZP_EFF_STORAGE_END_H
        effSetNext
        jmp @nextMode
@vDone: ; We're exiting vertical animation code.
	; Copy current end of storage as start of text
        lda TAKI_ZP_EFF_STORAGE_END_L
        effSetVar kLocTextAddr
        lda TAKI_ZP_EFF_STORAGE_END_H
        effSetNext
@nextMode:
        ; bump mode to the next mode
        effGetVar kLocMode
        clc
        adc #1
        sta (TAKI_ZP_EFF_STORAGE_L),y ; Y set from effGetVar: "mode"
@rts:	rts
CollectText:
	lda TAKI_ZP_ACC
        effAppendByte
        jmp TakiIoScreenOut
CkTick:
	cmp #TAKI_DSP_TICK	; tick?
        bne NoModesFound
        ;; DRAW TICK
        rts
NoModesFound:
	rts

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
@fail:	clc
	rts