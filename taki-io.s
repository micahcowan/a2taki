.include "a2-monitor.inc"
.include "taki-util.inc"
.include "taki-debug.inc"
TAKI_INTERNAL=1
.include "taki-public.inc"
I_AM_TAKI_IO=1
.include "taki-internal.inc"

DIVISION_WORK_AREA=RandomDivWorkspace
.include "division.inc"

.macpack apple2

_TakiCmdBufCurrent:
    .byte $00

; Taki standard character output/processing routine
.export _TakiOut
_TakiOut:
    cmp #$94        ; Ctrl-T?
    bne @RegChar    ; No, so proceed to output
    lda #$00
    sta _TakiCmdBufCurrent
    writeWord _TakiOutFn, _TakiIoCtrlReadCmd
    rts
@RegChar:
    jmp _TakiIoScreenOut

_TakiIoCtrlReadCmd:
    sta pvSavedRealChar

    tya     ; save Y
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
    sta ($00),y     ; the actual save
    inc _TakiCmdBufCurrent
    
    pla     ; restore ZP
    sta $01
    pla
    sta $00
    pla     ; restore Y
    tay
    
    lda pvSavedRealChar     ; and A
    
    cmp #$8D        ; Did we just store a CR?
    bne @rts        ; no, return
    TakiEffectDo_ _TakiCommandExec  ; yes: command done, execute

@rts:
    rts

.export _TakiIoCollectUntilCtrlQ
_TakiIoCollectUntilCtrlQ:
    cmp #$91        ; Ctrl-Q?
    bne @Collect
    TakiEffectDoDispatchCur_ TAKI_DSP_ENDCOLLECT
    writeWord  _TakiOutFn, _TakiOut ; restore normal output
    rts
@Collect:
    TakiEffectDoDispatchCur_ TAKI_DSP_COLLECT
    rts

.export _TakiIoCollectWord
_TakiIoCollectWord:
    cmp #$A0        ; SPC?
    beq @UnCollect
    cmp #$8D        ; CR?
    bne @Collect    ; no, collect
@UnCollect:
    pha
    TakiEffectDoDispatchCur_ TAKI_DSP_ENDCOLLECT
    writeWord  _TakiOutFn, _TakiOut ; restore normal output
    pla ; and also write out the space or CR
    jmp TakiOut
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
    ; if we're not in GetLN, skip:
    pha
.if 1
    cpx #0                  ; is x-reg zero?
                            ;  (might be pointing at INBUF)
    bne @NotExited          ; no, no further checks
    cpy #1                  ; is y-reg one?
    bne @NotExited
    cpy Mon_CH              ; and is it also == CH?
    bne @NotExited          ; no: not at prompt
    lda TakiVarExitPrompts  ; yes, check ] prompt
    beq @NotExited          ; prompt check disabled!
    cmp Mon_PROMPT          ; PROMPT = ] (or P1)?
    beq @Exited             ; yes so exited.
    lda TakiVarExitPrompts+1
    beq @NotExited          ; 2nd prompt disabled
    cmp Mon_PROMPT          ; PROMPT = * (or P2)?
    bne @NotExited          ; no, not exited
@Exited:
    lda Mon_PROMPT          ; one last check:
    dey
    cmp (Mon_BASL),y        ; is the preceding char
                            ;  the prompt char?
    php
    iny                     ; (fix y-reg back up)
    plp
    bne @NotExited          ; not prompt char, not prompt
    pla ; from branch-unless flagInGETLN
    TakiDbgPrint_ pvPromptExitStr
    lda (Mon_BASL),y
    pha
    lda pvSavedRealChar
    sta (Mon_BASL),y        ; remove flasher
    jsr _TakiExit
    ldy #$00                ; prompt at col 0
    lda Mon_PROMPT
    sta (Mon_BASL),y
    iny
    sty Mon_CH
    pla                     ; set flasher new spot
    sta (Mon_BASL),y
    lda pvSavedRealChar
    jmp Mon_KEYIN           ; let firmware keyin handle
.endif
@NotExited:
    sta $C00E               ; ensure alt charset is off
    lda #$5F                ; force flasher char (for //c).
                            ; Underscore, not "char under cursor",
                            ;  bc we can't handle lowercase like that.
                            ; ...and because flashing space looks
                            ;  hollow.
    sta (Mon_BASL),y
    pla ; from branch-unless flagInGETLN
@KEYIN:
    inc     Mon_RNDL
    bne     @KEYIN2
    inc     Mon_RNDH
    TakiBranchIfFlag_ flagTicksPaused, @Paused
    TakiSetFlag_ flagInInput
    TakiEffectDo_ _TakiTick
    TakiUnsetFlag_ flagInInput
@Paused:
@KEYIN2:
    bit     SS_KBD             ;read keyboard
    bpl     @KEYIN
    ; keypress available.
    lda     SS_KBD
    sta     SS_KBDSTRB
    jsr _TakiDbgCheckKey
    bcc @KEYIN
    cmp #$9B        ; ESC - skip and get new keypress
    beq @KEYIN
@Done:
    ; Restore proper char (both pages),
    ;  and $6/$7
    sta pvSavedCursor       ; temp save read key
    lda pvSavedRealChar
    sta (Mon_BASL),y
    lda pvSavedCursor
    rts

.export _TakiIoGetKey
_TakiIoGetKey:
@KEYIN:
    inc     Mon_RNDL
    bne     @KEYIN2
    inc     Mon_RNDH
@KEYIN2:
    bit     SS_KBD             ;read keyboard
    bpl     @KEYIN
    ; keypress available.
    lda     SS_KBD
    sta     SS_KBDSTRB

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
pCOUTZ:
    sty     pvYSAV1
    pha
    jsr     pVIDWAIT
    pla
    ldy     pvYSAV1
    rts
;
pSTORADV:
    ldy     Mon_CH
    sta (Mon_BASL),y
pADVANCE:
    inc     Mon_CH
    lda     Mon_CH
    cmp     Mon_WNDWDTH
    bcs     pCR
    rts
;
pVIDWAIT:
    cmp     #$8d            ;check for a pause only when I have a CR
    bne     pNOWAIT         ;no so, do regular
    ldy     SS_KBD          ;is key pressed?
    bpl     pNOWAIT         ;no
    cpy     #$93            ;is it ctl S?
    bne     pNOWAIT         ;no so ignore
    sta     SS_KBDSTRB      ;clear strobe
pKBDWAIT:
    TakiEffectDo_ _TakiTick
    ; FIXME: add some delay here to match speed at input
    ldy     SS_KBD          ;wait till next key to resume
    bpl     pKBDWAIT        ;wait for keypress
    cpy     #$83            ;is it control C ?
    beq     pNOWAIT         ;yes so leave it
    sta     SS_KBDSTRB      ;clr strobe
pNOWAIT:
pVIDOUT:
    pha
    TakiBranchUnlessFlag_ flagAnimationActive, pSkipTick
    TakiEffectDo_ _TakiTick
pSkipTick:
    pla
    cmp     #$a0
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
pRTS4:
    rts

pBELL1:
    jmp     Mon_BELL1

pCR:lda     #$00
    sta     Mon_CH
pLF:inc     Mon_CV
    lda     Mon_CV
    cmp     Mon_WNDBTM
    bcs     @AtBottom
    jmp     pVTABZ
@AtBottom:
    dec     Mon_CV
pSCROLL:
    lda     Mon_WNDTOP
    pha
    jsr     pVTABZ
pSCRL1:
    lda     Mon_BASL
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
pSCRL2:
    lda     (Mon_BASL),y
    sta     (Mon_BAS2L),y
    dey
    bpl     pSCRL2
    bmi     pSCRL1
pSCRL3:
    ldy     #$00
    jsr     pCLEOLZ
    bcs     pVTAB
pCLREOL:
    pha
    tya
    pha
    ldy     Mon_CH
pCLEOLZ:
    lda     #$a0
pCLREOL2:
    sta (Mon_BASL),y
    iny
    cpy     Mon_WNDWDTH
    bcc     pCLREOL2
    pla
    tay
    pla
    rts

pVTAB:
    lda     Mon_CV
pVTABZ:
    jsr     Mon_BASCALC
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
@ChkLp:
    pha
    jsr Mon_VTABZ
    ldy #0 ; we assume Mon_WNDLFT == 0, else how'd we get to 0,0?
@CkChr:
    lda (Mon_BASL),y
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
@ClrLp:
    pha
    jsr Mon_BASCALC
    ldy #0
    lda #$A0 ; SPC
@ClrChr:
    sta (Mon_BASL),y
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

pfovYSAV1:
    .byte $00
.export _TakiIoFastOut
_TakiIoFastOut:
pfoCOUTZ:
    sty     pfovYSAV1
    pha
    jsr     pfoNOWAIT
    pla
    ldy     pfovYSAV1
    rts
;
pfoSTORADV:
    ldy     Mon_CH
    sta (Mon_BASL),y
pfoADVANCE:
    inc     Mon_CH
    lda     Mon_CH
    cmp     Mon_WNDWDTH
    bcs     pfoCR
    rts
;
pfoNOWAIT:
pfoVIDOUT:
    pha
    pla
    cmp     #$a0
    bcs     pfoSTORADV
    tay
    bpl     pfoSTORADV
    cmp     #$8d
    beq     pfoCR
    cmp     #$8a
    beq     pfoLF
    cmp     #$88
    bne     pfoRTS4
    dec     Mon_CH
    bpl     pfoRTS4
    lda     Mon_WNDWDTH
    sta     Mon_CH
    dec     Mon_CH
    lda     Mon_WNDTOP
    cmp     Mon_CV
    bcs     pfoRTS4
    dec     Mon_CV
    lda     Mon_CV
    jsr     Mon_BASCALC
    adc     Mon_WNDLFT
    sta     Mon_BASL
pfoRTS4:
    rts
pfoCR:
    lda     #$00
    sta     Mon_CH
pfoLF:
    inc     Mon_CV
    lda     Mon_CV
    cmp     Mon_WNDBTM
    bcs     @AtBottom
    jmp     pVTABZ
@AtBottom:
    dec     Mon_CV
    ; We DON'T SCROLL in fast out
    jmp     pVTAB

.export _TakiIoFastPrintStr
_TakiIoFastPrintStr:
    ; First adjust BAS = BAS + CH
    lda Mon_BASL
    clc
    adc Mon_CH
    sta Mon_BASL
    pha
        ldy #0
@lp:
        lda (kZpEffSpecial0),y
        beq @finish
        sta (Mon_BASL),y
        iny
        bne @lp
@finish:
    pla
    sta Mon_BASL
    rts

.export _TakiIoFastPrintSpace
_TakiIoFastPrintSpace:
    ; First adjust BAS = BAS + CH
    lda Mon_BASL
    clc
    adc Mon_CH
    sta Mon_BASL
    pha
        ldy #0
@lp:
        lda (kZpEffSpecial0),y
        beq @finish
        lda #$A0
        sta (Mon_BASL),y
        iny
        bne @lp
@finish:
    pla
    sta Mon_BASL
    rts

.export _TakiIoNextRandom
_TakiIoNextRandom:
    tya
    pha
        ; Make certain the number isn't zero, or we can't fold it
        lda TakiVarRandomWord
        bne @notZero
        lda TakiVarRandomWord+ 1
        bne @notZero
        ; It's zero! Fix that.
        lda #$71
        sta TakiVarRandomWord
        lda #$94
        sta TakiVarRandomWord+1
    pla
    tay
    rts
@notZero:
        ; Algorithm based on Woz's Integer BASIC's PRNG implementation
        lda TakiVarRandomWord+1
        and #$7F
        sta TakiVarRandomWord+1
        ldy #$11
lp:
        lda TakiVarRandomWord+1
        asl
        clc
        adc #$40
        asl
        rol TakiVarRandomWord
        rol TakiVarRandomWord+1
        dey
        bne lp
    pla
    tay
    rts

.export _TakiIoRandWithinAY
_TakiIoRandWithinAY:
    sta locDivisor+1
    sty locDivisor
    jsr _TakiIoNextRandom
    lda TakiVarRandomWord
    sta locDividend+1
    lda TakiVarRandomWord+1
    sta locDividend
    jsr div16
    .if 0
    ldx #0
@lo:
    lda RandomDivWorkspace,x
    jsr Mon_PRBYTE
    inx
    cpx #20
    bne @lo
    ;
    lda #$8D
    jsr Mon_COUT
.endif
    ;
    lda locRemainder+1
    ldy locRemainder
    rts

div16:
makeDivisionRoutine 2

RandomDivWorkspace:
    .res 20
