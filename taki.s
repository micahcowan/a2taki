;#resource "apple2.rom"
;#link "taki-startup.s"
;#link "taki-debug.s"
;#link "taki-io.s"
;#link "taki-basic.s"
;#link "taki-public.s"
;#link "load-and-run-basic.s"
;#resource "taki.cfg"
;#define CFGFILE taki.cfg
;#resource "NAMING.md"

.macpack apple2

.import TakiVarNextPageBase, TakiVarTicksPaused, TakiVarOrigKSW, TakiVarOrigCSW

.import _TakiIoDoubleDo, _TakiIoDoubledOut, _TakiIoClearPageTwo
.import _TakiIoPageTwoBasCalc, _TakiOut, _TakiIn, _TakiIoPageFlip
.import _TakiIoSetPageOne, _TakiIoSetPageTwo

.import DebugInit, DebugExit, DebugPrint, DebugDrawBadge, DebugUndrawBadge

.include "taki-util.inc"
.include "a2-monitor.inc"
.include "taki-debug.inc"

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
	jsr Mon_HOME
	jsr _TakiIoClearPageTwo
        DebugInit_
        ; save away CSW, KSW
        copyWord TakiVarOrigCSW, Mon_CSWL
        copyWord TakiVarOrigKSW, Mon_KSWL
        lda #$00
        sta TakiVarTicksPaused
        jsr _TakiIoSetPageOne
        jmp _TakiResume

; Pause Taki I/O processing, restoring any
; previous I/O hooks. Mostly useful for talking
; to a DOS
.export _TakiPause
_TakiPause:
        bit $C054	; force page one
	DebugUndrawBadge_
	copyWord Mon_CSWL, TakiVarOrigCSW
        copyWord Mon_KSWL, TakiVarOrigKSW
	rts

; Restore Taki I/O hooks, saving away current ones,
; resuming Taki processing 
.export _TakiResume
_TakiResume:
	writeWord Mon_KSWL, _TakiIn
        writeWord Mon_CSWL, _TakiOut
	rts

.export _TakiExit
_TakiExit:
	DebugExit_
        jsr _TakiPause
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
	jsr _TakiIoPageFlip
        
        pla
        tax
        pla
        tay
        pla
        rts
