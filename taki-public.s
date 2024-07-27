.segment "PUBLIC"

.include "a2-monitor.inc"

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

TakiPublic_ TakiInit
;  TakiPublic_ takes a name like TakiInit
;  and spits out code like:
;
;.export TakiInit
;TakiMoveASoft:
;       jmp _TakiInit

TakiPublic_ TakiBareInit

; Set to correct code by TakiInit/TakiBareInit
.export TakiIn
TakiIn:
    cld
.export _TakiInFn
_TakiInFn = * + 1
    jmp Mon_KEYIN

; Set to correct code by TakiInit/TakiBareInit
.export TakiOut
TakiOut:
    cld
.export _TakiOutFn
_TakiOutFn = * + 1
    jmp Mon_COUT1
    
TakiPublic_ TakiDelay

;TakiPublic_ TakiPause
.byte $60,$00,$00
;TakiPublic_ TakiResume
.byte $60,$00,$00
TakiPublic_ TakiExit

TakiPublic_ TakiReset

TakiPublic_ TakiDbgInit
TakiPublic_ TakiDbgExit
TakiPublic_ TakiDbgPrint
TakiPublic_ TakiDbgCOUT
TakiPublic_ TakiDbgPrintCmdBufWordAtY

TakiPublic_ TakiIoScreenOut
TakiPublic_ TakiIoFastOut
TakiPublic_ TakiIoFastPrintStr
TakiPublic_ TakiIoFastPrintSpace
TakiPublic_ TakiIoNextRandom
TakiPublic_ TakiIoRandWithinAY

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

; Init status: set to zero only if initialization
; and allocation succeeded.
.export TakiVarInitStatus
TakiVarInitStatus:
    .byte $FF

.export TakiVarEffectsAllocNumPages, TakiVarMaxActiveEffects
.export TakiVarDefaultCountdown
TakiVarEffectsAllocNumPages:
    .byte $10       ; default value
TakiVarMaxActiveEffects:
    .byte 32        ; default value
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
    


; If Taki's input processor detects it is at
; a prompt, *and* the current PROMPT
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

; READ-ONLY status flags variable that is copied from an internal one
; when effect processing is active
.export TakiVarStatusFlags
TakiVarStatusFlags:
    .byte $00

.ifndef TF_BEH_DETECT_HOME
TF_BEH_DETECT_HOME = 1
.endif

; Status flags that control Taki behaviors
.export TakiVarBehaviorFlags
TakiVarBehaviorFlags:
    .byte TF_BEH_DETECT_HOME

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

; 16-bit PRNG word. Must never be zero.
; A new number is produced (from the old) if
; TakiIoNextRandom is called.
.export TakiVarRandomWord
TakiVarRandomWord:
    .word $9471
