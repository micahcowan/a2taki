.export Sine

;; Returns a sinusoidal value, scaled to A-reg
;;   A-reg: scale (returned value will never be
;;          greater in magnitude)
;;   X-reg: phase
;;   Y-reg: DESTROYED
;;   RETURNS: A * sine( X-reg * PI / 128 )
Sine:
    tay
    ; First, get sine value 0 - 255
    lda SineTable, x
    jsr ScaleFrac
    rts

ScaleFrac:
    pha
    tya
    
    cpy #0
    bmi @handleNeg
    pla
    jmp ScaleFracUns

@handleNeg:
    ; reverse scale 
    sec
    sbc #1
    eor #$FF
    tay
    pla
    jsr ScaleFracUns
    sta @tmp
    lda #0
    sec
    sbc @tmp
@out:
    rts
@tmp:
    .byte 0
    
;; Sets A to Y * A/256, where
ScaleFracUns:
    ;
    sta SineFracL
    lda #0
    sta SineFracH
    sta ScaledL
    sta ScaledH
    lda #$80 ; loop guard
    sta @loopGuard
    tya ; move scale to A-reg
    sta SineScale
    asl ; multiply scale * 2
        ; because afterward we'll subtract
        ; to go from twice the range, unsigned,
        ; to pos/neg signed, at correct range
@loop:
    lsr
    pha
        ; Do we have a set bit?
        bcc @noAdd ; No: don't add current fraction
        ; Yes: add current fraction
        clc
        lda SineFracL
        adc ScaledL
        sta ScaledL
        lda SineFracH
        adc ScaledH
        sta ScaledH
@noAdd: ; rotate the fraction and the loop guard
        ; fraction:
        lda SineFracL
        asl
        sta SineFracL
        lda SineFracH
        rol
        sta SineFracH
        ; loop guard:
        lda @loopGuard
        lsr
        sta @loopGuard
    pla
    bcc @loop
    ; Round to nearest
    lda ScaledL
    bpl @roundDone
    inc ScaledH
@roundDone:
    ; Adjust back down to pos/neg
    lda ScaledH
    sec
    sbc SineScale
    rts
@loopGuard:
    .byte 0
SineScale:
    .byte 0
SineFracL:
    ; fractional value we got from SineTable
    .byte 0
SineFracH:
    .byte 0
ScaledL:
    ; the value we're constructing
    .byte 0
ScaledH:
    .byte 0

SineTable:
.byte $80, $83, $86, $89, $8C, $8F, $92, $95
.byte $98, $9B, $9E, $A2, $A5, $A7, $AA, $AD
.byte $B0, $B3, $B6, $B9, $BC, $BE, $C1, $C4
.byte $C6, $C9, $CB, $CE, $D0, $D3, $D5, $D7
.byte $DA, $DC, $DE, $E0, $E2, $E4, $E6, $E8
.byte $EA, $EB, $ED, $EE, $F0, $F1, $F3, $F4
.byte $F5, $F6, $F8, $F9, $FA, $FA, $FB, $FC
.byte $FD, $FD, $FE, $FE, $FE, $FF, $FF, $FF
.byte $FF, $FF, $FF, $FF, $FE, $FE, $FE, $FD
.byte $FD, $FC, $FB, $FA, $FA, $F9, $F8, $F6
.byte $F5, $F4, $F3, $F1, $F0, $EE, $ED, $EB
.byte $EA, $E8, $E6, $E4, $E2, $E0, $DE, $DC
.byte $DA, $D7, $D5, $D3, $D0, $CE, $CB, $C9
.byte $C6, $C4, $C1, $BE, $BC, $B9, $B6, $B3
.byte $B0, $AD, $AA, $A7, $A5, $A2, $9E, $9B
.byte $98, $95, $92, $8F, $8C, $89, $86, $83
.byte $80, $7C, $79, $76, $73, $70, $6D, $6A
.byte $67, $64, $61, $5D, $5A, $58, $55, $52
.byte $4F, $4C, $49, $46, $43, $41, $3E, $3B
.byte $39, $36, $34, $31, $2F, $2C, $2A, $28
.byte $25, $23, $21, $1F, $1D, $1B, $19, $17
.byte $15, $14, $12, $11, $0F, $0E, $0C, $0B
.byte $0A, $09, $07, $06, $05, $05, $04, $03
.byte $02, $02, $01, $01, $01, $00, $00, $00 
.byte $00, $00, $00, $00, $01, $01, $01, $02
.byte $02, $03, $04, $05, $05, $06, $07, $09
.byte $0A, $0B, $0C, $0E, $0F, $11, $12, $14
.byte $15, $17, $19, $1B, $1D, $1F, $21, $23
.byte $25, $28, $2A, $2C, $2F, $31, $34, $36
.byte $39, $3B, $3E, $41, $43, $46, $49, $4C
.byte $4F, $52, $55, $58, $5A, $5D, $61, $64
.byte $67, $6A, $6D, $70, $73, $76, $79, $7C
