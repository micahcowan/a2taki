;; Bounce-In effect
;;
;; Captures several lines of text,
;; and bounces them in from the right, one at a time.

.macpack apple2

.include "taki-effect.inc"
.include "taki-public.inc"
.include "a2-monitor.inc"

config: .byte 2
types:  .byte TAKI_CFGTY_BYTE
        .byte TAKI_CFGTY_BYTE
words:
        scrcode "SHUF"  ; Sets whether bounced lines are shuffled first,
                        ; 0=no, 1=yes (default=yes)
        .byte $00 ; terminator
        scrcode "FBTW"  ; Sets how many frames to wait between starting a
                        ; bounce-in for the next line. ONLY read
                        ; from INIT; ignored in CONFIG
        .byte $00 ; terminator

declVar vShuffle,   1
declVar vUsrFbtw,   1
declVar vFbtw,      1
declVar vSimul,     1   ; Max number of lines drawn at a time. frames / fbtw
declVar vCountdown, 1   ; Countdown to start next line animation (init'd
                        ;  to vFbtw)
declVar vLinesDeck, 2   ; Address of shuffled line indices
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

; Animation var offsets
avWhichLine     = 0 ; 1 byte. $FF means not currently animating a line
avFrameNum      = 1 ; 1 byte
kAvarSize = 2

TAKI_EFFECT TE_BounceIn, "BOUNCE-IN", 0, config
	cmp #TAKI_DSP_INIT	; init?
        bne CkColl
        ;; INIT
        ; Allocate the space we will need
        effAllocate kVarSpaceNeeded

        lda #1
        effSetVar vShuffle
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
        cpy #kCharsInRow
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
        beq :+
        jmp CkTick
        :

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

        ; allocate a "deck" of indices into vLinesBuf
        ; ...first write the start of this deck in a var
        lda TAKI_ZP_EFF_STORAGE_END_L
        sta TAKI_ZP_EFF_SPECIAL_0
        effSetVar vLinesDeck
        lda TAKI_ZP_EFF_STORAGE_END_H
        sta TAKI_ZP_EFF_SPECIAL_1
        effSetNext

        ; Now allocate space for the deck
        effGetVar vNumLine
        sta TAKI_ZP_EFF_SPECIAL_2
        clc
        adc #1 ; for null term
        effAllocateA

        ; And write the indices out, +1 for null-termination
        lda TAKI_ZP_EFF_SPECIAL_2
        tay
        lda #0
        sta (TAKI_ZP_EFF_SPECIAL_0),y
        tya
        beq @indexMkDone
@indicesLp:
        dey
        sta (TAKI_ZP_EFF_SPECIAL_0),y
        tya
        bne @indicesLp
@indexMkDone:
        ; shuffle them!
        ; ...pick a random remaining card
        effGetVar vShuffle
        beq @doneShuffle
        ldy #0
        lda TAKI_ZP_EFF_SPECIAL_2
        beq @doneShuffle
@shuffle:
        jsr TakiIoRandWithinAY
        tay
        ; ...and swap it with the current one
        sty TAKI_ZP_EFF_SPECIAL_3
        lda (TAKI_ZP_EFF_SPECIAL_0),y
        pha ; save random card val
            ldy #0
            lda (TAKI_ZP_EFF_SPECIAL_0),y
            ldy TAKI_ZP_EFF_SPECIAL_3
            sta (TAKI_ZP_EFF_SPECIAL_0),y ; ...overwrite with cur
        pla
        ldy #0
        sta (TAKI_ZP_EFF_SPECIAL_0),y ; ...overwrite cur with rand (swapped!)
        ; bump "cur card" cursor
        inc TAKI_ZP_EFF_SPECIAL_0
        bne :+
        inc TAKI_ZP_EFF_SPECIAL_1
        :
        ; and decrement random-choice range
        ldy #0
        dec TAKI_ZP_EFF_SPECIAL_2
        lda TAKI_ZP_EFF_SPECIAL_2
        bne @shuffle
@doneShuffle:

        ; Set up vSimul # of animation variables, and start one off
        lda TAKI_ZP_EFF_STORAGE_END_L
        sta TAKI_ZP_EFF_SPECIAL_0
        effSetVar vLineAnims
        lda TAKI_ZP_EFF_STORAGE_END_H
        sta TAKI_ZP_EFF_SPECIAL_1
        effSetNext

        effGetVar vSimul
        pha
            effAllocateA
        pla
        tax
        lda #$FF
        ldy #0
@animVarsLp:
        sta (TAKI_ZP_EFF_SPECIAL_0),y
        dex
        beq @animVarsDone
        iny
        iny
        bne @animVarsLp ; always
@animVarsDone:
        ; Fall through
StartAnAnimation:
        effGetVar vLinesDeck
        sta TAKI_ZP_EFF_SPECIAL_2
        effGetNext
        sta TAKI_ZP_EFF_SPECIAL_3
        ldy #0
        lda (TAKI_ZP_EFF_SPECIAL_2),y   ; get next line to animate out of
                                        ;  shuffled deck
        bne :+
        rts ; No more lines to animate! Nothing to do.
        :
        sec
        sbc #1  ; subtract one from (+1) indices,
                ; for proper storage into animator
        sta TAKI_ZP_EFF_SPECIAL_2
        effGetVar vLineAnims
        sta TAKI_ZP_EFF_SPECIAL_0
        effGetNext
        sta TAKI_ZP_EFF_SPECIAL_1
        effGetVar vSimul
        tax
        ldy #0
@findAnim:
        lda (TAKI_ZP_EFF_SPECIAL_0),y
        cmp #$FF ; is this animator available?
        beq @useThisAnim
        dex
        beq @animNotFound
        iny
        iny
        bne @findAnim ; always
@animNotFound:
        ; XXX should probably complain about inner error?
        ; set the countdown so it triggers again and searches next frame
        lda #1
        effSetVar vCountdown
        rts
@useThisAnim:
        ; Found our animator.
        ; Set it to frame 1
        iny
        lda #1
        sta (TAKI_ZP_EFF_SPECIAL_0),y
        ; And mark it as busy with a line
        dey
        lda TAKI_ZP_EFF_SPECIAL_2
        sta (TAKI_ZP_EFF_SPECIAL_0),y
        ; Reset the countdown
        effGetVar vFbtw
        effSetVar vCountdown
        ; Finally, discard this line from the shuffled "deck"
        effGetVar vLinesDeck
        clc
        adc #1
        effSetCur
        bcc @skipHigh
        effGetNext
        adc #0 ; carry
        effSetCur
@skipHigh:
UnsupportedMode:
        rts
CkTick:
	cmp #TAKI_DSP_TICK	; tick?
        bne UnsupportedMode

        ;; TICK
        ; Set up ZP vars
        effGetVar vLineAnims
        sta TAKI_ZP_EFF_SPECIAL_0
        effGetNext
        sta TAKI_ZP_EFF_SPECIAL_1
        effGetVar vSimul
        pha
@animLoop:
            ; Iterate over the animators, and handle each
            ldy #0
            lda (TAKI_ZP_EFF_SPECIAL_0),y
            cmp #$FF
            beq @fake
            jsr HandleRealAnim
            jmp @next
@fake:
            jsr HandleFakeAnim
@next:
        pla
        sec
        sbc #1
        beq @animIterDone
        pha
            ; Advance to next animator
            lda TAKI_ZP_EFF_SPECIAL_0
            clc
            adc #2
            sta TAKI_ZP_EFF_SPECIAL_0
            bcc :+
            lda TAKI_ZP_EFF_SPECIAL_1
            adc #0 ; carry
            sta TAKI_ZP_EFF_SPECIAL_1
            :
        bne @animLoop ; always
@animIterDone:
        ; Decrement the countdown
        effGetVar vCountdown
        sec
        sbc #1
        beq @startNew
        effSetCur
        rts
@startNew:
        jmp StartAnAnimation

HandleFakeAnim:
        ; The purpose of this routine is to waste a similar amount of time,
        ; as would legitimately be spent handling a real animation.
        ; This is done to avoid stilted or jumpy animations by
        ; preventing dramatic speedups just because there's less work
        ; that needs doing.

        ; Scan through 40 characters, reading each twice.
        ; This simulates copying them out.
        ldy #39
@copyLp:
        lda (Mon_BASL),y
        lda (Mon_BASL),y
        dey
        bne @copyLp

        rts

HandleRealAnim:
        ; Find the line in question, and set it up in the ZP.
        ; ...line # is already in the accum. Push it for now.
        pha
            ; Start by setting up the overall buffer start, in ZP
            lda TAKI_ZP_EFF_STORAGE_L
            clc
            adc #vLinesBuf
            sta TAKI_ZP_EFF_SPECIAL_2
            lda TAKI_ZP_EFF_STORAGE_H
            adc #0 ; carry
            sta TAKI_ZP_EFF_SPECIAL_3
            ; Now, keep advancing to next line buffer until we've
            ; reached ours.
@findLine:
        pla
        beq @gotLine
        sec
        sbc #1
        pha
            lda TAKI_ZP_EFF_SPECIAL_2
            clc
            adc #kBufLineSz
            sta TAKI_ZP_EFF_SPECIAL_2
            bcc :+
            inc TAKI_ZP_EFF_SPECIAL_3
            :
        jmp @findLine
@gotLine:
        ; Set up at BASL
        lda Mon_BASL
        sta @SavedBASL
        lda Mon_BASH
        sta @SavedBASL+1
        ldy #0
        lda (TAKI_ZP_EFF_SPECIAL_2),y
        sta Mon_BASL
        iny
        lda (TAKI_ZP_EFF_SPECIAL_2),y
        sta Mon_BASH
            ; What's the frame number?
            ldy #avFrameNum
            lda (TAKI_ZP_EFF_SPECIAL_0),y
            ; Translate to column # (+1)
            tax
            lda AnimFrames,x
            sec
            sbc #1
            sta @SavedCol
            ; First, print spaces until we're at our column
            ldy #0
            tax
            beq @donePrSp
            lda #$A0 ; SPC
@loopPrSp:
            sta (Mon_BASL),y
            iny
            dex
            bne @loopPrSp
@donePrSp:
            ; Next, print our line.
            ; Advance our ZP to the start of text.
            ;brk
            lda TAKI_ZP_EFF_SPECIAL_2
            clc
            adc #2
            sta TAKI_ZP_EFF_SPECIAL_2
            bcc :+
            inc TAKI_ZP_EFF_SPECIAL_3
            :
            ; Advance BASL/H, too
            tya
            clc
            adc Mon_BASL
            sta Mon_BASL
            bcc :+
            inc Mon_BASH
            :
            lda #kCharsInRow
            sec
            sbc @SavedCol
            beq @doneCpy
            tax
            ldy #0
@copy:
            lda (TAKI_ZP_EFF_SPECIAL_2),y
            sta (Mon_BASL),y
            dex
            beq @doneCpy
            inc TAKI_ZP_EFF_SPECIAL_2
            bne :+
            inc TAKI_ZP_EFF_SPECIAL_3
            :
            inc Mon_BASL
            bne @copy
            inc Mon_BASH
            bne @copy
@doneCpy:
        lda @SavedBASL+1
        sta Mon_BASH
        lda @SavedBASL
        sta Mon_BASL
        ; Advance animation to next frame
        ldy #avFrameNum
        lda (TAKI_ZP_EFF_SPECIAL_0),y
        clc
        adc #1
        sta (TAKI_ZP_EFF_SPECIAL_0),y
        ; Make sure animation's not done
        tax
        lda AnimFrames,x
        beq @animDone
        rts ; animation not done, can exit
@animDone:
        ; Animation is done
        ldy #avWhichLine
        lda #$FF ; idle (or, rather, busy with "fake" animation)
        sta (TAKI_ZP_EFF_SPECIAL_0),y
        rts
@SavedBASL:
        .word 0
@SavedCol:
        .byte 0

AnimFrames:
;;;; Generated by calc-bounce

; Generating 39 frames at 30 fps, to last 1.250000 seconds.
; Time to reach left edge the first time: 0.500000 seconds (15 frames).
; Time to reach left edge the second time: 0.500000 seconds (15 frames).
; Time to reach left edge the third time: 0.250000 seconds (9 frames).

; First byte is frame count, for convenience.
.byte 39

; Slide-left frames:

.byte 41, 41, 40, 39, 38, 37, 35, 32
.byte 30, 27, 23, 19, 15, 11, 6

; Bounce 1 frames:

.byte 1, 3, 6, 7, 9, 10, 11, 11
.byte 11, 11, 10, 9, 7, 6, 3

; Bounce 2 frames:

.byte 1, 2, 3, 3, 3, 3, 3, 2
.byte 1

.byte 0
