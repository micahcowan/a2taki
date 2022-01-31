;#link "taki-basic.s"
;#link "load-and-run-basic.s"
;#resource "taki.cfg"
;#define CFGFILE taki.cfg

.import LoadAndRunBasic

.include "taki-util.inc"

CHRGET	= $B1
CHRGOT	= $B7
AMPERV	= $3F5

.segment "STARTUP"
TakiStartup:
	jsr PTakiInit
	jmp LoadAndRunBasic
        
.segment "CODE"

; Stable entry points table
PTakiInit:
	jmp TakiInit

TakiKeyword:
	tstr "TAKI"
TakiCommands:
	tstr "LINE"
        .byte $00
TakiInit:
	; Initialize & to skip to end of line and RTS
        writeByte AMPERV, $4C;	"JMP"
        writeWord {AMPERV+1}, AmperHandle
        rts

AmperHandle:
	; Just skip until NUL byte
        cmp CHRGOT
        beq @done
:       jsr CHRGET
        bne :-
@done:	rts