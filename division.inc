.ifndef MATH_DIVISION_
MATH_DIVISION_ = 1

.ifndef DIVISION_WORK_AREA
DIVISION_WORK_AREA = $9D
.endif

locDividend   = DIVISION_WORK_AREA
locDivisor    = locDividend + 4
locQuotient   = locDivisor + 4
locRemainder  = locQuotient + 4
whichQuotByte = locRemainder + 4
quotShift     = whichQuotByte + 1

.macro makeDivisionRoutine BYTES
.scope
BYTES_DEND = BYTES
BYTES_DSOR = BYTES
BYTES_QUOT = BYTES_DEND
BYTES_REM  = BYTES_DEND
    ; * First, clear quotient and remainder
    ; NOTE: assumes they're sequential, with quotient first
    lda #0
    ldx #BYTES_QUOT
@clrQuo:
    sta locQuotient-1,x
    dex
    bne @clrQuo
    ldx #BYTES_REM
@clrRem:
    sta locRemainder-1,x
    dex
    bne @clrRem
    sta whichQuotByte
@resetQuotShift:
    lda #$80
    sta quotShift
@dendShiftStart:
    ; * shift top bit of dividend onto bottom of remainder
    ldx #(BYTES_DEND - 1)
    ; XXX we could avoid extra shifting as we reach byte
    ;  thresholds
    clc
@dendShift:
    rol locDividend,x
    dex
    bpl @dendShift
    ; Now onto quotient bottom-end
    ; XXX We could avoid extra shifting as we reach byte
    ;  thresholds
    ldx #(BYTES_REM - 1)
@remShift:
    rol locRemainder,x
    dex
    bpl @remShift
    ; * Compare "remainder" (top portion dividend)
    ;   with divisor
    ; XXX We could avoid extra comparisons on leading
    ;  zero bytes *if we're careful to include an extra byte
    ;  from remainder, when borrow is set
    ldx #(BYTES_REM -1)
    sec ; clear borrow
@cmpRem:
    lda locRemainder,x
    sbc locDivisor,x ; XXX what if we want divisor bytes diff from dividend/rem?
    pha
    dex
    bpl @cmpRem
    ; Was the remainder ultimately greater than or equal to the divisor?
    bcs @doSub ; it was - record the subtraction, and mark "1"
    ; -> no; throw away the subtraction and shift again
    .repeat BYTES_REM
    pla
    .endrepeat
@shifter:
    lsr quotShift
    bcc @dendShiftStart ; -> set bit still in byte
    ; set bit rolled off, rol it onto "next" byte
    inc whichQuotByte
    lda whichQuotByte
    cmp #BYTES_QUOT
    bne @resetQuotShift
    ; we've finished the quotient!
    ; *** END ***
    rts
@doSub:
    ldx #0
@subLo:
    ; Make "real" the subtraction we just did
    pla
    sta locRemainder,x
    inx
    cpx #BYTES_REM
    bne @subLo
    ; Mark that divisor went into "remainder" (top end of divisor)
    ldx whichQuotByte
    lda locQuotient,x
    eor quotShift
    sta locQuotient,x
    bne @shifter; always
.endscope
.endmacro

.endif ; MATH_DIVISION_
