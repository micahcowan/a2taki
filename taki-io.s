.include "a2-monitor.inc"
.include "taki-util.inc"
.include "taki-debug.inc"
TAKI_INTERNAL=1
.include "taki-public.inc"
I_AM_TAKI_IO=1
.include "taki-internal.inc"

.macpack apple2

_TakiCmdBufCurrent:
	.byte $00

; Taki standard character output/processing routine
.export _TakiOut
_TakiOut:
	cmp #$94	; Ctrl-T?
        bne @RegChar	; No, so proceed to output
        lda #$00
        sta _TakiCmdBufCurrent
        writeWord Mon_CSWL, _TakiIoCtrlReadCmd
        rts
@RegChar:
	jmp _TakiIoScreenOut

_TakiIoCtrlReadCmd:
        sta pvSavedRealChar

	tya	; save Y
        pha
        lda $00 ; make room in ZP
        pha
        lda $01
        pha
        
        lda TakiVarCommandBufferPage
        sta $01
        lda #$00
        sta $00
        ldy _TakiCmdBufCurrent
        lda pvSavedRealChar
        sta ($00),y	; the actual save
        inc _TakiCmdBufCurrent
        
        pla	; restore ZP
        sta $01
        pla
        sta $00
        pla	; restore Y
        tay
        
        lda pvSavedRealChar	; and A
        
	cmp #$8D	; Did we just store a CR?
        bne @rts	; no, return
        TakiEffectDo_ _TakiCommandExec	; yes: command done, execute

@rts:	rts

.export _TakiIoCollectUntilCtrlQ
_TakiIoCollectUntilCtrlQ:
	cmp #$91	; Ctrl-Q?
        bne @Collect
        TakiEffectDoDispatchCur_ TAKI_DSP_ENDCOLLECT
	writeWord Mon_CSWL, _TakiOut ; restore normal output
        rts
@Collect:
	TakiEffectDoDispatchCur_ TAKI_DSP_COLLECT
	rts

.export _TakiIoCollectWord
_TakiIoCollectWord:
	cmp #$A0	; SPC?
        beq @UnCollect
        cmp #$8D	; CR?
        bne @Collect	; no, collect
@UnCollect:
	pha
        TakiEffectDoDispatchCur_ TAKI_DSP_ENDCOLLECT
	writeWord Mon_CSWL, _TakiOut ; restore normal output
        pla ; and also write out the space or CR
        jmp (Mon_CSWL)
@Collect:
	TakiEffectDoDispatchCur_ TAKI_DSP_COLLECT
	rts

pvPromptExitStr:
	scrcode "!!EXIT VIA PROMPT DETECTED!!",$0D
        .byte $00

pvSavedCursor:
	.byte $00
pvSavedRealChar:
	.byte $00
; Taki character input routine
; XXX: does this work with //e cursors?
.export _TakiIn
_TakiIn:
        ; save real char
        sta pvSavedRealChar
        jsr pTakiCheckForGETLN
        ; if we're not in GetLN, skip:
        pha
        TakiBranchUnlessFlag_ flagInGETLN, @NotExited
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
@Exited:pla ; from branch-unless flagInGETLN
	TakiDbgPrint_ pvPromptExitStr
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
	pla ; from branch-unless flagInGETLN
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
        TakiBranchIfFlag_ flagTicksPaused, @Paused
        TakiSetFlag_ flagInInput
        TakiEffectDo_ _TakiTick
        TakiUnsetFlag_ flagInInput
@Paused:
@KEYIN2:bit     SS_KBD             ;read keyboard
	bpl     @KEYIN
        ; keypress available.
	lda     SS_KBD
        bit	SS_KBDSTRB
        jsr _TakiDbgCheckKey
        bcc @KEYIN
        cmp #$9B	; ESC - skip and get new keypress
        beq @KEYIN
@NoESC: ; If GETLN gets a CR on input, it
	; clears to the end of the line, but
        ; since it doesn't use CSW to do this,
        ; it'll only happen in page one.
        ; So, as a hacky workaround, we check
        ; to see if we were called from GETLN
        ; and perform CLREOL in both pages if so.
	cmp #$8D	; CR - clear to EOL...
	bne @NoCR
        TakiBranchUnlessFlag_ flagInGETLN, @NoCR
        jsr pCLREOL
        
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

.export _TakiIoGetKey
_TakiIoGetKey:
@KEYIN:
	inc     Mon_RNDL
	bne     @KEYIN2
	inc     Mon_RNDH
@KEYIN2:bit     SS_KBD             ;read keyboard
	bpl     @KEYIN
        ; keypress available.
	lda     SS_KBD
        bit	SS_KBDSTRB

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
          TakiSetFlag_ flagInGETLN
          bne @Done ; always
@False: TakiUnsetFlag_ flagInGETLN
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

pvYSAV1:
	.byte $00
; A modified variant of Monitor's COUT1 routine
; (standard PR#0 output routine)
.export _TakiIoScreenOut
_TakiIoScreenOut:
	jsr _TakiIoCheckForHome
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
	sta (Mon_BASL),y
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
	jsr     Mon_BASCALC
	adc     Mon_WNDLFT
	sta     Mon_BASL
pRTS4:	rts

pBELL1:	jmp	Mon_BELL1

pCR:	lda     #$00
	sta     Mon_CH
pLF:	inc     Mon_CV
	lda     Mon_CV
	cmp     Mon_WNDBTM
        bcs	@AtBottom
        jmp     pVTABZ
@AtBottom:
	dec     Mon_CV
        ; TAKI - if we would scroll because of a CR,
        ; but an animation has been initialized:
        ; only scroll last two lines.
        ; AlsO add a delay
        TakiBranchUnlessFlag_ flagAnimationActive, pSCROLL
        TakiBranchIfFlag_ flagInDebugPrint, pSCROLL
        ; Animations in progress: delay a bit (with animation)
        ; and scroll ONLY last two lines (unless this
        ; is a debug print, or we're already in animation)
        lda #$18
        jsr _TakiDelay
        lda Mon_CV
        sec
        sbc #$01
        pha
        jsr pVTABZ
        bne pSCRL1 ; "always"
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
        bcs     pSCRL3
	pha
        jsr     pVTABZ
pSCRL2:	lda     (Mon_BASL),y
	sta     (Mon_BAS2L),y
        ; now do the other page
        lda Mon_BASL+1
        pha
        eor #$0C
        sta Mon_BASL+1
        lda Mon_BAS2L+1
        pha
        eor #$0C
        sta Mon_BAS2L+1
        ;
        lda (Mon_BASL),y
        sta (Mon_BAS2L),y
        ;
        pla
        sta Mon_BAS2L+1
        pla
        sta Mon_BASL+1
        ;
	dey
        bpl     pSCRL2
        bmi     pSCRL1
pSCRL3:	ldy     #$00
        jsr     pCLEOLZ
        bcs     pVTAB
pCLREOL:pha
	tya
        pha
	ldy     Mon_CH
pCLEOLZ:	lda     #$a0
pCLREOL2:sta (Mon_BASL),y
	iny
	cpy     Mon_WNDWDTH
        bcc     pCLREOL2
        pla
        tay
        pla
	rts

pVTAB:	lda	Mon_CV
pVTABZ:	jsr     Mon_BASCALC
	adc     Mon_WNDLFT
	sta     Mon_BASL
	rts

_TakiIoCheckForHome:
	pha
        tya
        pha
        TF_BEH_BRANCH_UNLESS_FLG TF_BEH_DETECT_HOME, @bail2
        
        ; Check if we're at 0, 0 with a blank screen.
        ; If so, the user probably executed "HOME". Clean
        ; up the 2nd page if so.
        lda Mon_CV
        bne @bail2
        ldy Mon_CH
        bne @bail2
        
        ; We're at 0, 0. Check for a cleared screen!
@ChkLp:	pha
        jsr Mon_VTABZ
	ldy #0 ; we assume Mon_WNDLFT == 0, else how'd we get to 0,0?
@CkChr: lda (Mon_BASL),y
        cmp #$A0 ; SPC
        bne @bail
        iny
        cpy Mon_WNDWDTH
        bcc @CkChr
        pla
        clc
        adc #1
        cmp Mon_WNDBTM
        bcc @ChkLp

	; Screen is clear. Assume we should reset animation
        ; and clear p2 as well.
        jsr _TakiReset
        lda #0
@ClrLp: pha
	jsr Mon_BASCALC
        ldy #0
        lda #$A0 ; SPC
@ClrChr:sta (Mon_BASL),y
	iny
        cpy Mon_WNDWDTH
        bcc @ClrChr
        pla
        clc
        adc #1
        cmp Mon_WNDBTM
        bcc @ClrLp
        .byte $24 ; skip next instr

@bail:
	pla
        lda #0
        jsr pVTABZ
@bail2:
        pla
        tay
        pla
        rts	
