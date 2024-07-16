;; Bounce-In effect
;;
;; Captures several lines of text,
;; and bounces them in from the right, one at a time.

.macpack apple2

.include "taki-effect.inc"
.include "taki-public.inc"
.include "a2-monitor.inc"

config: .byte 1
types:  .byte TAKI_CFGTY_BYTE
words:
        scrcode "FBTW"  ; Sets how many frames to wait between starting a
                        ; bounce-in for the next line. ONLY read
                        ; from INIT; ignored in CONFIG
        .byte $00 ; terminator

declVar vUsrFbtw,   1
declVar vFbtw,      1
declVar vSimul,     1   ; Max number of lines drawn at a time. frames / fbtw
declVar vCountdown, 1   ; Countdown to start next line animation (init'd
                        ;  to vFbtw)
declVar vLineAnims, 2   ; Address of per-line-animation variables,
                        ;  allocated when collection is finished.
declVar vNumLine,   1   ; Index into currently-updating line in vLineNums
declVar vLineNums,  25  ; Which lines have been written to/need the bounce
declVar vBufBAS,    2   ; Address of the start of the current line,
                        ;  in our lines buffer
declVar vLinesBuf,  0   ; Start of lines buffer (allocated piecemeal as
                        ;  needed)

kNumLines = 24
kCharsInRow = 40
kBufLineSz = kCharsInRow + 2    ; to make space for a recorded BASL/H

TAKI_EFFECT TE_BounceIn, "BOUNCE-IN", 0, config
	cmp #TAKI_DSP_INIT	; init?
        bne CkColl
        ;; INIT
        ; Allocate the space we will need
        effAllocate kVarSpaceNeeded

        lda #0
        effSetVar vFbtw
        effSetVar vNumLine; (skip vFtbw, vSimul and vLineAnims for now)
@initLineNums:
        effSetNext
        cpy #(vBufBAS-1)
        bne @initLineNums

        ; set vBufBAS - right now, actually, it'll be identical to
        ;  TAKI_ZP_EFF_STORAGE_END;
        lda TAKI_ZP_EFF_STORAGE_END_L
        effSetNext ; vBufBAS
        lda TAKI_ZP_EFF_STORAGE_END_H
        effSetNext ; vBufBAS + 1
        
	rts
CkColl: cmp #TAKI_DSP_COLLECT	; collect?
        beq @yesColl
        jmp CkCollectEnd
@yesColl:

        ;; COLLECT
        ; Set up a pointer to the current line number
        effGetVar vNumLine
        clc
        adc #vLineNums  ; add offset to where the line indicess are.
                        ; Too small to set carry.
        adc TAKI_ZP_EFF_STORAGE_L
        sta TAKI_ZP_EFF_SPECIAL_0
        lda TAKI_ZP_EFF_STORAGE_H
        adc #0 ; for carry
        sta TAKI_ZP_EFF_SPECIAL_1
        effGetVar vBufBAS
        sta TAKI_ZP_EFF_SPECIAL_2
        effGetNext
        sta TAKI_ZP_EFF_SPECIAL_3
        ldy #0

        lda TAKI_ZP_ACC
        ;brk
        cmp #$8D        ; is it a carriage return?
        beq @cr         ; yes -> process it
        cmp #$A0        ; is it a space?
        bne @regChar    ; no -> store regular character
        ; yes, it's a space. Don't store, just advance CH
        ldy Mon_CH
        iny
        bne @checkCH
@regChar:
        lda (TAKI_ZP_EFF_SPECIAL_0),y
                        ; are we currently in a recorded line?
        beq @recordLine ; no -> record this line and set up vBufBAS
        ; yes. Does the recorded line match current CV?
        sec
        sbc #1 ; We store as +1 for null termination
        cmp Mon_CV
        beq @recordChar ; yes -> Record the character in the lineBuf.
        ; no -> finish this line, record current one
@advAndRecordLine:
        jsr @advNumLine
@recordLine:
        ; Note: we only allocate a new line buffer when a line
        ; has actually been written to. To avoid "bouncing" in
        ; blank lines.

        ; store CV+1 at the current spot in vLineNums
        lda Mon_CV
        clc
        adc #1 ; stored as +1 so null termination still works when CV = 0
        ldy #0
        sta (TAKI_ZP_EFF_SPECIAL_0),y
        ; allocate the line in buffer
        effAllocate kBufLineSz
        ; record BAS. Assume monitor BASL/H is correct
        lda Mon_BASL
        sta (TAKI_ZP_EFF_SPECIAL_2),y
        lda Mon_BASH
        iny
        sta (TAKI_ZP_EFF_SPECIAL_2),y
        ; clear the allocated line
        iny
        lda #$A0 ; space character
@clearLp:
        sta (TAKI_ZP_EFF_SPECIAL_2),y
        iny
        cpy #kBufLineSz
        bne @clearLp
@recordChar:
        lda TAKI_ZP_ACC
        ldy Mon_CH
        iny ; advance to compensate for two-byte BASL at start of line buffer
        iny
        sta (TAKI_ZP_EFF_SPECIAL_2),y
        dey ; + 2 - 1 = +1 for advancing Mon_CH value
@checkCH:
        ; Did CH just exceed the line length? (XXX: ignores WNDLFT/WNDWDTH)
        cpy #(kCharsInRow + 1)
        bcs @cr             ; yes -> finish this line
        ; CH is fine, so just store and return.
        sty Mon_CH
        rts
@cr:
        ; set CH to 0
        lda #0
        sta Mon_CH
        ; advance CV(?)
        inc Mon_CV
        lda Mon_CV
        cmp #kNumLines
        bcc @notTooHigh ; CV not too high, advance and recalculate
        ; CV too high, lock to bottom of screen.
        lda #(kNumLines - 1)
        sta Mon_CV
@notTooHigh:
        ; recalculate Mon_BASL
        jsr Mon_VTAB
        ; If current line isn't recorded, bail without advancing vNumLine
        lda (TAKI_ZP_EFF_SPECIAL_0),y
                        ; are we currently in a recorded line?
        beq @advRts     ; no -> skip advancing the line then
@advNumLine:
        ; advance vNumLine (onto a null)
        effGetVar vNumLine
        clc
        adc #1
        effSetCur ; vNumLine
        inc TAKI_ZP_EFF_SPECIAL_0
        bne :+
        inc TAKI_ZP_EFF_SPECIAL_1
        :
        ; advance vBufBAS past the end of the current buffer
        lda TAKI_ZP_EFF_SPECIAL_2 ; vBufBASL
        clc
        adc #kBufLineSz
        sta TAKI_ZP_EFF_SPECIAL_2
        effSetVar vBufBAS
        lda TAKI_ZP_EFF_SPECIAL_3 ; vBufBASH
        adc #0 ; for carry
        sta TAKI_ZP_EFF_SPECIAL_3
        effSetNext
@advRts:
        rts
CkCollectEnd:
	cmp #TAKI_DSP_ENDCOLLECT
        bne CkTick

        ;; END COLLECT
        ; Copy user-specified frames-between value at INIT, to our
        ;  non-user-accessible var (so it won't be impacted by a later CONFIG)
        effGetVar vUsrFbtw
        effSetNext ; vFbtw

        ; Calculate vSimul
        ldx #0
        effGetVar vFbtw
        bne :+
        lda AnimFrames ; if it's zero, substitute exactly the # anim frames
        effSetCur ; store back into vFbtw
        :
        sta TAKI_ZP_EFF_SPECIAL_0
        lda AnimFrames
        sec
@lpDiv:
        sbc TAKI_ZP_EFF_SPECIAL_0
        bcc @doneDiv
        inx
        bne @lpDiv ; always
@doneDiv:
        adc TAKI_ZP_EFF_SPECIAL_0   ; carry is clear. Add back in to check
                                    ;  for remainder.
        beq @exact  ; no remainder, exact.
        inx         ; remainder. Sometimes we'll need an extra animation.
@exact:
        cpx #0
        bne @fine
        inx
@fine:
        txa
        effSetVar vSimul

        ; XXX Set up fbtw timer, and vSimul # of animation variables

        rts
UnsupportedMode:
        rts
CkTick:
	cmp #TAKI_DSP_TICK	; tick?
        bne UnsupportedMode

        ;; TICK
        rts

AnimFrames:
;;;; (Generated by calc-bounce)

; Generating 31 frames at 30 fps, to last 1.000000 seconds.
; Time to reach left edge the first time: 0.500000 seconds (15 frames).
; Time to reach left edge the second time: 0.500000 seconds (16 frames).

; First byte is frame count, for convenience.
.byte 31

; Slide-left frames:

.byte 25, 25, 25, 24, 23, 22, 21, 20
.byte 18, 16, 14, 12, 10, 7, 4

; Bounce frames:

.byte 1, 2, 4, 5, 6, 6, 7, 7
.byte 7, 7, 6, 6, 5, 4, 2, 1

.byte 0
