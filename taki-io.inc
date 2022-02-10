;; Taki character output/processing routine
TakiOut:
	jmp (Mon_CSWL)

;; Taki character input routine
TakiIn:
	jmp (Mon_KSWL)

YSAV1:
	.byte $00
TakiCOUT:
	cmp     #$a0
	bcc     COUTZ
	and     Mon_INVFLG
COUTZ:  sty     YSAV1
	pha
	jsr     VIDOUT
	pla
	ldy     YSAV1
	rts
;
STORADV:ldy     Mon_CH
	sta     (Mon_BASL),y
ADVANCE:inc     Mon_CH
	lda     Mon_CH
	cmp     Mon_WNDWDTH
	bcs     CR
RTS3:	rts
;
VIDOUT:	cmp     #$a0
	bcs     STORADV
	tay
	bpl     STORADV
	cmp     #$8d
	beq     CR
	cmp     #$8a
	beq     LF
	cmp     #$88
	bne     BELL1
	dec     Mon_CH
	bpl     RTS3
	lda     Mon_WNDWDTH
	sta     Mon_CH
	dec     Mon_CH
	lda     Mon_WNDTOP
	cmp     Mon_CV
	bcs     RTS4
	dec     Mon_CV
	lda     Mon_CV
	jsr     Mon_BASCALC
	adc     Mon_WNDLFT
	sta     Mon_BASL
RTS4:	rts

BELL1:	jmp	Mon_BELL1

CR:	lda     #$00
	sta     Mon_CH
LF:	inc     Mon_CV
	lda     Mon_CV
	cmp     Mon_WNDBTM
	bcc     VTABZ
	dec     Mon_CV
SCROLL:	lda     Mon_WNDTOP
	pha
	jsr     Mon_VTABZ
SCRL1:	lda     Mon_BASL
	sta     Mon_BAS2L
	lda     Mon_BASH
	sta     Mon_BAS2H
	ldy     Mon_WNDWDTH
	dey
	pla
	adc     #$01
	cmp     Mon_WNDBTM
	bcs     SCRL3
	pha
	jsr     Mon_VTABZ
SCRL2:	lda     (Mon_BASL),y
	sta     (Mon_BAS2L),y
	dey
	bpl     SCRL2
	bmi     SCRL1
SCRL3:	ldy     #$00
	jsr     CLEOLZ
	bcs     VTAB
CLREOL:	ldy     Mon_CH
CLEOLZ:	lda     #$a0
CLREOL2:sta     (Mon_BASL),y
	iny
	cpy     Mon_WNDWDTH
	bcc     CLREOL2
	rts

VTAB:	lda	Mon_CV
VTABZ:	jmp	Mon_VTABZ
