.include "a2-monitor.inc"
.include "taki-util.inc"
.include "taki-debug.inc"

; Used by InitializeDirect:
.import _TakiVarActiveEffectsNum
.import _TakiEffectInitializeDirect, _TakiEffectInitializeDirectFn
.import TE_Scan, _TakiSetupForEffectY, _TakiVarEffectCounterInitTable

.import _TakiDbgInit, _TakiDbgExit, _TakiDbgPrint, _TakiDbgPrintStr
.import _TakiDbgDrawBadge, _TakiDbgUndrawBadge

.import TakiVarIndirectFn, TakiVarExitPrompts, TakiVarInGETLN
.import TakiVarCurPageBase, TakiVarNextPageBase, TakiVarTicksPaused
.import TakiVarDebugActive

.import _TakiTick, _TakiExit, _TakiIndirect
.import _TakiEffectSetupAndDo, _TakiEffectSetupFn

.macpack apple2

; Call a function twice, once with BAS -> pg 1,
; and once with BAS -> pg 2.
;
; To invoke, first write the addr of the fn
; you want called for each page to TakiVarIndirectFn,
; then jsr TakiDoubleDo.
.export _TakiIoDoubleDo
_TakiIoDoubleDo:
	; Save CH, CV, BASL/H
        pha
        lda Mon_CH
        sta pvSaved_CH
        lda Mon_CV
        sta pvSaved_CV
        lda Mon_BASL
        sta pvSaved_BAS
        lda Mon_BASH
        sta pvSaved_BAS+1
        pla
        
        ; Do p1 job
        jsr _TakiIndirect
        
        ; Restore CH, CV, BASL/H
        pha
        lda pvSaved_CH
        sta Mon_CH
        lda pvSaved_CV
        sta Mon_CV
        lda pvSaved_BAS
        sta Mon_BASL
        lda pvSaved_BAS+1
        eor #$0C
        sta Mon_BASH
        ; and set BASCALC
        lda #<_TakiIoPageTwoBasCalc
        sta pvBASCALCfn
        lda #>_TakiIoPageTwoBasCalc
        sta pvBASCALCfn+1
	pla
        ; Do p2 job
        jsr _TakiIndirect
        ; Fix up BASL, and BASLCALC
        pha
        lda Mon_BASH
        eor #$0C
        sta Mon_BASH
        lda #<_TakiIoPageOneBasCalc
        sta pvBASCALCfn
        lda #>_TakiIoPageOneBasCalc
        sta pvBASCALCfn+1
        pla
        rts

; Taki standard character output/processing routine
.export _TakiOut
_TakiOut:
	cmp #$92	; Ctrl-R?
        bne @RegChar	; No, so proceed to output
        writeWord Mon_CSWL, _TakiIoCtrlR
        rts
@RegChar:
	jmp _TakiIoDoubledOut

_TakiIoCtrlR:
	; ignore next char for , assume "S"
        ; Set up initialization
        TakiEffectInitializeDirect_ TE_Scan
        ;; set different counter value
        tya
        pha
        lda $0
        pha
        lda $1
        pha
        
        lda _TakiVarEffectCounterInitTable
        sta $0
        lda _TakiVarEffectCounterInitTable+1
        sta $1
        lda #$2C
        ldy #2
        sta ($0),y
        
        pla
        sta $1
        pla
        sta $0
        pla
        tay
        ;; end set different countr value
	writeWord Mon_CSWL, _TakiIoCollectWord
        rts

_TakiIoCollectWord:
	cmp #$92	; Ctrl-R?
        bne @Collect
        ;TakiEffectDo_ _TakiIoCollectEndScan
	writeWord Mon_CSWL, _TakiOut ; restore normal output
        rts
@Collect:
	TakiEffectDo_ _TakiIoCollectByteScan
	rts

_TakiIoCollectByteScan:
	ldy _TakiVarActiveEffectsNum
        dey
        jsr _TakiSetupForEffectY
        lda #TAKI_DSP_COLLECT
        jsr TE_Scan
        ; save allocations
        lda kZpCurEffect
        asl
        tay
        lda kZpCurEffStorageEndL
        sta (kZpEffAllocTbl),y
        iny
        lda kZpCurEffStorageEndH
        sta (kZpEffAllocTbl),y
	rts

pvPromptExitStr:
	scrcode "!!EXIT VIA PROMPT DETECTED!!",$0D
        .byte $00

pvSavedCursor:
	.byte $00
pvSavedRealChar:
	.byte $00
; Taki character input routine
; XXX: make this work with both text pages...
; XXX: does this work with //e cursors?
.export _TakiIn
_TakiIn:
        ; save real char
        sta pvSavedRealChar
        jsr pTakiCheckForGETLN
        bit TakiVarInGETLN	; are we in GETLN?
        bpl @NotExited		; no, skip ahead
        cpx #00			; yes: are we in 2nd column?
        bne @NotExited		; no, no further checks
        lda TakiVarExitPrompts	; yes, check ] prompt
        beq @NotExited		; prompt check disabled!
        cmp Mon_PROMPT		; PROMPT = ] (or P1)?
        beq @Exited		; yes so exited.
        lda TakiVarExitPrompts+1
        beq @NotExited		; 2nd prompt disabled
        cmp Mon_PROMPT		; PROMPT = * (or P2)?
        bne @NotExited		; no, not exited
@Exited:TakiDbgPrint_ pvPromptExitStr
	lda (Mon_BASL),y
        pha
        lda pvSavedRealChar
	sta (Mon_BASL),y	; remove flasher
	jsr _TakiExit
	ldy #$00		; prompt at col 0
        lda Mon_PROMPT
        sta (Mon_BASL),y
        iny
        sty Mon_CH
        pla			; set flasher new spot
        sta (Mon_BASL),y
        lda pvSavedRealChar
        jmp (Mon_KSWL)		; hand control to
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
        ;and #($FF - $4)
        ;ora #$08
        eor #$0C
        sta $7
        
        ; save cursor, and set it on pg 2 as well
        lda (Mon_BASL),y
        sta pvSavedCursor
        sta ($06),y
@KEYIN:	inc     Mon_RNDL
	bne     @KEYIN2
	inc     Mon_RNDH
        bit TakiVarTicksPaused
        bne @Paused
        TakiEffectDo_ _TakiTick
@Paused:
@KEYIN2:bit     SS_KBD             ;read keyboard
	bpl     @KEYIN
        ; keypress available.
	lda     SS_KBD
        bit	SS_KBDSTRB
        bit     TakiVarDebugActive  ; is debug active?
        bpl     @NoAT               ; no: skip @ check
        cmp	#$C0	; '@' ?
        bne	@NoAT	; no: skip
        pha
        lda #$FF
        sta TakiVarTicksPaused
        pla
        jsr	_TakiIoPageFlip
        jmp	@KEYIN
@NoAT:	; Any key other than @ will resume ticks
        pha
        lda #$00
        sta TakiVarTicksPaused
        pla
	cmp #$9B	; ESC - skip and get new keypress
        bne @NoESC
        jmp @KEYIN
@NoESC:  ; If GETLN gets a CR on input, it
	; clears to the end of the line, but
        ; since it doesn't use CSW to do this,
        ; it'll only happen in page one.
        ; So, as a hacky workaround, we check
        ; to see if we were called from GETLN
        ; and perform CLREOL in both pages if so.
	cmp #$8D	; CR - clear to EOL...
	bne @NoCR
	bit TakiVarInGETLN	; ...but only if in GETLN
        bpl @NoCR
        writeWord TakiVarIndirectFn, pCLREOL
        
        ; CLREOL changes y reg, so save/restore
        pha
        tya
        pha
        jsr _TakiIoDoubleDo
        pla
        tay
        pla
        
        ; "Saved char" will be written to both pages,
        ; AFTER we did a CLREOL, and then GETLN
        ; will clear again. This leaves the "saved"
        ; char on the screen in page 2 but not page 1.
        ; So set "saved char" to SPACE, to compensate.
        lda #$A0
        sta pvSavedRealChar
        lda #$8D
@NoCR:
@Done:	; Restore proper char (both pages),
	; and $6/$7
        sta pvSavedCursor	; temp save read key
        lda pvSavedRealChar
        sta (Mon_BASL),y
        sta ($6),y
	pla
	sta $7
        pla
        sta $6
        lda pvSavedCursor
	rts

pTakiCheckForGETLN:
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
          sta TakiVarInGETLN
          bne @Done ; always
@False: lda #$00
	sta TakiVarInGETLN
@Done:  pla
        tax
        pla
	rts

pvSaved_CH:
	.byte $00
pvSaved_CV:
	.byte $00
pvSaved_BAS:
	.byte $00, $00
        
pTakiBASCALC:
pvBASCALCfn = pTakiBASCALC + 1
        jmp _TakiIoPageOneBasCalc ; actual addr overwritten

_TakiIoPageOneBasCalc = Mon_BASCALC

; Same as monitor BASCALC, but calc for page 2 instead
.export _TakiIoPageTwoBasCalc
_TakiIoPageTwoBasCalc:
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
.export _TakiIoDoubledOut
_TakiIoDoubledOut:
	cld
        pha
        writeWord TakiVarIndirectFn, pTakiCOUT
        pla
        jmp _TakiIoDoubleDo

pvYSAV1:
	.byte $00
; A modified variant of Monitor's COUT1 routine
; (standard PR#0 output routine)
pTakiCOUT:
	cmp     #$a0
        bcc     pCOUTZ
	and     Mon_INVFLG
pCOUTZ:  sty     pvYSAV1
	pha
        jsr     pVIDOUT
	pla
        ldy     pvYSAV1
	rts
;
pSTORADV:ldy     Mon_CH
	sta     (Mon_BASL),y
pADVANCE:inc     Mon_CH
	lda     Mon_CH
	cmp     Mon_WNDWDTH
        bcs     pCR
	rts
;
pVIDOUT:	cmp     #$a0
        bcs     pSTORADV
	tay
        bpl     pSTORADV
	cmp     #$8d
        beq     pCR
	cmp     #$8a
        beq     pLF
	cmp     #$88
        bne     pBELL1
	dec     Mon_CH
        bpl     pRTS4
	lda     Mon_WNDWDTH
	sta     Mon_CH
	dec     Mon_CH
	lda     Mon_WNDTOP
	cmp     Mon_CV
        bcs     pRTS4
	dec     Mon_CV
	lda     Mon_CV
	jsr     pTakiBASCALC
	adc     Mon_WNDLFT
	sta     Mon_BASL
pRTS4:	rts

pBELL1:	jmp	Mon_BELL1

pCR:	lda     #$00
	sta     Mon_CH
pLF:	inc     Mon_CV
	lda     Mon_CV
	cmp     Mon_WNDBTM
        bcc     pVTABZ
	dec     Mon_CV
pSCROLL:lda     Mon_WNDTOP
	pha
        jsr     pVTABZ
pSCRL1:	lda     Mon_BASL
	sta     Mon_BAS2L
	lda     Mon_BASH
	sta     Mon_BAS2H
	ldy     Mon_WNDWDTH
	dey
	pla
	adc     #$01
	cmp     Mon_WNDBTM
        bcs     pBadge
	pha
        jsr     pVTABZ
pSCRL2:	lda     (Mon_BASL),y
	sta     (Mon_BAS2L),y
	dey
        bpl     pSCRL2
        bmi     pSCRL1
pBadge:
        jsr _TakiDbgDrawBadge
pSCRL3:	ldy     #$00
        jsr     pCLEOLZ
        bcs     pVTAB
pCLREOL:ldy     Mon_CH
pCLEOLZ:	lda     #$a0
pCLREOL2:sta     (Mon_BASL),y
	iny
	cpy     Mon_WNDWDTH
        bcc     pCLREOL2
	rts

pVTAB:	lda	Mon_CV
pVTABZ:	jsr     pTakiBASCALC
	adc     Mon_WNDLFT
	sta     Mon_BASL
	rts

.export _TakiIoClearPageTwo
_TakiIoClearPageTwo:
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
        jsr _TakiDbgDrawBadge
	rts

.export _TakiIoPageFlip
_TakiIoPageFlip:
	lda TakiVarCurPageBase	; what's cur page?
        cmp #$08		; p2: go handle that
        beq _TakiIoSetPageTwo	; otherwise, handle p1 here
.export _TakiIoSetPageOne
_TakiIoSetPageOne:
	lda #$08
        sta TakiVarCurPageBase
        lda #$04
        sta TakiVarNextPageBase
        bit SS_SEL_TEXT_P2	; switch to p2
        rts
.export _TakiIoSetPageTwo
_TakiIoSetPageTwo:
	lda #$04
        sta TakiVarCurPageBase
        lda #$08
        sta TakiVarNextPageBase
        bit SS_SEL_TEXT_P1	; switch to p1
        rts
	
