; printer.s
;
; Load this in to have a convenient way to play around with parsing

.macpack apple2

Mon_COUT = $FDED

    .org $300

Printer:
    LDX #$00
    CLV
:   LDA TheString, X
    BEQ @Out
    JSR Mon_COUT
    INX
    BVC :-
@Out:
    RTS

    .res 16

TheString:
    scrcode "Hello. There is some ", $12, "Fflashing", $12, " and "
    scrcode $12, "Iinverse", $12, " text here."
    .BYT $00
