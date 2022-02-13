;#resource "apple2.rom"
;#link "taki-startup.s"
;#link "taki-basic.s"
;#link "load-and-run-basic.s"
;#resource "taki.cfg"
;#define CFGFILE taki.cfg
;#resource "TAKI-TODO"

.macpack apple2

.define DEBUG	1

.include "taki-util.inc"
.include "a2-monitor.inc"

; Stable entry points table
.export PTakiMoveASoft
PTakiMoveASoft:
	jmp TakiMoveASoft
.export PTakiInit
PTakiInit:
	jmp TakiInit
.export PTakiPause
PTakiPause:
	jmp TakiPause
.export PTakiResume
PTakiResume:
	jmp TakiResume

.include "taki-debug.inc"
.include "taki-io.inc"

; Reorganize where in memory a BASIC program is
; located (to move it out of the way of the
; second text page - to $C01)
TakiMoveASoft:
	lda #$0C
        sta Mon_TEXTTAB+1
        sta Mon_VARTAB+1
        sta Mon_PRGEND+1
	rts

; Initialize Taki, hijacking input and output
; for special processing (and to send things to both
; text pages)
TakiInit:
	jsr TakiClearP2
	DebugPrint_ DbgInitMsg
        jmp TakiResume

.if DEBUG
DbgInitMsg:
	scrcode "TAKI STARTED", $0D
;	scrcode "THREE",$0D,"FOUR",$0D,"FIVE",$0D
	.byte $00
.endif

; Pause Taki I/O processing, restoring any
; previous I/O hooks. Mostly useful for talking
; to a DOS
TakiPause:
	rts

; Restore Taki I/O hooks, saving away current ones,
; resuming Taki processing 
TakiResume:
	lda #<TakiIn
        sta Mon_KSWL
        lda #>TakiIn
        sta Mon_KSWL+1
        lda #<TakiOut
        sta Mon_CSWL
        lda #>TakiOut
        sta Mon_CSWL+1
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
        