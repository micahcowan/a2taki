.import LoadAndRunBasic
.import PTakiMoveASoft

.segment "STARTUP"
TakiStartup:
    ldx #$FF
    txs
    jmp LoadAndRunBasic
