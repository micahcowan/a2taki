;; Pakku effect
;;
;; Displays an ascii animation of a certain world-beloved dot-eating
;; video game character

.macpack apple2

.include "taki-effect.inc"
.include "taki-public.inc"
.include "a2-monitor.inc"

kNumSprites = 4
kSpriteWidth = 7
kSpriteHeight = 7
kSpriteSize = kSpriteWidth * kSpriteHeight
tblPakkuSprites:
    scrcode "  ###  "
    scrcode " ##### "
    scrcode "#####  "
    scrcode "####   "
    scrcode "#####  "
    scrcode " ##### "
    scrcode "  ###  "
;
    scrcode "  ###  "
    scrcode " ##### "
    scrcode "#######"
    scrcode "#####  "
    scrcode "#######"
    scrcode " ##### "
    scrcode "  ###  "
;
    scrcode "  ###  "
    scrcode " ##### "
    scrcode "#######"
    scrcode "#######"
    scrcode "#######"
    scrcode " ##### "
    scrcode "  ###  "
;
    scrcode "  ###  "
    scrcode " ##### "
    scrcode "#######"
    scrcode "#####  "
    scrcode "#######"
    scrcode " ##### "
    scrcode "  ###  "

kOrientationSize = 4
Orientations:
    ; start,    step,   rowAdjust,  done
    ; 0 = RIGHT
    .byte 0,    1,      0,          kSpriteSize
    ; 1 = LEFT
    ;.byte 
curOrientation:
    .byte 0
curSprite:
    .byte 0

declVar     varCH, 1
declVar     varCV, 1

TAKI_EFFECT TE_Pakku, "PAKKU", 0, 0
	cmp #TAKI_DSP_INIT	; init?
        bne CkTick
        ;; INIT
        ; Allocate the space we will need
        effAllocate kVarSpaceNeeded

        ; save cursor X and Y
        lda Mon_CH
        sta SavedCH
        effSetVar varCH
        lda Mon_CV
        sta SavedCV
        effSetNext
        lda Mon_BASL
        sta SavedBAS
        lda Mon_BASH
        sta SavedBAS+1
        lda #0
        sta curOrientation
        sta curSprite
        jsr drawPakku
        jmp Cleanup
UnsupportedMode:
        rts
CkTick:
	cmp #TAKI_DSP_TICK	; tick?
        bne UnsupportedMode
        rts

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
        beq Cleanup
        pha
            and #$DF    ; de-lowercase
            ora #$80    ; ensure normal range
            cmp #$DB    ; >  'Z'?
            bcs @prLit  ; yes -> print literal char
            cmp #$C1    ; >= 'A'?
            bcc @prLit  ; no ->  print literal char
        pla
        ; Print garbage!
        jsr TakiIoFastOut
        jmp PrintLoop
@prLit:
        pla
        jsr TakiIoFastOut
        jmp PrintLoop
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
vCursorStop:
    .word 0
drawPakku:
    ; Init
    lda #>tblPakkuSprites
    sta vSpriteCursor+1
    sta vCursorStop+1
    lda #<tblPakkuSprites
    sta vSpriteCursor
    sta vCursorStop
    ; Note expected final position of the sprite scanning cursor
    clc
    adc #kSpriteSize ; XXX orientation zero-specific
    sta vCursorStop
    bcc :+
    inc vCursorStop+1
    :
    ;
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
        ldx #7
@colLoop:
        ; copy "pixel" character
        lda (vSpriteCursor),y
        sta (Mon_BASL),y
        ; advance cursors
        inc Mon_BASL
        lda vSpriteCursor
        clc
        adc #1   ; XXX specific to orientation 0
        sta vSpriteCursor
        bcc :+
        inc vSpriteCursor
        :
        ;
        dex
        bne @colLoop ;END LOOP colLoop
        ; 
        ; Are we done? Check the cursor
        ;
        lda vSpriteCursor
        cmp vCursorStop
        bne @notDone
        lda vSpriteCursor+1
        cmp vCursorStop+1
        bcc @notDone
    ; END LOOP rowLoop
    pla
    rts
@notDone:
        ; advance sprite cursor
        ; XXX nothing to do for orientation 0
        ; advance CV
    pla
    clc
    adc #1
    pha
    jmp @rowLoop
