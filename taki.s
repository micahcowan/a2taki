;;   Eventually: detect and save aside DOS/ProDOS processors
;;   so that we can detect Ctrl-D at beginning of line,
;;   and switch things over to DOS/ProDOS at that point

    .include "progstart.inc"

MON_COut = $FDF0
DOS_CSWL = $AA53
CSWL     = $36

.define TakiControlChar #$9A   ; Control-T (for "Taki")

.define ST_Init             #$00
.define ST_EffectName       #$01

;; Public interfaces ;;;;;;;;;;;;;;;;;;;

; The following calls are arranged in a stable order,
; so that users will always know where to call them, even if the
; "real" routines they jump to change location.
;
; Users should always use e.g. CallTakiPrint over TakiPrint,
; as TakiPrint's location could change from one version to another.
CallInit:
    JMP Init
CallTakiPrint:
    JMP TakiPrint

Init:
    ; Install for DOS 3.3 CSW
    ; (We will be called _by_ DOS's own CSW handler - there's no
    ; reasonable way to avoid this. It will do its own processinig,
    ; and Taki will get the lftovers.)
    ; TODO: support ProDOS, no-DOS (from tape)
    ; TODO: does the DOS_CSWL location depend on the memory in the
    ; machine (for e.g. a "master" DOS disk)?
    LDA #<TakiPrint
    STA DOS_CSWL
    LDA #>TakiPrint
    STA DOS_CSWL+1
    ; Install ROM CSW as the underlying print routine we pass along to
    LDA #<MON_COut
    STA vOurCSWL
    LDA #>MON_COut
    STA vOurCSWL+1

    ; Initialize processing state
    LDA ST_Init
    STA vState

    RTS

;; Vars
RunOurCSW:
    .byt $4C    ; JMP
vOurCSWL:
    .byt $00
    .byt $00

vState:
    .byt $00

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TakiPrint:
    CLD         ; ProDOS wants this in any user routine it calls
    ; Save A, X, Y
    PHA
    TXA
    PHA
    TYA
    PHA
    ; Restore A (which we saved a couple spaces back on stack)
    TSX
    INX ; Y
    INX ; X
    INX ; A
    LDA $100, X
    ; What state are we in?
    LDX vState
    ;BNE StateChk    ; TODO

    ; Zero. Default, pass-it-through state.
    ; ...Is the character our special control character?
    CMP TakiControlChar
    BNE CookedOutput
    ; It IS our special control. Enter effect name-parsing
    LDX ST_EffectName
    STX vState
    ; TODO initialize effect name buffer here
    ;JMP ParseEffectName
CookedOutput:
    JSR RunOurCSW
TakiPrintExit:
    PLA
    TAY
    PLA
    TAX
    PLA
    RTS
