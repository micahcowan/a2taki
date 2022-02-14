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
TakiPublic_ TakiExit
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

; Original (pre-Taki init) I/O routines
; (could be from PR#0, more likely from a DOS)
; saved away for restoration on exit
PTakiOrigCSW:
	.word $0000
PTakiOrigKSW:
	.word $0000

; If Taki's input processor detects that it was
; called from GETLN, *and* the current PROMPT
; is set to one of the following two values,
; then Taki will auto-exit and clean up.
;
; This is intended to detect if, say,
; a BASIC program has terminated (perhaps
; unexpectedly) and wound up at the AppleSoft
; prompt, or if a crash occured that brought us
; to the firmware monitor program.
;
; Set the second prompt value to $00 to only check
; the first prompt; set the first prompt to $00
; to disable prompt checks.
PTakiExitPrompts:
	.byte $DD
        .byte $AA
        
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
        ; save away CSW, KSW
        copyWord PTakiOrigCSW, Mon_CSWL
        copyWord PTakiOrigKSW, Mon_KSWL
        jmp TakiResume

; Pause Taki I/O processing, restoring any
; previous I/O hooks. Mostly useful for talking
; to a DOS
TakiPause:
        bit $C054	; force page one
	DebugUndrawBadge_
	copyWord Mon_CSWL, PTakiOrigCSW
        copyWord Mon_KSWL, PTakiOrigKSW
	rts

; Restore Taki I/O hooks, saving away current ones,
; resuming Taki processing 
TakiResume:
	writeWord Mon_KSWL, TakiIn
        writeWord Mon_CSWL, TakiOut
	rts

TakiExit:
	DebugExit_
        jsr TakiPause
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
        