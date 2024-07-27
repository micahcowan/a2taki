.include "forthish.inc"
.include "a2-monitor.inc"
MATH_CA65_NO_IMPORT=1
.include "math-ca65.inc"

.export prBin8_A
prBin8_A:
    ldx #$8
@Lp:asl
    pha
    bcs @On ; print '1' if set, '0' if not
@Ze:lda #$B0
    bne @Pr ; always
@On:lda #$B1
@Pr:jsr Mon_COUT1
    pla
    dex
    bne @Lp
    lda #$A0    ; SPC
    jsr Mon_COUT1
    rts

;; High byte in A, low byte in Y
.export prBin16_AY
prBin16_AY:
    jsr prBin8_A
    tya
    jsr prBin8_A
    rts

;; High byte in A, low byte in Y
;;  Remainder will be placed in X register
DEBUG=0
.export div10w_AY
div10w_AY:
    ; initialize vars
    sta dividendH
    sty dividendL
    lda #0
    sta quotientL
    sta quotientH
    sta markerL
    sta divisorL
    lda #$A0
    sta divisorH
    lda #$10
    sta markerH
@Lp:
    .if DEBUG
        jsr print_state_div10w_AY
    .endif
    lda dividendH
    bne @NotZero
    lda divisorH
    beq @divHZero ; skip high bytes if we're past that
    lda dividendH
@NotZero:
    cmp divisorH
    beq @CheckLow ; divisorH == dividendH? check low byte too
    bcs @Mk       ; divisorH < dividendH? divide!
    ; otherwise shift dividend and marker right and try again
@shiftR:
    lsr divisorH
    ror divisorL
    lsr markerH
    ror markerL ; we'd do a carry check after, but
                ; for 10 we know that only happens
                ; when we're down to low bytes
    jmp @Lp
    ; We need to check divisorL <= dividendL too
@CheckLow:
    lda dividendL
    cmp divisorL
    bcc @shiftR
@Mk:
    lda dividendL
    sec
    sbc divisorL
    sta dividendL
    lda dividendH
    sbc divisorH
    sta dividendH
    lda markerH
    ora quotientH
    sta quotientH
    lda markerL
    ora quotientL
    sta quotientL
    jmp @shiftR
@divHZero:
    .if DEBUG
         jsr print_state_div10w_AY
    .endif
    ; with some prep code before, could jump here for an
    ; 8-bit division...
    lda dividendL
    cmp divisorL
    bcs @Mk8 ; divisorL
    ; shift dividend and marker
@shiftR8:
    lsr divisorL
    lsr markerL
    bcc @divHZero
    ; carry is set - we shifted off the end!
    ; set A and Y according to the result
    lda quotientH
    ldy quotientL
    ldx dividendL ; remainder/modulus
    .if DEBUG
        jmp print_state_cleanup_div10w_AY
    .endif
    rts
@Mk8:
    lda dividendL
    sec
    sbc divisorL
    sta dividendL
    lda markerL
    ora quotientL
    sta quotientL
    jmp @shiftR8
dividendL:
    .byte $00
dividendH:
    .byte $00
quotientL:
    .byte $FF
quotientH:
    .byte $FF
markerL:
    .byte $FF
markerH:
    .byte $FF
divisorL:
    .byte $FF
divisorH:
    .byte $FF

.export mul10w_AY
mul10w_AY:
    ; initialize values
    sta multiplicandH
    sty multiplicandL
    ldy #$00
    sty productH
    sty productL
    sty multiplierH
    ; The multiplier gets a value of 5 instead of 10
    ; to start, because when we shift the first bit off the
    ; multiplicand into the carry, and simultaneously
    ; shift multiplier left, we'll have a value of 10
    ; while we're examining the 1's place.
    ldy #$05
    sty multiplierL
@multLoop:
    asl multiplierL
    rol multiplierH
    bcc @shCand ; if we just shifted off the left bit of
    bne @shCand ; the ten multiplier, and the right bit's
    lda productH; nowhere to be found in the high bit,
    ldy productL; then exit with product
    rts         ; .
@shCand:
    lsr multiplicandH
    ror multiplicandL ; check next bit of multiplicand
    bcc @multLoop     ; unset? loop around again
    lda productL      ; otherwise add the multiplier
    clc
    adc multiplierL
    sta productL
    lda productH
    adc multiplierH
    sta productH
    jmp @multLoop
multiplicandL:
    .byte 0
multiplicandH:
    .byte 0
multiplierL:
    .byte 0
multiplierH:
    .byte 0
productL:
    .byte 0
productH:
    .byte 0

.ifdef DEBUG
.macro prstate code, name
    lda #.strat(code,0) | $80
    jsr Mon_COUT1
    lda #$BA    ; ':'
    jsr Mon_COUT1
    lda #$A0    ; SPC
    jsr Mon_COUT1
    lda .ident(.concat(.string(name),"H"))
    ldy .ident(.concat(.string(name),"L"))
    jsr prBin16_AY
    lda #$8D    ; CR
    jsr Mon_COUT1
.endmacro

print_state_div10w_AY:
    lda Mon_CH ; save char pos
    pha
    lda #$00
    sta Mon_CH
    ; print various states of division
    prstate "X", dividend
    prstate "Y", divisor
    prstate "M", marker
    prstate "Q", quotient
    
    lda Mon_CV
    sec
    sbc #4
    sta Mon_CV
    jsr Mon_BASCALC
    pla
    sta Mon_CH
    rts

print_state_cleanup_div10w_AY:
    pha
    tya
    pha
    txa
    pha
    lda Mon_CH ; save current char pos
    pha
    ; clean up screen
    lda #$0
    sta Mon_CH
    .repeat 4
        jsr Mon_CLREOL
        inc Mon_CV
        jsr Mon_VTAB
    .endrepeat
    ; jump back to the line we were at
    ;
    lda Mon_CV
    sec
    sbc #4
    sta Mon_CV
    jsr Mon_BASCALC
    pla
    sta Mon_CH
    pla
    tax
    pla
    tay
    pla
    rts
.endif ; DEBUG

.export prDec16u_AY
prDec16u_AY:
    ; push X onto stack while preserving A (no PHX for 6502)
    ldx #$00
    stx saveIdx
@loop:
    ; divide A Y by 10
    jsr div10w_AY
    sta saveA ; preserve answer
    stx saveX
    lda saveIdx
    tax
    lda saveX
    ora #$B0
    sta digits, x ; store modulus in digits
    lda saveA
    ; if the division result is 0 then we're done
    bne @loopNext
    cpy #0
    beq @done
@loopNext:
    ; quotient !+ 0, we're not done. Increment and loop back!
    inx
    stx saveIdx
    bne @loop
@done:
    lda digits,x
    jsr Mon_COUT
    dex
    bpl @done
@rts:
    rts
saveX:
    .byte 0
saveA:
    .byte 0
saveIdx:
    .byte 0
digits:
    .byte 0,0,0,0,0
digitsEnd:

;; Pointer to string is on stack, highest byte most-recent.
;; Y register is an index into that string.
;; 
;; The number is assumed to be terminated by a
;; non-digit number.
;;   The 16-bit result will be placed on the stack,
;;   highest byte will pull first.
;;   
.export rdDec16u
rdDec16u:
    tya
    pha
    ; stack: strL strH <RET WORD> pushY (top)
    rollb1_ 5
    rollb1_ 5
    ;stack: <RET> pushY strL strH
    lda $0
    pha
    lda $1
    pha
    roll1_ 5
    roll1_ 5
    ;stack: <RET> z0 z1 pushY strL strH
    
    ; Now set up string in ZP
    pla
    sta $1
    pla
    sta $0
    
    ldy #$0
    sty @valueH
    sty @valueL
    
    pla
    tay ; now we have caller's original Y
@loop:
    lda ($0),y
    ; is it a digit?
    cmp #$B0 ; exit if < '0'
    bcc @nonDigit
    cmp #$BA ; or >= ':' (one past '9')
    bcs @nonDigit
    ; we have a digit. Convert to number
    and #$0f
    
    pha
    sty @index
    
    ; multiply value by 10
    lda @valueH
    ldy @valueL
    jsr mul10w_AY
    sta @valueH
    sty @valueL
    pla
    clc
    adc @valueL
    sta @valueL
    lda @valueH
    adc #$00 ; for carry
    sta @valueH    
    
    ldy @index
    iny
    bne @loop ; always
    
@nonDigit:
    pla
    sta $1
    pla
    sta $0
    
    ; exit with our value
    lda @valueL
    pha
    lda @valueH
    pha
    swapW_ ; swap so return addr on top
    ldy @index
    iny
    rts
@valueL:
    .byte 0
@valueH:
    .byte 0
@index:    
    .byte 0
