.include "taki-debug.inc"

I_AM_TAKI_DEBUG=1
TAKI_INTERNAL=1
.include "taki-public.inc"
.include "taki-internal.inc"
.include "a2-monitor.inc"

.macpack apple2

kDebugNumLines		= 4 ; # lines to reserve at scr btm
kDebugNumRegLines	= 24 - kDebugNumLines

.export _TakiDbgInit
_TakiDbgInit:
	; If CV is in the reserved area, scroll
        ; up (scrolling cursor along) until
        ; it's not.
@ScrollCheck:
        lda Mon_CV
	cmp #kDebugNumRegLines
        bcc @DoneScrolling
        sbc #1	; carry is set/"borrow clear"
        sta Mon_CV
        jsr Mon_SCROLL	; use monitor's because
        		; pg 2 already clear
        jmp @ScrollCheck
@DoneScrolling:
	; Clear lines at screen bottom
	lda #(24 - kDebugNumLines)
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
	lda #(24 - kDebugNumLines)
        sta Mon_WNDBTM
        ; Mark debug as active
        lda _TakiVarStatusFlags
        ora #flagDebugActive
        sta _TakiVarStatusFlags
        ; and copy to copy-of-flags
        sta TakiVarStatusFlags
        ; Print start msg
        TakiDbgPrint_ pvDbgInitMsg
        rts
        
.export _TakiDbgExit
_TakiDbgExit:
        TakiBranchIfFlag_ flagDebugActive, :+
        rts
:       TakiDbgPrint_ pvDbgExitMsg
        lda #24
        sta Mon_WNDBTM
        lda #0
        sta Mon_CH
        lda #23
        sta Mon_CV
        jsr Mon_VTABZ
        lda #$8D
        jsr Mon_COUT
        lda #$8D
        jsr Mon_COUT
        ; Mark debug as inactive
        lda _TakiVarStatusFlags
        and #.lobyte(~(flagDebugActive))
        sta _TakiVarStatusFlags
        ; and copy to copy-of-flags
        sta TakiVarStatusFlags
	rts

pvDbgInitMsg:
	scrcode "TAKI DEBUG START", $0D
;	scrcode "TWO",$0D,"THREE",$0D,"FOUR",$0D,"FIVE",$0D
;	scrcode "SIX",$0D,"SEVEN",$0D
        .byte $00
pvDbgExitMsg:
	scrcode "TAKI DEBUG EXIT", $0D
        .byte $00

.export _TakiDbgPrint
_TakiDbgPrint:
	pha
        TakiBranchIfFlag_ flagDebugActive, :+
        pla
        rts
:       pla
	sta _TakiDbgVarPrintStr
        sty _TakiDbgVarPrintStr+1
        jsr pPrintSetup
.export _TakiDbgVarPrintStr
_TakiDbgVarPrintStr = * + 1
@Loop:	lda $1000
	beq @Done
        jsr Mon_COUT
        inc _TakiDbgVarPrintStr
        bne @Loop
        inc _TakiDbgVarPrintStr+1
        bne @Loop
@Done:
        jmp pPrintTeardown

.export _TakiDbgCOUT
_TakiDbgCOUT:
        sta pvSavedChar
        TakiBranchIfFlag_ flagDebugActive, :+
        lda pvSavedChar
        rts
        ; NOT RE-ENTRANT!
:       lda pvSavedChar
	TakiSetFlag_ flagInDebugPrint
        bit pvDoCrNext
	beq @NoPendCR	; Pending CR? no: check
        pha		; for current CR. yes: emit CR
	lda #$8D
        jsr _TakiOut
        lda #$00 ; un-pend CR
        sta pvDoCrNext
        pla
@NoPendCR:
	cmp #$8D	; current CR?
        bne @DoOutput	; no: just do output
        sta pvDoCrNext ; yes: save it and exit
        beq @rts	; always
@DoOutput:
        lda Mon_INVFLG; save invflag
        pha
        lda #$3F ; Set inverse
        sta Mon_INVFLG
        lda pvSavedChar
	jsr _TakiOut
        pla
        sta Mon_INVFLG
@rts:
	TakiUnsetFlag_ flagInDebugPrint
        lda pvSavedChar
        rts

pvSavedChar:
	.byte $00
pvSavedCSW:
	.word $0000
pvSavedWNDBTM:
	.byte $00
pvSavedWNDTOP:
	.byte $00
pvSavedCV:
	.byte $00
pvSavedCH:
	.byte $00
pvCH:
	.byte $00
pvDoCrNext:
	.byte $FF
pPrintSetup:
        copyWord pvSavedCSW, Mon_CSWL
        writeWord Mon_CSWL, _TakiDbgCOUT
        lda Mon_WNDBTM
        sta pvSavedWNDBTM
        lda Mon_WNDTOP
        sta pvSavedWNDTOP
        lda Mon_CH
        sta pvSavedCH
        lda Mon_CV
        sta pvSavedCV
        lda #kDebugNumRegLines
        sta Mon_WNDTOP
        lda #24 ; total # lines on screen
        sta Mon_WNDBTM
        lda #23 ; last line #
        sta Mon_CV
        lda pvCH
        sta Mon_CH
        jsr Mon_VTAB
        rts

pPrintTeardown:
	copyWord Mon_CSWL, pvSavedCSW
        lda Mon_CH
        sta pvCH
        lda pvSavedWNDBTM
        sta Mon_WNDBTM
        lda pvSavedWNDTOP
        sta Mon_WNDTOP
        lda pvSavedCH
        sta Mon_CH
        lda pvSavedCV
        sta Mon_CV
        jsr Mon_VTAB
        rts

;; WARNING! This expects to be called somewhere within a
;; TakiEffectDo_ environ (for Zero Page setup)
.export _TakiDbgPrintCmdBufWordAtY
_TakiDbgPrintCmdBufWordAtY:
        TakiBranchUnlessFlag_ flagDebugActive, :+
        tya
        pha
        
        ; find the end of the word
        jsr _TakiCmdFindWordEnd
        sta @delimRestore
        sty @yRestore
        lda #0
        sta (kZpCmdBufL),y

	; find low byte of name
	pla ; copy original y into acc,
        pha ; still leaving it on stack
        clc
        adc kZpCmdBufL
        pha
        ; find high byte of name
        lda kZpCmdBufH
        adc #0 ; for carry
        tay
        pla
        jsr TakiDbgPrint

@delimRestore = * + 1
        lda #$FF ; OVERWRITTEN
@yRestore = * + 1
	ldy #$FF ; OVERWRITTEN
        sta (kZpCmdBufL),y

        pla
        tay
:
	rts

.export _TakiDbgCheckKey
_TakiDbgCheckKey:
	pha
        ; exit early if debug not active
        TakiBranchIfFlag_ flagDebugActive, @check
        pla
@unhandled:
        sec
        rts ; EXIT
@check:
        pla
	cmp #$C0	; '@' ?
        beq @DebugMode	; yes: debug mod
        sec
        rts ; EXIT
@DebugMode:
	jsr _TakiIoGetKey
@CkPl:	cmp #$AB	; '+'?
	bne @handled	; no: return, handled
@AdvFrm:
        ; We received a '+' - that means, proceed
        ; until next animation frame.
        lda #0
        sta _TakiVarEffectFrameTicked
@NoFlip:TakiSetFlag_ flagInInput
        TakiEffectDo_ _TakiTick
        TakiUnsetFlag_ flagInInput
        lda _TakiVarEffectFrameTicked
	beq @NoFlip ; no: do another tick
        jmp @DebugMode  ; yes: go back to (paused) key processing
@handled:
	; Not a debug key, return (but handled)
        clc
        rts
