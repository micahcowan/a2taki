;#resource "apple2.rom"
;#link "taki-startup.s"
;#link "taki-debug.s"
;#link "taki-io.s"
;#link "taki-basic.s"
;#link "taki-public.s"
;#link "eff-spinner.s"
;#link "load-and-run-basic.s"
;#resource "taki.cfg"
;#define CFGFILE taki.cfg
;#resource "NAMING.md"

.macpack apple2

.import TakiStart, TakiVarMaxActiveEffects, TakiVarDefaultCountdown
.import TakiVarEffectsAllocStartPage, TakiVarEffectsAllocEndPage
.import TakiVarEffectsAllocNumPages, TakiVarEffectCounterInitTable
.import TakiVarNextPageBase, TakiVarTicksPaused, TakiVarOrigKSW, TakiVarOrigCSW

.import _TakiIoDoubleDo, _TakiIoDoubledOut, _TakiIoClearPageTwo
.import _TakiIoPageTwoBasCalc, _TakiOut, _TakiIn, _TakiIoPageFlip
.import _TakiIoSetPageOne, _TakiIoSetPageTwo

.import _TakiDbgInit, _TakiDbgExit, _TakiDbgPrint, _TakiDbgDrawBadge, _TakiDbgUndrawBadge

.import TE_Spinner

.include "a2-monitor.inc"
.include "taki-util.inc"
.include "taki-effect.inc"
.include "taki-debug.inc"

_TakiVarActiveEffectsNum:
	.byte $00
; alloc table: tracks the ENDs of allocation!
; Start of alloc for first effect is always
; start of the storage area itself.
.export TakiEffectTablesStart
TakiEffectTablesStart:
_TakiVarEffectAllocTable = TakiEffectTablesStart
_TakiVarEffectCounterTable = TakiEffectTablesStart + 2
_TakiVarEffectCounterInitTable = TakiEffectTablesStart + 4
_TakiVarEffectDispatchTable = TakiEffectTablesStart + 6
.export TakiEffectTablesEnd
TakiEffectTablesEnd = TakiEffectTablesStart + 8

.res (TakiEffectTablesEnd - TakiEffectTablesStart)

; Reorganize where in memory a BASIC program is
; located (to move it out of the way of the
; second text page - to $C01)
.export _TakiMoveASoft
_TakiMoveASoft:
	lda #$0C
        sta Mon_TEXTTAB+1
        sta Mon_VARTAB+1
        sta Mon_PRGEND+1
	rts

; Initialize Taki, hijacking input and output
; for special processing (and to send things to both
; text pages)
.export _TakiInit
_TakiInit:
	jsr _TakiMemInit
        jsr Mon_HOME
	jsr _TakiIoClearPageTwo
        ;jsr _TakiDbgInit
        ; save away CSW, KSW
        copyWord TakiVarOrigCSW, Mon_CSWL
        copyWord TakiVarOrigKSW, Mon_KSWL
        jsr _TakiIoSetPageOne
        writeWord Mon_KSWL, _TakiIn
        writeWord Mon_CSWL, _TakiOut
        lda TakiVarEffectsAllocStartPage
        lda #$00
        sta TakiVarTicksPaused
        sta _TakiVarActiveEffectsNum
        
        ; Demo effect: "spinenr"
        TakiEffectDispatchStart_
        TakiEffectInitializeDirect_ TE_Spinner
        TakiEffectDispatchEnd_
        
	rts

.export _TakiExit
_TakiExit:
        jsr _TakiDbgExit
        bit $C054	; force page one
        jsr _TakiDbgUndrawBadge
	copyWord Mon_CSWL, TakiVarOrigCSW
        copyWord Mon_KSWL, TakiVarOrigKSW
	rts

_TakiMemInit:
	; save $6, $7, $8: use for allocation
        lda $6
        pha
        lda $7
        pha
        lda $8
        pha
        
        lda TakiVarMaxActiveEffects
        asl ; x2 for word-size tables
        sta $8
        ; Initialize $6 and $7 with Taki's start-of-code
        lda #>TakiStart
        sta $7
        lda #<TakiStart
        ;sta $6 ; will delay until after first calc below
        
        ; Allocate various effect tables:
        ; effect delay counter initial values table
        sec
        sbc $8
        sta $6
        lda $7
        sbc #$0
        sta $7
        copyWord _TakiVarEffectCounterInitTable, $6
        ; effect delay counter current values table
        subtractAndSave16_8 $6, $8
        copyWord _TakiVarEffectCounterTable, $6
        ; effect allocations table
        subtractAndSave16_8 $6, $8
        copyWord _TakiVarEffectAllocTable, $6
        ; effect dispatch handlers table
        subtractAndSave16_8 $6, $8
        copyWord _TakiVarEffectDispatchTable, $6
        
        ; Allocate effect allocations area
        sta TakiVarEffectsAllocEndPage ; assumes $7 in acc
        sec
        sbc TakiVarEffectsAllocNumPages
        sta TakiVarEffectsAllocStartPage
        ; Init current number of effects
        lda #0
        sta _TakiVarActiveEffectsNum
        
        pla
        sta $8
        pla
        sta $7
        pla
        sta $6
        rts
        
pvTickIter:
	.byte $00
pvTickCounter:
	.byte $01
pvTickChars:
	scrcode "I/-\"
        .byte $00
.export _TakiTick
_TakiTick:
	pha
        tya
        pha
        txa
        pha
        
        ldx pvTickCounter
        ldy pvTickIter
        dex
        bne @StX
        ldx #$20
        iny
        cpy #4
        bne @StY
        ldy #0
@StY:	sty pvTickIter
@StX:	stx pvTickCounter

        lda TakiVarNextPageBase
        ora #$03
        sta @DrawSta+2	; modify upcoming sta dest
        lda pvTickChars,y
@DrawSta:
        sta $7F6
        jsr _TakiDbgDrawBadge
	jsr _TakiIoPageFlip
        
        pla
        tax
        pla
        tay
        pla
        rts
