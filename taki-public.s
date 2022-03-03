.segment "PUBLIC"

I_AM_TAKI_PUBLIC=1
.include "taki-internal.inc"

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
TakiPublic_ TakiDbgPrintCmdBufWordAtY

TakiPublic_ TakiIn
TakiPublic_ TakiOut
TakiPublic_ TakiDelay
TakiPublic_ TakiIoPageTwoBasCalc
TakiPublic_ TakiIoClearPageTwo
TakiPublic_ TakiIoDoubledOut

TakiPublic_ TakiMySetCounter
TakiPublic_ TakiMyGetCounter
TakiPublic_ TakiMySetCounterInit
TakiPublic_ TakiMyGetCounterInit


;;;;; PUBLIC VARIABLES AND FLAGS

TakiPubFnEnd:

; Guarantee that they begin at START + $80
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
.export TakiVarCommandBufferPage
TakiVarEffectsAllocStartPage:
	.byte $00
TakiVarEffectsAllocEndPage:
	.byte $00
TakiVarCommandBufferPage:
	.byte $00
        

; Original (pre-Taki init) I/O routines
; (could be from PR#0, more likely from a DOS)
; saved away for restoration on exit
.export TakiVarOrigCSW, TakiVarOrigKSW
TakiVarOrigCSW:
	.word $0000
TakiVarOrigKSW:
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

; READ-ONLY flags variable that is copied from an internal one
; when effect processing is active
.export TakiVarFlags
TakiVarFlags:
	.byte $00

; TakiVarTickNum: incrmented just prior to each tick/untick.
; useful for an effect to coordinate something across its
; multiple instances (like the XXX flasher)
.export TakiVarTickNum
TakiVarTickNum:
	.byte $00

; TakiVarDispatchEvent: set before calling an effect
; dispatch handler, to designate what the event is.
; This info is also communicated via the accumulator to
; the dispatch handler; but this var is used internally
; while the accumulator and stack are used for other things,
; and exposed here publicly for convenience
.export TakiVarDispatchEvent
TakiVarDispatchEvent:
	.byte $00
