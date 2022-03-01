;; NONE effect
;;
;; This effect is not entered into the "built-in effects"
;; table, but is instead used whenever an effect name
;; can't be found.
;;
;; Just sends debug messages and silently collects
;; (and discards) input characters.

.macpack apple2

.export TE_NONE

.include "taki-effect.inc"
.include "a2-monitor.inc"
.include "taki-public.inc"
.include "taki-debug.inc"

.import TakiVarCommandBufferPage

TE_NONE:
	cmp #TAKI_DSP_INIT
        bne @rts
        ; Prepare command buffer for printing
	lda #$00
        sta kZpEffSpecial0
	lda TakiVarCommandBufferPage
        sta kZpEffSpecial1
        ldy #$00
@BufLoop:
	lda (kZpEffSpecial0),y
        beq @FoundEnd	; NUL
        cmp #$8D	; CR
        beq @FoundEnd
        cmp #$A8	; '('
        beq @FoundEnd	; none of the above? next char
@NextChar:
	iny
        jmp @BufLoop
@FoundEnd:
	lda #$00	; NUL-terminate
        sta (kZpEffSpecial0),y
        
        ; Display debug message
        TakiDbgPrint_ pEffNotFoundMsgPre
        TakiDbgPrint_ kZpEffSpecial0
        lda #$00
        ldy kZpEffSpecial1
        jsr TakiDbgPrint
        TakiDbgPrint_ pEffNotFoundMsgPost
@rts:	rts

pEffNotFoundMsgPre:
	scrcode "EFFECT NAME ",'"'
	.byte $00

pEffNotFoundMsgPost:
	scrcode '"'," NOT FOUND.",$0D,"IGNORING COLLECT.",$0D
	.byte $00
