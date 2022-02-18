.segment "PUBLIC"

.import TakiMoveASoft, TakiInit, TakiPause, TakiResume, TakiExit

.import TakiIn, TakiOut, TakiBASCALC_pageTwo, TakiClearPage2
.import TakiDoubleDo, TakiDoubledOut

TakiStart:

.macro TakiPublic_ subname
	.export .ident(.concat("P", .string(subname)))
	.ident(.concat("P", .string(subname))):
        jmp subname
.endmacro

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

; Release version: if high bit of first byte is
; set, this is an unstable/unreleased version
.export PTakiReleaseVersion
PTakiReleaseVersion:
	.byte $FF, $FF

; Original (pre-Taki init) I/O routines
; (could be from PR#0, more likely from a DOS)
; saved away for restoration on exit
.export PTakiOrigCSW, PTakiOrigKSW
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
.export PTakiExitPrompts
PTakiExitPrompts:
	.byte $DD
        .byte $AA
        
; A convenience routine: store an address
; at TakiIndirectFn, then JSR to TakiIndirect.
; A workaround for 6502's lack of indirect JSR
; (this is in "flags and variables" because
; a user doesn't call it, only writes to PTakiIndirect
.export TakiIndirect
TakiIndirect:
.export PTakiIndirectFn
PTakiIndirectFn = TakiIndirect + 1
	jmp $1000 ; addr overwritten by caller
.export PTakiInGETLN
PTakiInGETLN:
	.byte $00 ; set to $FF when TakiIn
                  ; called from GETLN


; PTakiCurPageBase: contains $04 if page one is the
; currently shown page, $08 if page two.
; PTakiNextPageBase: reverse of the above.
	.byte $00
.export PTakiCurPageBase
PTakiCurPageBase:
	.byte $04
	.byte $00
.export PTakiNextPageBase
PTakiNextPageBase:
	.byte $08

.export PTakiTicksPaused
PTakiTicksPaused:
	.byte $00
