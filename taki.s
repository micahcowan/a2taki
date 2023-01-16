;#resource "apple2.rom"
;#link "taki-startup.s"
;#link "taki-debug.s"
;#link "taki-effect.s"
;#link "taki-io.s"
;#link "taki-command.s"
;#link "taki-basic.s"
;#link "taki-public.s"
;#link "eff-spinner.s"
;#link "eff-scan.s"
;#link "eff-sineanim.s"
;#link "eff-NONE.s"
;#link "load-and-run-basic.s"
;#link "forthish.s"
;#resource "math-ca65.inc"
;#link "math-ca65.s"
;#link "signlib.s"
;#link "signcalc.s"


;#resource "taki.cfg"
;#define CFGFILE taki.cfg
;#resource "NAMING.md"

.macpack apple2

.include "a2-monitor.inc"
.include "forthish.inc"


.include "taki-util.inc"
.include "taki-effect.inc"
.include "taki-debug.inc"
TAKI_INTERNAL=1
.include "taki-public.inc"
I_AM_TAKI=1
.include "taki-internal.inc"

.export _TakiVarStatusFlags
_TakiVarStatusFlags:
	.byte $00

; Initialize Taki, hijacking input and output
; for special processing (and to send things to both
; text pages)
.export _TakiInit
_TakiInit:
	jsr _TakiMemInit
        
        jsr Mon_HOME
        ;jsr _TakiDbgInit
        ; save away CSW, KSW
        copyWord TakiVarOrigCSW, Mon_CSWL
        copyWord TakiVarOrigKSW, Mon_KSWL
        writeWord Mon_KSWL, _TakiIn
        writeWord Mon_CSWL, _TakiOut
        lda TakiVarEffectsAllocStartPage
        lda #$00
        sta _TakiVarStatusFlags
        sta TakiVarStatusFlags
        sta _TakiVarActiveEffectsNum
        
	rts

.export _TakiExit
_TakiExit:
        jsr _TakiDbgExit
        bit $C054	; force page one
	copyWord Mon_CSWL, TakiVarOrigCSW
        copyWord Mon_KSWL, TakiVarOrigKSW
	rts

.export _TakiReset
_TakiReset:
	lda #0
        sta _TakiVarActiveEffectsNum
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
        sec
        sbc #$01 ; to reserve a page for command buffer
        sta TakiVarCommandBufferPage
        sta $7
        lda #<TakiStart
        ;sta $6 ; will delay until after first calc below
        
        ; Allocate various effect tables:
        ; effect delay counter initial values table
        sec
        sbc $8
        sta $6
        lda $7
        sbc #$0 ; for carry
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
        
        ; Set HIMEM
        sta Mon_MEMSIZE+1
        sta Mon_FRETOP+1
        lda #0
        sta Mon_MEMSIZE
        sta Mon_FRETOP
        
        ; Init current number of effects
        sta _TakiVarActiveEffectsNum
        
        pla
        sta $8
        pla
        sta $7
        pla
        sta $6
        rts

.export _TakiDelay
_TakiDelay:
	pha
	lda #$FF
        sta pvTakiDelayCounter
        pla
pWAIT2:
	pha
pWAIT3:	inc pvTakiDelayCounter
	.repeat 5
          nop
        .endrepeat
        bne pWAIT3
        TakiEffectDo_ _TakiTick
	pla
        sec
	sbc     #$01
	bne     pWAIT2
	rts
pvTakiDelayCounter:
	.byte $00
