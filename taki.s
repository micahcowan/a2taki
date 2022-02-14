;#resource "apple2.rom"
;#link "taki-startup.s"
;#link "taki-basic.s"
;#link "load-and-run-basic.s"
;#resource "taki.cfg"
;#define CFGFILE taki.cfg
;#resource "TAKI-TODO"

.macpack apple2

.define DEBUG	1

TakiStart:

.include "taki-util.inc"
.include "a2-monitor.inc"

;;;;; PUBLIC FUNCTION ENTRY POINTS
; Stable entry points table, so that programs
; have a "known" offset they can use to call
; a routine, that will not change
; across releases.

TakiPublic_ TakiMoveASoft
;  TakiPublic_ takes a name like TakiMoveASoft
;  and spits out code like:
;
;.export PTakiMoveASoft
;PTakiMoveASoft:
;	jmp TakiMoveASoft

TakiPublic_ TakiInit
TakiPublic_ TakiPause
TakiPublic_ TakiResume
TakiPublic_ TakiIn
TakiPublic_ TakiOut
;
.export PTakiPageTwoBasCalc
PTakiPageTwoBasCalc:
 	jmp TakiBASCALC_pageTwo
;
TakiPublic_ TakiClearPage2
TakiPublic_ TakiDoubleDo
TakiPublic_ TakiDoubledOut


;;;;; PUBLIC VARIABLES AND FLAGS

; Guarantee that they begin at $8080
TakiPubFnEnd:

.res TakiStart + $80 - *

TakiFlagsStart:
; A convenience routine: store an address
; at TakiIndirectFn, then JSR to TakiIndirect.
; A workaround for 6502's lack of indirect JSR
; (this is in "flags and variables" because
; a user doesn't call it, only writes to PTakiIndirect
TakiIndirect:
PTakiIndirectFn = TakiIndirect + 1
	jmp $1000 ; addr overwritten by caller
PTakiInGETLN:
	.byte $00 ; set to $FF when TakiIn
                  ; called from GETLN

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
	jsr TakiClearPage2
        DebugInit_
        jmp TakiResume

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
        