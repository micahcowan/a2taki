.export TakiDoubleDo, TakiDoubledOut, TakiClearPage2
.export TakiBASCALC_pageTwo, TakiOut, TakiIn

.include "a2-monitor.inc"
.include "taki-debug.inc"

.import DebugInit, DebugExit, DebugPrint, DebugPrintStr, DebugDrawBadge, DebugUndrawBadge
.import PTakiIndirectFn, TakiTick, TakiExit, PTakiExitPrompts
.import PTakiInGETLN, TakiIndirect

.macpack apple2

; Call a function twice, once with BAS -> pg 1,
; and once with BAS -> pg 2.
;
; To invoke, first write the addr of the fn
; you want called for each page to PTakiIndirectFn,
; then jsr TakiDoubleDo.
TakiDoubleDo:
	; Save CH, CV, BASL/H
        pha
        lda Mon_CH
        sta Saved_CH
        lda Mon_CV
        sta Saved_CV
        lda Mon_BASL
        sta Saved_BAS
        lda Mon_BASH
        sta Saved_BAS+1
        pla
        
        ; Do p1 job
        jsr TakiIndirect
        
        ; Restore CH, CV, BASL/H
        pha
        lda Saved_CH
        sta Mon_CH
        lda Saved_CV
        sta Mon_CV
        lda Saved_BAS
        sta Mon_BASL
        lda Saved_BAS+1
        clc
        adc #04		; fix up for pg 2
        sta Mon_BASH
        ; and set BASCALC
        lda #<TakiBASCALC_pageTwo
        sta BASCALCfn
        lda #>TakiBASCALC_pageTwo
        sta BASCALCfn+1
	pla
        ; Do p2 job
        jsr TakiIndirect
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

; Taki character output/processing routine
TakiOut:
	jmp TakiDoubledOut

.if DEBUG
PromptExitStr:
	scrcode "!!EXIT VIA PROMPT DETECTED!!",$0D
        .byte $00
.endif

SavedCursor:
	.byte $00
SavedRealChar:
	.byte $00
; Taki character input routine
; XXX: make this work with both text pages...
; XXX: does this work with //e cursors?
TakiIn:
        ; save real char
        sta SavedRealChar
	jsr TakiCheckForGETLN
        bit PTakiInGETLN	; are we in GETLN?
        bpl @NotExited		; no, skip ahead
        cpx #00			; yes: are we in 2nd column?
        bne @NotExited		; no, no further checks
        lda PTakiExitPrompts	; yes, check ] prompt
        beq @NotExited		; prompt check disabled!
        cmp Mon_PROMPT		; PROMPT = ] (or P1)?
        beq @Exited		; yes so exited.
        lda PTakiExitPrompts+1
        beq @NotExited		; 2nd prompt disabled
        cmp Mon_PROMPT		; PROMPT = * (or P2)?
        bne @NotExited		; no, not exited
@Exited:lda SavedRealChar
	sta (Mon_BASL),y
	DebugPrint_ PromptExitStr
	jsr TakiExit
	lda SavedRealChar
        jmp Mon_GETLN		; hand control to
        			;  pre-Taki I/O processor
@NotExited:
        ; save $6, $7, use for BAS + $400
        lda $6
        pha
        lda $7
        pha
        lda Mon_BASL
        sta $6
        lda Mon_BASH
        and #($FF - $4)
        ora #$08
        sta $7
        
        ; save cursor, and set it on pg 2 as well
        lda (Mon_BASL),y
        sta SavedCursor
        sta ($06),y
KEYIN:	inc     Mon_RNDL
	bne     KEYIN2
	inc     Mon_RNDH
        jsr TakiTick
KEYIN2:	bit     SS_KBD             ;read keyboard
	bpl     KEYIN
        ; keypress available.
	lda     SS_KBD
        bit	SS_KBDSTRB
.if DEBUG
        cmp	#$AF	; '/'
        bne	NoFS
        bit	$C055
        jmp	KEYIN
NoFS:	cmp	#$DC	; '\'
        bne	NoBS
        bit	$C054
        jmp	KEYIN
.endif ; DEBUG
NoBS:	cmp #$9B	; ESC - skip and get new keypress
        bne NoESC
        jmp KEYIN
NoESC:  ; If GETLN gets a CR on input, it
	; clears to the end of the line, but
        ; since it doesn't use CSW to do this,
        ; it'll only happen in page one.
        ; So, as a hacky workaround, we check
        ; to see if we were called from GETLN
        ; and perform CLREOL in both pages if so.
	cmp #$8D	; CR - clear to EOL...
	bne NoCR
	bit PTakiInGETLN	; ...but only if in GETLN
        bpl NoCR
        writeWord PTakiIndirectFn, CLREOL
        jsr TakiDoubleDo
        lda #$8D
NoCR:
@Done:	; Restore proper char (both pages),
	; and $6/$7
        sta SavedCursor	; temp save read key
        lda SavedRealChar
        sta (Mon_BASL),y
        sta ($6),y
	pla
	sta $7
        pla
        sta $6
        lda SavedCursor
	rts

TakiCheckForGETLN:
	; The monitor GETLN routine, also used
        ; by AppleSoft and assembly-language
        ; programs, does special things we must
        ; account for. Check to see if that's
        ; our caller.
        pha
        txa
        pha
          tsx	; stack into X
          lda $107,x ; check for return to $FD78
          cmp #$77
          bne @False
          lda $108,x
          cmp #$FD
          bne @False
          lda #$FF
          sta PTakiInGETLN
          bne @Done ; always
@False: lda #$00
	sta PTakiInGETLN
@Done:  pla
        tax
        pla
	rts

Saved_CH:
	.byte $00
Saved_CV:
	.byte $00
Saved_BAS:
	.byte $00, $00
        
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

; Taki's standard COUT-assigned routine.
; Prints to both text pages at once, and
; checks for Taki control character
TakiDoubledOut:
	cld
        pha
        writeWord PTakiIndirectFn, TakiCOUT
        pla
        jmp TakiDoubleDo

YSAV1:
	.byte $00
; A modified variant of Monitor's COUT1 routine
; (standard PR#0 output routine)
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
	bcs     Badge
	pha
	jsr     VTABZ
SCRL2:	lda     (Mon_BASL),y
	sta     (Mon_BAS2L),y
	dey
	bpl     SCRL2
	bmi     SCRL1
Badge:
	DebugDrawBadge_
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

TakiClearPage2:
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
        DebugDrawBadge_
	rts
	
