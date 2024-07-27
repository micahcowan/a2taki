;; Forthish.inc
;;   minimal Forth-like stack operation macros for 6502
;;
;; Copyright © 2022-2024  Micah J Cowan
;; All rights reserved
;;
;; Permission is hereby granted, free of charge, to any
;; person obtaining a copy of this software and associated
;; documentation files (the "Software"), to deal in the Software
;; without restriction, including without limitation the rights
;; to use, copy, modify, merge, publish, distribute, sublicense,
;; and/or sell copies of the Software, and to permit persons to
;; whom the Software is furnished to do so, subject to the
;; following conditions:
;;
;; The above copyright notice and this permission notice shall
;; be included in all copies or substantial portions of the
;; Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
;; KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE 
;; WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
;; PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS
;; OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
;; OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
;; OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
;; SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

FORTHISH_NO_IMPORT=1
.include "forthish.inc"

.export roll1, roll1A
roll1:
    ; on stack: number of items to roll
    ;           <16-bit return address>
    rotb_ ; get N past return address
    pla
roll1A:
    sta @adc+1 ; use N to adjust stack ptr in X later
    tsx
    inx ; skip return address
    inx
    stx @cpx+1 ; use to determine when we're done
    txa
    clc
@adc:
    adc #$00 ; overwritten above, to skip N bytes
    tay ; Y is at "bottom" of roll
    tax
    dex ; X is one "up" from there
@loop:
@cpx:
    cpx #$00 ; overwritten above
    beq @finish
    swapXY_
    dex
    jmp @cpx
@finish:
    rts

.export rollb1, rollb1A
rollb1:
    ; on stack: number of items to roll
    ;           <16-bit return address>
    rotb_ ; get N past return address
    pla
rollb1A:
    sta @adc+1 ; use N to adjust stack ptr in X later
    tsx
    inx ; skip return address
    inx
    txa
    inx ; X is at bottom
    clc
@adc:
    adc #$00 ; overwritten above, to skip N bytes
    sta @cpx+1 ; use to determine when we're done
    tay ; Y is at "top" of roll
@loop:
@cpx:
    cpx #$00 ; overwritten above
    beq @finish
    swapXY_
    inx
    jmp @cpx
@finish:
    rts

.export copy, copyA
copy:
    rotb_ ;get N past the return address
    pla
copyA:
    sta @adc+1
    ; move our return address out of the way
    pla
    sta @finish+4
    pla
    sta @finish+1
    ;
    tsx
    stx @cpx+1
    txa
    clc
@adc:
    adc #$00 ; overwritten above
    tax
@lp:
    lda $100,x
    pha
    dex
@cpx:
    cpx #$00 ; overwritten above
    bne @lp
@finish:
    lda #$00 ; overwritten
    pha
    lda #$00 ; overwritten
    pha
    rts
