.import LoadAndRunBasic
.import PTakiMoveASoft

.segment "STARTUP"
TakiStartup:
	lda #20	; reserve 4 lines at scr bottom
        sta $23
	jsr PTakiMoveASoft
	jmp LoadAndRunBasic
