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


.macro TakiEffectInitializeDirect_ effAddr
	lda #<effAddr
        sta _TakiEffectInitializeDirectFn
        lda #>effAddr
        sta _TakiEffectInitializeDirectFn+1
	TakiEffectDo_ _TakiEffectInitializeDirect
.endmacro

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
        TakiEffectInitializeDirect_ TE_Spinner
        
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

; Setup zero page for effect actions.
; Set TakiEffectSetupFn to your fn addr
; before invoking
.export _TakiEffectSetupAndDo
_TakiEffectSetupAndDo:
	; Save various things to stack
        tya		; Save registers
        pha
        txa
        pha
        ldy #$00	; Save ZP items
@Lp:    lda $00,y
        pha
        iny
        cpy #kZpEnd
        bne @Lp
        
        ; Copy various things to ZP
        ldy #$00
@LpZp:	lda TakiEffectTablesStart,y
        sta kZpEffTablesStart,y
        iny
        cpy #1 + kZpEffTablesEnd - kZpEffTablesStart
        bne @LpZp

.export _TakiEffectSetupFn
_TakiEffectSetupFn = * + 1
	jsr $1000
        
        ; Restore various things to stack
        ldy #kZpEnd-1	; Restore ZP items
@Lp:    pla
        sta $00,y
        dey
        bpl @Lp
        pla		; Restore registers
        tax
        pla
        tay
        
        rts

_TakiSetupForEffectY:
	; Set up effect storage start:
        ;  if we're effect 0 it's start of storage
        ;  otherwise it's prev element's 
        sty kZpCurEffect
        sta TAKI_ZP_DSP_MODE
        tya
        asl ; y * 2
        tay

@SetupEffStorage:
	cpy #$00
        bne @NotFirst	; if y != 0 then branch
        sty TAKI_ZP_EFF_STORAGE_L ; storing y (== 0)
        lda TakiVarEffectsAllocStartPage
        sta TAKI_ZP_EFF_STORAGE_H
        jmp @SetupEffStorageEnd
@NotFirst:
	dey ; y now at preceding eff's high byte
        lda (kZpEffAllocTbl),y
        sta TAKI_ZP_EFF_STORAGE_H
        dey
        lda (kZpEffAllocTbl),y
        sta TAKI_ZP_EFF_STORAGE_L
        iny
        iny ; y: back to cur eff
@SetupEffStorageEnd:
	lda (kZpEffAllocTbl),y
        sta TAKI_ZP_EFF_STORAGE_END_L
        iny
        lda (kZpEffAllocTbl),y
        sta TAKI_ZP_EFF_STORAGE_END_H

	ldy kZpCurEffect
        lda TAKI_ZP_DSP_MODE
        rts

_TakiEffectInitializeDirect:
	lda _TakiVarActiveEffectsNum
        asl	; times 2 to count words
        tay
        
        ;; Set values in tables:
        ; dispatch handler in table
        lda _TakiEffectInitializeDirectFn
        sta @DispatchCall+1
        sta (kZpEffDispatchTbl),y
        iny
        lda _TakiEffectInitializeDirectFn+1
        sta @DispatchCall+2
        sta (kZpEffDispatchTbl),y
        ; y is now 1 past
        
        ; end of allocation - initialize with
        ;  start of storage area if eff.num == 0,
        ; otherwise with whatever the end of
        ; allocation was for the previous effect
        ; (which is also the start of the new
        ; effect's allocation, since it hasn't
        ; allocated anything yet)
        cpy #1 ; y is one past, so 1 if we're at 0
        bne @PrevEffAlloc
        ; we're effect 0, use start of storage
        lda TakiVarEffectsAllocStartPage
        sta TAKI_ZP_EFF_STORAGE_END_H
        dey
        lda #$00
        sta TAKI_ZP_EFF_STORAGE_END_L
        beq @FinishAlloc ; always
@PrevEffAlloc:
	dey ; y -= 2, to get prev eff's end
        dey
        lda (kZpEffAllocTbl),y
        sta TAKI_ZP_EFF_STORAGE_L
        iny
        lda (kZpEffAllocTbl),y
        sta TAKI_ZP_EFF_STORAGE_H
        iny ; y at cur eff low byte
@FinishAlloc:
	; Now actually store to effect's alloc entry
	lda TAKI_ZP_EFF_STORAGE_L
        sta TAKI_ZP_EFF_STORAGE_END_L
        sta (kZpEffAllocTbl),y
        iny
        lda TAKI_ZP_EFF_STORAGE_H
        sta TAKI_ZP_EFF_STORAGE_END_H
        sta (kZpEffAllocTbl),y
        ; y is one past
        
        ; Initialize counter init and counter
        lda TakiVarDefaultCountdown+1
        sta (kZpEffCtrInitTbl),y
        lda #$00
        sta (kZpEffCtrValTbl),y
        dey
        sta (kZpEffCtrValTbl),y
        lda TakiVarDefaultCountdown
        sta (kZpEffCtrInitTbl),y
        ; y is at eff
       	tya ; save y to stack
        sta kZpCurEffect ; and also  to ZP
        pha
        
        ; Increment number of effects
        inc _TakiVarActiveEffectsNum
        
        lda TAKI_DSP_INIT
        ; Call effect's dispatch handler
@DispatchCall:
	jsr $1000 ; address is overwritten
        pla
        tay ; restore y, is at eff
        
        ; Save any allocation change
        lda TAKI_ZP_EFF_STORAGE_END_L
        sta (kZpEffAllocTbl),y
        iny
        lda TAKI_ZP_EFF_STORAGE_END_H
        sta (kZpEffAllocTbl),y
        rts
_TakiEffectInitializeDirectFn = @DispatchCall + 1


pvPendingFlip:
	.byte $00
.export _TakiTick
_TakiTick:
        ; Run all effect ticks
        lda _TakiVarActiveEffectsNum
        beq @EffLoopDone
        ldy #0
        sty pvPendingFlip
@EffLoop:
        jsr _TakiSetupForEffectY
        
        tya
        asl
        tay ; y *= 2, for tables-of-addresses
        
        ; handle the counter
        sec
        lda (kZpEffCtrValTbl),y
        sbc #1
        sta (kZpEffCtrValTbl),y
        bcs @SkipDispatch
        iny ; borrow from high byte
        lda (kZpEffCtrValTbl),y
        sbc #0
        sta (kZpEffCtrValTbl),y
        dey
        bcs @SkipDispatch
        
        ; counter underflowed!
        ; reload initial counter values,
        ; and run dispatch!
        lda #$ff
        sta pvPendingFlip
        lda (kZpEffCtrInitTbl),y
        sta (kZpEffCtrValTbl),y
        iny
        lda (kZpEffCtrInitTbl),y
        sta (kZpEffCtrValTbl),y
        dey
        
        lda (kZpEffDispatchTbl),y
        sta @pEffJsr+1
        iny
        lda (kZpEffDispatchTbl),y
        sta @pEffJsr+2
        
        ldy kZpCurEffect
        tay
        lda #TAKI_DSP_TICK
@pEffJsr:
	jsr $1000
@SkipDispatch:
        ldy kZpCurEffect
        iny
	cpy _TakiVarActiveEffectsNum
	bne @EffLoop

@EffLoopDone:
        jsr _TakiDbgDrawBadge
        bit pvPendingFlip
        beq @SkipFlip
	jsr _TakiIoPageFlip
@SkipFlip:
        
        rts
