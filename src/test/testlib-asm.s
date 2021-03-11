CSWL = $36

.import _brkHandler
brkHandler = _brkHandler

.CONSTRUCTOR InitFirmware

InitFirmware:
    ; Set up a BRK handler
    LDA #<brkHandler
    STA $FFFE
    LDA #>brkHandler
    STA $FFFF

    ; Set up COUT
    LDA #<COUT1
    STA CSWL
    LDA #>COUT1
    STA CSWL+1

    RTS

;;;;;;;;;; I/O Firmware ;;;;;;;;;;
;;
;; gets installed in key Apple 2 spots
;;

.segment "IOFIRM"

COUT:
    JMP (CSWL)
COUT1:
    BRK
