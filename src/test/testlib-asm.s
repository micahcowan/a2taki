;; Monitor zero-page locations
INVFLG  = $32
CSWL    = $36

COUT1   = $FDF0
HOME    = $FC58
RESET   = $FA62

_homePosition = HOME
.export _homePosition

.import _brkHandler, TakiInitNoInstall, TakiPrint
brkHandler = _brkHandler
_putcTaki = TakiPrint
.export _putcTaki

.CONSTRUCTOR InitFirmware

InitFirmware:
    ; Set up a BRK handler
    LDA #<brkHandler
    STA $FFFE
    LDA #>brkHandler
    STA $FFFF

    ; Run (patched) RESET code.
    JSR RESET

    ; Init Taki
    JMP TakiInitNoInstall

    ; RTS to caller

.SEGMENT "PATCHRESET"

    ;; This code gets run INSTEAD of the usual cold boot "check for disk"
    ;; stuff. We just skip over remaining initialization (including
    ;; setting up the "warm restart" vector) and clear the screen,
    ;; returning so that other "constructors", and then the test main()
    ;; routine, can have a go.

    JMP HOME    ; Clear the screen and then return from "constructor"
