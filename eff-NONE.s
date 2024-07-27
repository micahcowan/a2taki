;; NONE effect
;;
;; This effect is not entered into the "built-in effects"
;; table, but is instead used whenever an effect name
;; can't be found.
;;
;; Just silently collects
;; (and discards) input characters.

.macpack apple2

.export TE_NONE

.include "taki-effect.inc"
.include "a2-monitor.inc"
.include "taki-public.inc"
.include "taki-debug.inc"

.import _TakiIoDoubledOut

.byte ""
.byte 0
.word 0
.word 0
TE_NONE:
    cmp #TAKI_DSP_COLLECT
    bne @gtfo
    ; COLLECT - print with inverse
    lda TAKI_ZP_ACC
    and #$3F
    jmp TakiIoFastOut
@gtfo:
    rts
