; Taki character output/processing routine
TakiOut:
	cld
	jmp TakiDoubledOut

SavedCursor:
	.byte $00
; Taki character input routine
; XXX: make this work with both text pages...
; XXX: does this work with //e cursors?
TakiIn:
KEYIN:	inc     Mon_RNDL
	bne     KEYIN2
	inc     Mon_RNDH
KEYIN2:	bit     SS_KBD             ;read keyboard
	bpl     KEYIN
        ; keypress available.
        ; save cursor away in case
        pha
        lda	(Mon_BASL),y
        sta	SavedCursor
        pla
        ; overwrite cursor with correct cell in A
	sta     (Mon_BASL),y
	lda     SS_KBD
        bit	SS_KBDSTRB
.if DEBUG
        cmp	#$AF	; '/'
        bne	NoFS
        bit	$C055
        jmp	RestoreCursor
NoFS:	cmp	#$DC	; '\'
        bne	NoBS
        bit	$C054
        jmp	RestoreCursor
.endif ; DEBUG
NoBS:	cmp #$9B	; ESC
        bne NoESC
        jmp RestoreCursor
NoESC:	rts
RestoreCursor:
	lda (Mon_BASL),y
        lda SavedCursor
        sta (Mon_BASL),y
        jmp KEYIN

Saved_CH:
	.byte $00
Saved_CV:
	.byte $00
Saved_BASL:
	.byte $00, $00
        
; Taki's standard COUT-assigned routine.
; Prints to both text pages at once, and
; checks for Taki control character
TakiDoubledOut:
	cld
	; Save CH, CV, BASL/H
        pha
        lda Mon_CH
        sta Saved_CH
        lda Mon_CV
        sta Saved_CV
        lda Mon_BASL
        sta Saved_BASL
        lda Mon_BASH
        sta Saved_BASL+1
        pla
        
        ; Do p1 COUT
        jsr TakiCOUT
        
        ; Restore CH, CV, BASL/H
        pha
        lda Saved_CH
        sta Mon_CH
        lda Saved_CV
        sta Mon_CV
        lda Saved_BASL
        sta Mon_BASL
        lda Saved_BASL+1
        clc
        adc #04		; fix up for pg 2
        sta Mon_BASH
        ; and set BASCALC
        lda #<TakiBASCALC_pageTwo
        sta BASCALCfn
        lda #>TakiBASCALC_pageTwo
        sta BASCALCfn+1
	pla
        ; Do p2 COUT
        ; NOTE: should arrive at same values for CH, CV again...
        jsr TakiCOUT
        ; Fix up BASL, and BASLCALC
        pha
        sec
        lda Mon_BASH
        sbc #04		; fix up for pg 1 again
        sta Mon_BASH
        lda #<TakiBASCALC_pageOne
        sta BASCALCfn
        lda #>TakiBASCALC_pageOne
        sta BASCALCfn+1
        pla
        rts
        
TakiBASCALC:
BASCALCfn = TakiBASCALC + 1
	jmp TakiBASCALC_pageOne ; actual addr overwritten

TakiBASCALC_pageOne = Mon_BASCALC

; Same as monitor BASCALC, but calc for page 2 instead
TakiBASCALC_pageTwo:
	pha
	lsr
	and     #$03
	ora     #$08	; page two
	sta     Mon_BASH
	pla
	and     #$18
	bcc     :+
	adc     #$7f
:	sta     Mon_BASL
	asl
        asl
	ora     Mon_BASL
	sta     Mon_BASL
	rts

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
	rts
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
	bpl     RTS4
	lda     Mon_WNDWDTH
	sta     Mon_CH
	dec     Mon_CH
	lda     Mon_WNDTOP
	cmp     Mon_CV
	bcs     RTS4
	dec     Mon_CV
	lda     Mon_CV
	jsr     TakiBASCALC
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
	jsr     VTABZ
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
	jsr     VTABZ
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
VTABZ:	jsr     TakiBASCALC
	adc     Mon_WNDLFT
	sta     Mon_BASL
	rts

TakiClearP2:
	lda $06
        pha
        lda $07
        pha
        tya
        pha
        txa
        pha
        
        lda #$00
        sta $06
        lda #$08
        sta $07
        lda #$A0
@nextPg:ldy #0
:	sta ($06),y
        iny
        bne :-
        inc $07
        ldx $07
        cpx #$0C
        bne @nextPg
        
        pla
        tax
        pla
        tay
        pla
        sta $07
        pla
        sta $06
	rts
	