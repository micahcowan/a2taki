TAKI_INTERNAL=1
.include "taki-public.inc"
I_AM_TAKI_CMD=1
.include "taki-internal.inc"

.macpack apple2

.include "taki-debug.inc"
.include "taki-util.inc"

.include "a2-monitor.inc"
.include "forthish.inc"
.include "math-ca65.inc"

_TakiCmdTable:
	.byte 3		; num entries
        tstr "INSTANT"
        tstr "WORD"
        tstr "MARK"

pvCmdInstant = 0
pvCmdWord    = 1
pvCmdMark    = 2

;; _TakiCmdIsDelim
;; returns with carry unset if acc is a delimiter,
;; set otherwise
.export _TakiCmdIsDelim
_TakiCmdIsDelim:
        ; is it a terminator?
        beq @IsDelim		; NUL
        cmp #$8D		; CR
        beq @IsDelim
        cmp #$A0		; SP
        beq @IsDelim
        cmp #$A8		; '('
        beq @IsDelim
        ; no terminator - increment and check next char
        sec
        rts
@IsDelim:
	clc
	rts

;; _TakiCmdFindWordEnd
;;
;; Expects ZP set up via TakiEffectDo_
;;
;; Jumps the y register to the end of the current word
;; in the command buffer - or sets y to 0 if no end found
;;
;; Uses acc, y
.export _TakiCmdFindWordEnd
_TakiCmdFindWordEnd:
@FindWordEnd:
	lda (kZpCmdBufL),y
        ; is it a terminator?
        jsr _TakiCmdIsDelim
        bcc @HaveTerminator
        ; not terminator - increment and check next char
        iny
        bne @FindWordEnd
@HaveTerminator:
	rts

.export _TakiCmdSkipSpaces
pCmdSkipSpacesPre:
        iny
_TakiCmdSkipSpaces:
	; x has right value
        ; forward y while SPC
        lda (kZpCmdBufL),y
        cmp #$A0 ; SPC
        beq pCmdSkipSpacesPre
        ;
	rts

;; _TakiIoCtrlExecCmd
;;
;; Expects ZP set up via TakiEffectDo_
;;
;; Attempts to execute the command found in the command buffer,
;; as collected from _TakiIoCtrlReadCmd
.export _TakiCommandExec
_TakiCommandExec:
        ; try to find the effect name
        ldy #0 ; set y to start of cmd buf
        jsr _TakiCmdFind
        bcs @NoCmdFound
        stx @effMode
        jsr _TakiEffectFind
        bcc @EffFound
@NoEffFound:
	; Print not-found message
        TakiDbgPrint_ pEffNotFoundMsgPre
        jsr _TakiDbgPrintCmdBufWordAtY
        TakiDbgPrint_ pEffNotFoundMsgPost
	; We use a dummy effect so collection still takes place
        ; XXX we should probably remove this as soon as
        ; collection is done.
	lda #<TE_NONE
	ldy #>TE_NONE
        sta _TakiEffectInitializeFn
        sty _TakiEffectInitializeFn+1
        jmp @runInit
@NoCmdFound:
	TakiDbgPrint_ pCmdNotFoundMsgPre
        jsr _TakiDbgPrintCmdBufWordAtY
        TakiDbgPrint_ pCmdNotFoundMsgPost
        writeWord Mon_CSWL, _TakiOut
        rts
@EffFound:
	; Initialize an effect instance
        ; from the found entry
	;   -- X is at the low byte of dispatch handler
        lda _TakiBuiltinEffectsTable,x
        sta _TakiEffectInitializeFn
        inx ; now get high byte
        lda _TakiBuiltinEffectsTable,x
	sta _TakiEffectInitializeFn+1
@runInit:
        jsr _TakiEffectInitialize
        lda (kZpCmdBufL),y
        cmp #$A8 ; '('
        bne @finalInit
        iny
        jsr _TakiCmdHandleConfig
@finalInit:
        lda #TAKI_DSP_INIT
        sta TakiVarDispatchEvent
        jsr _TakiEffectDispatchCur
        
@effMode = * + 1
	lda #$FF ; OVERWRITTEN
@ckMark:
        cmp #pvCmdMark
        bne @ckWord
	writeWord Mon_CSWL, _TakiIoCollectUntilCtrlQ
        rts
@ckWord:cmp #pvCmdWord
	bne @unhandledOrInstant
	writeWord Mon_CSWL, _TakiIoCollectWord
        rts
@unhandledOrInstant:
	; Is this instant, or unhandled?
        cmp #$00
        beq @skipUnh
        TakiDbgPrint_ pEffModeUnhandled
@skipUnh:
	; immediately send ENDCOLLECT
        lda #TAKI_DSP_COLLECT
        sta TakiVarDispatchEvent
        jsr _TakiEffectDispatchCur
        writeWord Mon_CSWL, _TakiOut
        rts

pEffModeUnhandled:
	scrcode "!!! UNHANDLED EFFECT MODE !!!",$0D
        .byte $00

pEffNotFoundMsgPre:
	scrcode "BAD EFF NAME ",'"'
	.byte $00

pEffNotFoundMsgPost:
	scrcode '"'," - IGNORE COLLECT",$0D
	.byte $00

pCmdNotFoundMsgPre:
	scrcode "BAD COMMAND ",'"'
	.byte $00

pCmdNotFoundMsgPost:
	scrcode '"',$0D
	.byte $00

_TakiCmdReadNumW:
	; XXX support reading HEX if first char is $!
        
        ; set up A and Y to point to high and low bytes
        ; of buffer addr
        lda kZpCmdBufL
        pha
        lda kZpCmdBufH
        pha
        jsr rdDec16u ; from math-ca65
        
        ; Y points past number in str, and
        ; number is on stack, high byte pulls first
        tya ; move Y onto stack so it oesn't get munged
        pha
        rollb1_ 5 ; move return address to just below
        rollb1_ 5 ; pushed Y
        rotb_
        pla
        tay
	rts

_TakiCmdHandleConfigFDLY:
	tya
        pha
        
        lda (kZpCmdBufL),y
        cmp #$C6 ; 'F'
        bne @cleanup
        iny
        lda (kZpCmdBufL),y
        cmp #$C4 ; 'D'
        bne @cleanup
        iny
        lda (kZpCmdBufL),y
        cmp #$CC ; 'L'
        bne @cleanup
        iny
        lda (kZpCmdBufL),y
        cmp #$D9 ; 'Y'
        bne @cleanup
        iny
        pla ; discard original y position
        ;
        
        jsr _TakiCmdSkipSpaces
        cmp #$BD ; '='
        ; XXX if not, handle error!
        iny
        jsr _TakiCmdSkipSpaces
        jsr _TakiCmdReadNumW
        tya
        pha
        rot_
        ; stack: regY numL numH (top)
        lda _TakiVarActiveEffectsNum
        sec
        sbc #1
        asl ; double for words
        tay
        iny
        pla
        sta (kZpEffCtrInitTbl),y
        dey
        pla
        sta (kZpEffCtrInitTbl),y
        ;
        pla
        tay ; restore Y that points past digits
        ;
        rts
@cleanup:
	pla
        tya
	rts

_TakiCmdHandleConfig:
	jsr _TakiCmdSkipSpaces
        ; special handling for "FDLY"
        jsr _TakiCmdHandleConfigFDLY
	rts

;; _TakiCmdFind
;;
;; Expects ZP set up via TakiEffectDo_
;;
;; Attempts to find the command named at cmd buf + yreg.
.export _TakiCmdFind
_TakiCmdFind:
	lda #<_TakiCmdTable
        pha
        lda #>_TakiCmdTable
        pha
        jsr _TakiFindCmdWordInTable
        rts

.export _TakiFindCmdWordInTable
_TakiFindCmdWordInTable:
	; table addr is on stack, behind our return address.
        sty @savedY
        
        swapW_
;@tableAddr = kZpEffSpecial0
        pla ; high byte of table addr
        sta @tableAddr+1
        pla ; low byte of table addr
        sta @tableAddr
        
        ; Record number of table entries
        jsr @getTableChar
        sta @numEntries
        inc @tableAddr
        bne :+
        inc @tableAddr+1
:

        ldx #0
        ldy @savedY
@CheckWord:
	cpx @numEntries
        bcs @EndOfTable ; reached the end of table; not found
        jsr @getTableChar
        beq @CheckDelim
        cmp (kZpCmdBufL),y
        bne @FindNextWord
@NextChar:
	inc @tableAddr ; still in the running
        bne :+
        inc @tableAddr+1
:	iny
        bne @CheckWord ; "always"
@CheckDelim:
	; Reached end of tok - is it end of cmd buf word too?
        lda (kZpCmdBufL),y
        jsr _TakiCmdIsDelim
        bcc @FOUND
@FindNextWord:
        inc @tableAddr
        bne :+
        inc @tableAddr+1
:	jsr @getTableChar
@NotThisWord:
	bne @FindNextWord
@CheckNextWord:
	inc @tableAddr
        bne :+
        inc @tableAddr+1
:
	inx
        ldy #0
        beq @CheckWord ; always
@EndOfTable:
	sec
        ldy @savedY
        rts
@FOUND:
	jsr _TakiCmdSkipSpaces
	clc
	rts
@getTableChar:
@tableAddr = * + 1
	lda $1000 ; OVERWRITTEN
        rts
@savedY:
	.byte 0
@numEntries:
	.byte 0
