TAKI_INTERNAL=1
.include "taki-public.inc"
I_AM_TAKI_CMD=1
.include "taki-internal.inc"

.macpack apple2

.include "taki-debug.inc"
.include "taki-util.inc"

.include "a2-monitor.inc"
.include "forthish.inc"

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

;; _TakiIoCtrlExecCmd
;;
;; Expects ZP set up via TakiEffectDo_
;;
;; Attempts to execute the command found in the command buffer,
;; as collected from _TakiIoCtrlReadCmd
.export _TakiIoCtrlExecCmd
_TakiIoCtrlExecCmd:
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
        sta _TakiEffectInitializeDirectFn
        sty _TakiEffectInitializeDirectFn+1
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
        sta _TakiEffectInitializeDirectFn
        inx ; now get high byte
        lda _TakiBuiltinEffectsTable,x
	sta _TakiEffectInitializeDirectFn+1
@runInit:
        jsr _TakiEffectInitializeDirect
        
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
        beq @skipUnh
        TakiDbgPrint_ pEffModeUnhandled
@skipUnh:
	; immediately send ENDCOLLECT
        jsr _TakiEffectEndCollect
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
	; x has right value
        ; forward y while SPC
        lda (kZpCmdBufL),y
        cmp #$A0 ; SPC
        bne @done
        iny
        bne @FOUND ; "always"
@done:
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
