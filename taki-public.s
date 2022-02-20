.segment "PUBLIC"

.import _TakiMoveASoft, _TakiInit, _TakiPause, _TakiResume, _TakiExit

.import _TakiIn, _TakiOut, _TakiIoPageTwoBasCalc, _TakiIoClearPageTwo
.import _TakiIoDoubleDo, _TakiIoDoubledOut

.import _TakiDbgInit, _TakiDbgExit, _TakiDbgPrint, _TakiDbgCOUT
.import _TakiDbgUndrawBadge, _TakiDbgDrawBadge

.export TakiStart
TakiStart:

.macro TakiPublic_ subname
        .export subname
        subname:
        jmp .ident(.concat("_", .string(subname)))
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
;.export TakiMoveASoft
;TakiMoveASoft:
;	jmp _TakiMoveASoft

TakiPublic_ TakiInit
;TakiPublic_ TakiPause
.byte $60,$00,$00
;TakiPublic_ TakiResume
.byte $60,$00,$00
TakiPublic_ TakiExit

TakiPublic_ TakiDbgInit
TakiPublic_ TakiDbgExit
TakiPublic_ TakiDbgPrint
TakiPublic_ TakiDbgCOUT
TakiPublic_ TakiDbgUndrawBadge
TakiPublic_ TakiDbgDrawBadge

TakiPublic_ TakiIn
TakiPublic_ TakiOut
TakiPublic_ TakiIoPageTwoBasCalc
TakiPublic_ TakiIoClearPageTwo
TakiPublic_ TakiIoDoubleDo
TakiPublic_ TakiIoDoubledOut


;;;;; PUBLIC VARIABLES AND FLAGS

; Guarantee that they begin at $8080
TakiPubFnEnd:

.res TakiStart + $80 - *

TakiVarsStart:

; Release version: if high bit of first byte is
; set, this is an unstable/unreleased version
.export TakiVarReleaseVersion
TakiVarReleaseVersion:
	.byte $FF, $FF

.export TakiVarEffectsAllocNumPages, TakiVarMaxActiveEffects
.export TakiVarDefaultCountdown
TakiVarEffectsAllocNumPages:
	.byte $10	; default value
TakiVarMaxActiveEffects:
	.byte 32	; default value
TakiVarDefaultCountdown:
	.word $0012

.export TakiVarEffectsAllocStartPage, TakiVarEffectsAllocEndPage
TakiVarEffectsAllocStartPage:
	.byte $00
TakiVarEffectsAllocEndPage:
	.byte $00
        

; Original (pre-Taki init) I/O routines
; (could be from PR#0, more likely from a DOS)
; saved away for restoration on exit
.export TakiVarOrigCSW, TakiVarOrigKSW
TakiVarOrigCSW:
	.word $0000
TakiVarOrigKSW:
	.word $0000

; Is debug mode active?
.export TakiVarDebugActive
TakiVarDebugActive:
    .byte $00

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
.export TakiVarExitPrompts
TakiVarExitPrompts:
	.byte $DD
        .byte $AA
        
; A convenience routine: store an address
; at TakiIndirectFn, then JSR to TakiIndirect.
; A workaround for 6502's lack of indirect JSR
; (this is in "flags and variables" because
; a user doesn't call it, only writes to TakVariIndirectFn)
.export _TakiIndirect
_TakiIndirect:
.export TakiVarIndirectFn
TakiVarIndirectFn = _TakiIndirect + 1
	jmp $1000 ; addr overwritten by caller
.export TakiVarInGETLN
TakiVarInGETLN:
	.byte $00 ; set to $FF when TakiIn
                  ; called from GETLN


; TakiVarCurPageBase: contains $04 if page one is the
; currently shown page, $08 if page two.
; TakiVarNextPageBase: reverse of the above.
	.byte $00
.export TakiVarCurPageBase
TakiVarCurPageBase:
	.byte $04
	.byte $00
.export TakiVarNextPageBase
TakiVarNextPageBase:
	.byte $08

.export TakiVarTicksPaused
TakiVarTicksPaused:
	.byte $00
