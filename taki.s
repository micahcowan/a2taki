;#resource "apple2.rom"
;#link "taki-startup.s"
;#link "taki-debug.s"
;#link "taki-io.s"
;#link "taki-basic.s"
;#link "taki-public.s"
;#link "load-and-run-basic.s"
;#resource "taki.cfg"
;#define CFGFILE taki.cfg
;#resource "TAKI-TODO"

.macpack apple2

.import PTakiNextPageBase, PTakiTicksPaused, PTakiOrigKSW, PTakiOrigCSW

.import TakiDoubleDo, TakiDoubledOut, TakiClearPage2
.import TakiBASCALC_pageTwo, TakiOut, TakiIn, TakiIoPageFlip
.import TakiIoSetPageOne, TakiIoSetPageTwo

.import DebugInit, DebugExit, DebugPrint, DebugDrawBadge, DebugUndrawBadge

.include "taki-util.inc"
.include "a2-monitor.inc"
.include "taki-debug.inc"

; Reorganize where in memory a BASIC program is
; located (to move it out of the way of the
; second text page - to $C01)
.export TakiMoveASoft
TakiMoveASoft:
	lda #$0C
        sta Mon_TEXTTAB+1
        sta Mon_VARTAB+1
        sta Mon_PRGEND+1
	rts

; Initialize Taki, hijacking input and output
; for special processing (and to send things to both
; text pages)
.export TakiInit
TakiInit:
	jsr Mon_HOME
	jsr TakiClearPage2
        DebugInit_
        ; save away CSW, KSW
        copyWord PTakiOrigCSW, Mon_CSWL
        copyWord PTakiOrigKSW, Mon_KSWL
        lda #$00
        sta PTakiTicksPaused
        jsr TakiIoSetPageOne
        jmp TakiResume

; Pause Taki I/O processing, restoring any
; previous I/O hooks. Mostly useful for talking
; to a DOS
.export TakiPause
TakiPause:
        bit $C054	; force page one
	DebugUndrawBadge_
	copyWord Mon_CSWL, PTakiOrigCSW
        copyWord Mon_KSWL, PTakiOrigKSW
	rts

; Restore Taki I/O hooks, saving away current ones,
; resuming Taki processing 
.export TakiResume
TakiResume:
	writeWord Mon_KSWL, TakiIn
        writeWord Mon_CSWL, TakiOut
	rts

.export TakiExit
TakiExit:
	DebugExit_
        jsr TakiPause
	rts

TakiTickIter:
	.byte $00
TakiTickCounter:
	.byte $01
TakiTickChars:
	scrcode "I/-\"
        .byte $00
.export TakiTick
TakiTick:
	pha
        tya
        pha
        txa
        pha
        
        ldx TakiTickCounter
        ldy TakiTickIter
        dex
        bne @StX
        ldx #$20
        iny
        cpy #4
        bne @StY
        ldy #0
@StY:	sty TakiTickIter
@StX:	stx TakiTickCounter

        lda PTakiNextPageBase
        ora #$03
        sta @DrawSta+2	; modify upcoming sta dest
        lda TakiTickChars,y
@DrawSta:
        sta $7F6
	jsr TakiIoPageFlip
        
        pla
        tax
        pla
        tay
        pla
        rts

.if 0
; not done writing this fn
PrintStr:
PrintStrAddr = PrintStr+1
	lda #1000	; Overwritten before call.
        		; Load next str char. Is NUL?
        beq PSDone	; yes: exit
PSDone: rts
.endif
        
