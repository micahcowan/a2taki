.macro DebugPrint_ strAddr
  .if DEBUG
    pha
    writeWord DebugPrintStr, strAddr
    jsr DebugPrint
    pla
  .endif
.endmacro

.macro DebugInit_
  .if DEBUG
    jsr DebugInit
  .endif
.endmacro

.if DEBUG

DebugNumLines	= 4 ; # lines to reserve at scr btm
DebugNumRegLines= 24 - DebugNumLines

DebugInit:
	; If CV is in the reserved area, scroll
        ; up (scrolling cursor along) until
        ; it's not.
@ScrollCheck:
        lda Mon_CV
	cmp #DebugNumRegLines
        bcc @DoneScrolling
        sbc #1	; carry is set/"borrow clear"
        sta Mon_CV
        jsr Mon_SCROLL	; use monitor's because
        		; pg 2 already clear
        jmp @ScrollCheck
@DoneScrolling:
	; Clear lines at screen bottom
	lda #(24 - DebugNumLines)
@ClrLoop:
	cmp #24 ; total lines in screen
        bcs @ClrDone
        pha
        jsr Mon_VTABZ
        ldy #0
        jsr Mon_CLEOLZ
        pla
        adc #0 ; carry is set, so "+ 1"
        jmp @ClrLoop
@ClrDone:
	jsr Mon_VTAB
        ; Reserve lines at scr bottom
	lda #(24 - DebugNumLines)
        sta Mon_WNDBTM
        ; Print start msg
        DebugPrint_ DbgInitMsg
        rts

DbgInitMsg:
	scrcode "TAKI START", $0D
;	scrcode "TWO",$0D,"THREE",$0D,"FOUR",$0D,"FIVE",$0D
;	scrcode "SIX",$0D,"SEVEN",$0D
        .byte $00


DebugPrint:
	jsr DebugPrSetup
DebugPrintStr = * + 1
@Loop:	lda $1000
	beq @Done
        jsr Mon_COUT
        inc DebugPrintStr
        bne @Loop
        inc DebugPrintStr+1
        bne @Loop
@Done:
	jmp DebugPrTeardown

DebugCOUT:
	bit DebugDoCrNext
	beq @NoPendCR	; Pending CR? no: check
        pha		; for current CR. yes: emit CR
	lda #$8D
        jsr TakiOut
        lda #$00 ; un-pend CR
        sta DebugDoCrNext
        pla
@NoPendCR:
	cmp #$8D	; current CR?
        bne @DoOutput	; no: just do output
        sta DebugDoCrNext ; yes: save it and exit
        rts
@DoOutput:
        sta DebugSavedChar
        lda Mon_INVFLG; save invflag
        pha
        lda #$3F ; Set inverse
        sta Mon_INVFLG
        lda DebugSavedChar
	jsr TakiOut
        pla
        sta Mon_INVFLG
        lda DebugSavedChar
        rts

DebugSavedChar:
	.byte $00
DebugSavedCSW:
	.word $0000
DebugSavedWNDBTM:
	.byte $00
DebugSavedWNDTOP:
	.byte $00
DebugSavedCV:
	.byte $00
DebugSavedCH:
	.byte $00
DebugCH:
	.byte $00
DebugDoCrNext:
	.byte $FF
DebugPrSetup:
        copyWord DebugSavedCSW, Mon_CSWL
        writeWord Mon_CSWL, DebugCOUT
        lda Mon_WNDBTM
        sta DebugSavedWNDBTM
        lda Mon_WNDTOP
        sta DebugSavedWNDTOP
        lda Mon_CH
        sta DebugSavedCH
        lda Mon_CV
        sta DebugSavedCV
        lda #DebugNumRegLines
        sta Mon_WNDTOP
        lda #24 ; total # lines on screen
        sta Mon_WNDBTM
        lda #23 ; last line #
        sta Mon_CV
        lda DebugCH
        sta Mon_CH
        jsr Mon_VTAB
        rts

DebugPrTeardown:
	copyWord Mon_CSWL, DebugSavedCSW
        lda Mon_CH
        sta DebugCH
        lda DebugSavedWNDBTM
        sta Mon_WNDBTM
        lda DebugSavedWNDTOP
        sta Mon_WNDTOP
        lda DebugSavedCH
        sta Mon_CH
        lda DebugSavedCV
        sta Mon_CV
        jsr Mon_VTAB
        rts

.endif ; DEBUG