;#link "taki-startup.s"
;#link "taki-cout.s"
;#link "taki-basic.s"
;#link "load-and-run-basic.s"
;#resource "taki.cfg"
;#define CFGFILE taki.cfg

.include "taki-util.inc"

CSWL	= $36
TEXTTAB	= $67
VARTAB	= $69
PRGEND	= $AF
CHRGET	= $B1
CHRGOT	= $B7

; Stable entry points table
PTakiMoveASoft:
	jmp TakiMoveASoft
PTakiInit:
	jmp TakiInit

; Reorganize where in memory a BASIC program is
; located (to move it out of the way of the
; second text page - to $C01)
TakiMoveASoft:
	lda #$0C
        sta TEXTTAB+1
        sta VARTAB+1
        sta PRGEND+1
	rts

; Initialize Taki, hijacking input and output
; for special processing (and to send things to both
; text pages)
TakiInit:
	; Initialize & to skip to end of line and RTS
        rts

.if 0
; not done writing this fn
PrintStr:
PrintStrAddr = PrintStr+1
	lda #1000	; Overwritten before call.
        		; Load next str char. Is NUL?
        beq PSDone	; yes: exit
PSDone: rts
.endif
        