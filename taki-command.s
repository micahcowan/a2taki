TAKI_INTERNAL=1
.include "taki-public.inc"
I_AM_TAKI_CMD=1
.include "taki-internal.inc"

;; _TakiCmdFindWordEnd
;;
;; Expects ZP set up via TakiEffectDo_
;;
;; Jumps the y register to the end of the current word
;; in the command buffer - or sets y to 0 if no end found
;;
;; Uses acc, y
.export _TakiCmdFindWordEnd
_TakiCmdFindWordEnd:
@FindWordEnd:
	lda (kZpCmdBufL),y
        ; is it a terminator?
        beq @HaveTerminator	; NUL
        cmp #$8D		; CR
        beq @HaveTerminator
        cmp #$A0		; SP
        beq @HaveTerminator
        cmp #$A8		; '('
        beq @HaveTerminator
        ; no terminator - increment and check next char
        iny
        bne @FindWordEnd
@HaveTerminator:
	rts
