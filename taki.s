;; Set up our CSW/output proceessor.
;;   Eventually: detect and save aside DOS/ProDOS processors
;;   so that we can detect Ctrl-D at beginning of line,
;;   and switch things over to DOS/ProDOS at that point

    .include "progstart.inc"

MON_COut = $FDF0
CSWL     = $36

TakiControlChar     = $9A   ; Control-T (for "Taki")

ST_Init             = $00
ST_EffectName       = $01

Init:
    ; Initialize processing state
    LDA #$00
    STA vState
    ; Install CSW
    LDA #<OutHook
    STA CSWL
    LDA #>OutHook
    STA CSWL+1
    ; Install ROM CSW as our underlying print routine
    LDA #<MON_COut
    STA vOurCSWL
    LDA #>MON_COut
    STA vOurCSWL+1
    RTS

;; Vars
RunOurCSW:
    .byt $4C	; JMP
vOurCSWL:
    .byt $00
    .byt $00

vState:
    .byt $00

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

OutHook:
    CLD         ; In case we ever want to be called by ProDOS I guess?
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
    CMP #TakiControlChar
    BNE CookedOutput
    ; It IS our special control. Enter effect name-parsing
    LDX #ST_EffectName
    STX vState
    ; TODO initialize effect name buffer here
    ;JMP ParseEffectName
CookedOutput:
    JSR RunOurCSW
OutHookExit:
    PLA
    TAY
    PLA
    TAX
    PLA
    RTS
