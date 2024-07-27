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

.ifndef FORTHISH_INC_
FORTHISH_INC_ = 1

.macro maybe_import name
  .ifndef FORTHISH_NO_IMPORT
    .import name
  .endif
.endmacro

;; dup_
;;
;; duplicate the top byte of the stack
.macro dup_
    pla
    pha
    pha
.endmacro

;; swap_
;;
;; swaps the top two bytes of the stack.
.macro swap_
    pla
    tay
    pla
    tax
    
    tya
    pha
    txa
    pha
.endmacro

;; swapXY_
;;
;; swaps the byte at stack position marked by register X
;; with the byte at stack position marked by register Y
;;
;; Example:
;;  Stack: A (X:)B C (Y:)D E
;;  swapXY_
;;  Stack: A (X:)D C (Y:)B E
.macro swapXY_
    lda $100,x
    pha
    lda $100,y
    sta $100,x
    pla
    sta $100,y
.endmacro

;; swapW_
;;
;; swaps the top two WORDS of the stack.
.macro swapW_
    tsx
    inx
    txa
    tay
    iny
    iny
    swapXY_
    inx
    iny
    swapXY_
.endmacro

;; pick_ N
;;
;; place a copy of the N-1st byte from top-of-stack
;; on the top of the stack. If M is specified,
;; copies M bytes back from that location, to the stack top.
.macro pick_ N, M
.scope
    .ifnblank M
      _M = M
    .else
      _M = 1
    .endif
    num = N+_M-1
    tsx
    .if num <= 5
      .repeat num
        inx
      .endrepeat
    .else
      txa
      clc
      adc #num
      tax
    .endif
    lda $101,x
    pha
    .if _M > 1
      .repeat _M-1
        dex
        lda $101,x
        pha
      .endrepeat
    .endif
.endscope
.endmacro

;; rot_
;;
;; Rotate the top 3 items of the stack one forward.
;; Equivalent to roll1 N, but faster.
.macro rot_
    tsx
    dup_
    lda $102,x
    sta $101,x
    lda $103,x
    sta $102,x
    pla
    sta $103,x
.endmacro

;; rotb_
;;
;; Rotate the top 3 items of the stack back one.
;; Very useful for getting at something that was
;; pushed just prior to a JSR.
.macro rotb_
    tsx
    dup_
    lda $103,x
    sta $101,x
    lda $102,x
    sta $103,x
    pla
    sta $102,x
.endmacro

;; roll1_ N
;;
;; Roll the top N bytes of the stack forward by one, wrapping
;; the topmost byte N-1 spaces back.
;;
;; Example:
;;  Stack: A B C D E (top of stack)
;;  roll_ 4
;;  Stack: A E B C D
maybe_import roll1
maybe_import roll1A
.macro roll1_ N
    lda #N
    jsr roll1A
.endmacro

;; rollb1_ N
;;
;; Roll the top N bytes of the stack back by one, wrapping
;; the backmost byte to the front
;;
;; Example:
;;  Stack: A B C D E (top of stack)
;;  roll_ 4
;;  Stack: A C D E B
maybe_import rollb1
maybe_import rollb1A
.macro rollb1_ N
    lda #N
    jsr rollb1A
.endmacro

;; copy_ N
;;
;; Roll the top N bytes of the stack back by one, wrapping
;; the backmost byte to the front
;;
;; Example:
;;  Stack: A B C D E (top of stack)
;;  roll_ 4
;;  Stack: A C D E B
maybe_import copy
maybe_import copyA
.macro copy_ N
    lda #N
    jsr copyA
.endmacro

.delmacro maybe_import

.endif ; FORTHISH_INC_
