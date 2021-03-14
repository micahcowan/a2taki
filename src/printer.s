; printer.s
;
; Load this in to have a convenient way to play around with parsing

.macpack apple2

;Mon_COUT = $FDED
.import __TAKI_START__
Taki_Init = __TAKI_START__ + $03
Taki_COUT = __TAKI_START__ + $06

Init:
    ; Call Taki's init w/o installing to CSW
    JSR Taki_Init
    JMP Printer

    .res 8, $00

Printer:
    LDX #$00
    CLV
:   LDA TheString, X
    BEQ @Out
    JSR Taki_COUT
    INX
    BVC :-
@Out:
    RTS

    .res 16, $00

TheString:
    scrcode "Hello. There is some ", $12, "Fflashing", $12, " and "
    scrcode $12, "Iinverse", $12, " text here."
    .BYT $00
