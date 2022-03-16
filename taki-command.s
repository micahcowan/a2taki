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
	.byte 5		; num entries
        tstr "INSTANT"
        tstr "WORD"
        tstr "MARK"
        tstr "CONFIG"
        tstr "DELAY"

pvCmdInstant = 0
pvCmdWord    = pvCmdInstant + 1
pvCmdMark    = pvCmdWord + 1
pvCmdTagNeedsInit = pvCmdMark + 1 ; commands below this number
                                  ; require an init
pvCmdConfig  = pvCmdTagNeedsInit
pvCmdDelay   = pvCmdConfig + 1

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
        cmp #$BD		; '='
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

;; _TakiCommandExec
;;
;; Expects ZP set up via TakiEffectDo_
;;
;; Attempts to execute the command found in the command buffer,
;; as collected from _TakiIoCtrlReadCmd
.export _TakiCommandExec
_TakiCommandExec:
        ; try to find the effect name
        writeWord Mon_CSWL, _TakiOut
        ldy #0 ; set y to start of cmd buf
        jsr _TakiCmdFind
        bcc @cmdFound
        jmp @NoCmdFound
@cmdFound:
        stx @effMode
        cpx #pvCmdTagNeedsInit
        bcs @NoInit
        ; Needs Init (and effect name)
        jsr _TakiEffectFind
        bcs @NoEffFound ; no effect found? jump to a dummy setup
        jmp @InitAndCollect
@NoInit:
        cpx #pvCmdConfig
        beq @config
        cpx #pvCmdDelay
        beq @delay
        jmp @unhandledOrInstant
@config:
        ; CONFIG command
        jsr _TakiCmdReadNumW ; get effect number
        pla ; toss out high byte
        pla
        cmp _TakiVarActiveEffectsNum
        bcc @DoConfig ; num we got is valid for an effect
        ; Not a a valid effect #
        ; XXX report the error
        rts
@DoConfig:
	pha
	tya
        pha
        swap_
        pla
        tay
        jsr _TakiSetupForEffectY
        pla
        tay
        jmp _TakiCmdHandleConfig
        ; END
@delay:
	jsr _TakiCmdReadNumW
        pla ; high
        pla ; low
        jsr _TakiDelay
        rts
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
        lda #$21
        jsr _TakiIoDoubledOut
	TakiDbgPrint_ pCmdNotFoundMsgPre
        jsr _TakiDbgPrintCmdBufWordAtY
        TakiDbgPrint_ pCmdNotFoundMsgPost
        rts
@InitAndCollect:
	; Initialize an effect instance
        ; from the found entry
	;   -- X is at the low byte of dispatch handler
        lda _TakiBuiltinEffectsTable,x
        sta _TakiEffectInitializeFn
        inx ; now get high byte
        lda _TakiBuiltinEffectsTable,x
	sta _TakiEffectInitializeFn+1
@runInit:
	tya
        pha
        jsr _TakiEffectInitialize
        ; Dispatch INIT event
        lda #TAKI_DSP_INIT
        sta TakiVarDispatchEvent
        jsr _TakiEffectDispatchCur
        ; Handle any config
        pla
        tay
        lda (kZpCmdBufL),y
        cmp #$A8 ; '('
        bne @HandleCollectMode
        iny
        jsr _TakiCmdHandleConfig
        
@HandleCollectMode:
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
        bne @nope
        iny
        lda (kZpCmdBufL),y
        cmp #$C4 ; 'D'
        bne @nope
        iny
        lda (kZpCmdBufL),y
        cmp #$CC ; 'L'
        bne @nope
        iny
        lda (kZpCmdBufL),y
        cmp #$D9 ; 'Y'
        bne @nope
        iny
        ;
        
        jsr _TakiCmdSkipSpaces
        cmp #$BD ; '=' ?
        ; if not, handle error!
        bne @nope
	pla
	iny
        jsr _TakiCmdSkipSpaces
        jsr _TakiCmdReadNumW
        tya
        pha
        rot_
        ; stack: regY numL numH (top)
        lda kZpCurEffect
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
        clc
        ;
        rts
@nope:
	pla
        tya
	sec
	rts

_TakiCmdHandleConfig:
@nextWd:
	jsr _TakiCmdSkipSpaces
	; Did we reach the end of config string?
        lda (kZpCmdBufL),y
        beq @doneBridge; NUL
        cmp #$A9 ; ')'
        beq @doneBridge
        cmp #$8D ; 'CR'
        beq @doneBridge
        ; special handling for "FDLY"
        jsr _TakiCmdHandleConfigFDLY
        bcc @nextWd ; this word already handled!
        
        ; Find the current effect's config table
        ; XXX should cache this, instead of recalc
        ; every iteration...
        sty @SavedY
        ;   Start with the dsp handler:
        ldy kZpCurEffect
        asl ; times 2 for words
        lda (kZpEffDispatchTbl),y ; low byte
        sec
        sbc #4 ; back two words to cfg addr
        sta kZpEffSpecial0
        iny
        lda (kZpEffDispatchTbl),y
        sbc #0 ; for borrow
        sta kZpEffSpecial1
        ldy #1
        lda (kZpEffSpecial0),y ; read high byte
@doneBridge:
        beq @done ; if it's 0, THERE IS NO CONFIG. done.
        pha
        dey
        lda (kZpEffSpecial0),y ; low byte
        ; reset zpSpecial to the cfg table
        sta kZpEffSpecial0
        pla
        sta kZpEffSpecial1
        ldy @SavedY
        jsr _TakiCmdConfigFind
        bcs @badWord
        ;
        stx @foundIdx
        ; we found our word!
        jsr _TakiCmdSkipSpaces
        lda (kZpCmdBufL),y
        cmp #$BD ; '='
        bne @badWord
        iny
        jsr _TakiCmdSkipSpaces
        ; for NOW, we're just assuming everything's numbers.
        ; grab a number.
        jsr _TakiCmdReadNumW
        sty @SavedY
        ;
        lda pvNumEntries ; we just saved this in the find fn,
        		 ; might as well get it from there.
        inc kZpEffSpecial0 ; start of var types
        bne :+
        inc kZpEffSpecial1
:
        ldy #0 ; where in types table
        ldx #0 ; where in alloc table
@traverseTypes:
	; As of the time of this comment's writing,
        ; a config var's type is also the number of
        ; bytes it takes up!
        cpy @foundIdx
        beq @arrived
        lda (kZpEffSpecial0),y
        beq @zero
        cmp #1
        beq @one
        ; two
        inx
@one:   inx
@zero:  iny
        bne @traverseTypes
@arrived:
        lda (kZpEffSpecial0),y ; what type is OUR config
                               ; (/how many bytes?)
        pha
        txa
        tay ; alloc -> y reg
        pla
        beq @jmpBack ; we don't handle FN type yet
        cmp #1
        beq @one1 ; single-byte config
        ; word-sized config
        pla ; high
        iny
        sta (kZpCurEffStorageL),y ; set up during INIT dispatch?
        dey
        jmp @low
@one1:  pla
@low:	pla
	sta (kZpCurEffStorageL),y
@jmpBack:
        ldy @SavedY
        jmp @nextWd
@badWord:
        ; else: this wasn't a config word, and wasn't FDLY
        TakiDbgPrint_ pConfigJunkStr
        tya
        ldy kZpCmdBufH
    	jsr TakiDbgPrint
        ; XXX should print what effect generated this msg
@done:
	rts
@SavedY:
	.byte 0
@foundIdx:
	.byte 0

pConfigJunkStr:
	scrcode "CFG JUNK: "
        .byte 0

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

_TakiCmdConfigFind:
	sty pvSavedY
        ; config table is in zpSpecial
        ;  set numEntries
        ldy #0
        lda (kZpEffSpecial0),y
        sta pvNumEntries
        ;  now jump to start of config labels
        clc
        adc #1
        adc kZpEffSpecial0
        sta pvTableAddr
        lda #0
        adc kZpEffSpecial1 ; for carry
        sta pvTableAddr+1
	jmp pFindInTable

.export _TakiFindCmdWordInTable
_TakiFindCmdWordInTable:
	; table addr is on stack, behind our return address.
        sty pvSavedY
        
        swapW_
;@tableAddr = kZpEffSpecial0
        pla ; high byte of table addr
        sta pvTableAddr+1
        pla ; low byte of table addr
        sta pvTableAddr
        
        ; Record number of table entries
        jsr pGetTableChar
        sta pvNumEntries
        inc pvTableAddr
        bne :+
        inc pvTableAddr
:
pFindInTable:
        ldx #0
        ldy pvSavedY
@CheckWord:
	cpx pvNumEntries
        bcs @EndOfTable ; reached the end of table; not found
        jsr pGetTableChar
        beq @CheckDelim
        cmp (kZpCmdBufL),y
        bne @FindNextWord
@NextChar:
	inc pvTableAddr ; still in the running
        bne :+
        inc pvTableAddr
:	iny
        bne @CheckWord ; "always"
@CheckDelim:
	; Reached end of tok - is it end of cmd buf word too?
        lda (kZpCmdBufL),y
        jsr _TakiCmdIsDelim
        bcc @FOUND
        bcs @NotThisWord
@FindNextWord:
        inc pvTableAddr
        bne :+
        inc pvTableAddr+1
:	ldy pvSavedY
	jsr pGetTableChar
@NotThisWord:
	bne @FindNextWord
@CheckNextWord:
	inc pvTableAddr
        bne :+
        inc pvTableAddr+1
:
	inx
        ldy pvSavedY
        jmp @CheckWord ; always
@EndOfTable:
	sec
        ldy pvSavedY
        rts
@FOUND:
	jsr _TakiCmdSkipSpaces
	clc
	rts
pGetTableChar:
pvTableAddr = * + 1
	lda $1000 ; OVERWRITTEN
        rts
pvSavedY:
	.byte 0
pvNumEntries:
	.byte 0
