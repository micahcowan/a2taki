;; Open-the-door effect
;;
;; Displays an ascii animation of a door being opened, when
;; CONFIG OPEN=1 is set.

.macpack apple2

.include "taki-effect.inc"
.include "taki-public.inc"
.include "a2-monitor.inc"

kNumSprites = 7
kSpriteWidth = 4
kSpriteHeight = 4
kSpriteSize = kSpriteWidth * kSpriteHeight
tblSprites:
    scrcode "DOOR"
    scrcode "    "
    scrcode "    "
    scrcode "    "
;
    scrcode "DO  "
    scrcode "  OR"
    scrcode "    "
    scrcode "    "
;
    scrcode "D   "
    scrcode " OO "
    scrcode "   R"
    scrcode "    "
;
    scrcode "D   "
    scrcode " O  "
    scrcode "  O "
    scrcode "   R"
;
    scrcode "D   "
    scrcode " O  "
    scrcode " O  "
    scrcode "  R "
;
    scrcode "D   "
    scrcode "O   "
    scrcode " O  "
    scrcode " R  "
;
    scrcode "D   "
    scrcode "O   "
    scrcode "O   "
    scrcode "R   "
;

kOrientationSize = 1
tblOrientations:
    ; AS DEFINED:
    .byte 0             ; start (as offset from start of sprite)
    .word 1             ; step (can be negative)
    .word 0             ; amount to adjust cursor between rows (can be negative)

declVar     varOpen, 1
declVar     varCH, 1
declVar     varCV, 1
declVar     varSprNum, 1

config: .byte 1
types:  .byte TAKI_CFGTY_BYTE
words:
    scrcode "OPEN"
    .byte $00 ; terminator

TAKI_EFFECT TE_Door, "DOOR", 0, config
    cmp #TAKI_DSP_INIT      ; init?
    bne CkColl
    ;; INIT
    ; Allocate the space we will need
    effAllocate kVarSpaceNeeded

    ; save cursor X and Y
    lda #0
    effSetVar varOpen
    lda Mon_CH
    sta SavedCH
    effSetNext ; varCH
    lda Mon_CV
    sta SavedCV
    effSetNext ; varCV
    lda Mon_BASL
    sta SavedBAS
    lda Mon_BASH
    sta SavedBAS+1
    lda #0
    effSetNext ; varSprNum
    jsr drawDoor
    jmp Cleanup
UnsupportedMode:
    rts
CkColl:
    cmp #TAKI_DSP_COLLECT   ; collect?
    bne CkTick
    ; COLLECT
    lda TAKI_ZP_ACC
    jmp TakiIoFastOut ; XXX
CkTick:
    cmp #TAKI_DSP_TICK      ; tick?
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
    ; Are we opening or closing a door?
    effGetVar varOpen
    bne @openDoor
@closeDoor:
    ; Decrement sprite #
    effGetVar varSprNum
    beq @drawDoor
    sec
    sbc #1
    effSetCur
    jmp @drawDoor
@openDoor:
    ; Increment sprite #
    effGetVar varSprNum
    cmp #(kNumSprites-1)
    beq @drawDoor
    clc
    adc #1
    effSetCur
@drawDoor:
    jsr drawDoor
    jmp Cleanup
Cleanup:
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

vSpriteCursor = TAKI_ZP_EFF_SPECIAL_0
vOrientation  = TAKI_ZP_EFF_SPECIAL_2
vRowsLeft:
    .byte 0
drawDoor:
    ; Init
    lda #>tblSprites
    sta vSpriteCursor+1
    lda #<tblSprites
    sta vSpriteCursor
    lda #kSpriteHeight
    sta vRowsLeft
    ;
    ; Adjust values per pakku's orientation
    ;
    lda #<tblOrientations
    sta vOrientation
    lda #>tblOrientations
    sta vOrientation+1

    ; adjust values
    ldy #0
    lda (vOrientation),y
    sta @orStart+1
    iny
    lda (vOrientation),y
    sta @orStepL+1
    iny
    lda (vOrientation),y
    sta @orStepH+1
    iny
    lda (vOrientation),y
    sta @orRowAdjL+1
    iny
    lda (vOrientation),y
    sta @orRowAdjH+1

    ; Adjust for sprite #
    effGetVar varSprNum
    tax
    beq @correctSpr
@nextSpr:
    lda vSpriteCursor
    clc
    adc #kSpriteSize
    sta vSpriteCursor
    bcc :+
    inc vSpriteCursor+1
    :
    dex
    bne @nextSpr
@correctSpr:
    ; Now adjust for orientation start
    lda vSpriteCursor
    clc
@orStart:
    adc #0  ; this op WILL BE MODIFIED for orientation
    sta vSpriteCursor
    bcc :+
    inc vSpriteCursor+1
    :
    effGetVar varCV
    pha
@rowLoop:
        ; Calculate memory location from y
        sta Mon_CV
        jsr Mon_VTAB
        ; Now add x
        effGetVar varCH
        clc
        adc Mon_BASL
        sta Mon_BASL
        bcc :+
        inc Mon_BASH
        :
        ldy #0
        ldx #kSpriteWidth
@colLoop:
        ; copy "pixel" character
        lda (vSpriteCursor),y
        sta (Mon_BASL),y
        ; advance cursors
        inc Mon_BASL
        lda vSpriteCursor
        clc
@orStepL:
        adc #1      ; this op WILL BE MODIFIED for orientation
        sta vSpriteCursor
        lda vSpriteCursor+1
@orStepH:
        adc #0      ; this op WILL BE MODIFIED for orientation
        sta vSpriteCursor+1

        ;
        dex
        bne @colLoop ;END LOOP colLoop
        ; Are we done?
        dec vRowsLeft
        bne @notDone
    ; END LOOP rowLoop
    pla
    rts
@notDone:
        ; advance sprite cursor
        lda vSpriteCursor
        clc
@orRowAdjL:
        adc #0  ; this op WILL BE MODIFIED for orientation
        sta vSpriteCursor
        lda vSpriteCursor+1
@orRowAdjH:
        adc #0  ; this op WILL BE MODIFIED for orientation
        sta vSpriteCursor+1
    ; advance CV
    pla
    clc
    adc #1
    pha
    jmp @rowLoop
