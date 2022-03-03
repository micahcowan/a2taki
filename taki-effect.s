.include "forthish.inc"
TAKI_INTERNAL=1
.include "taki-public.inc"
I_AM_TAKI_EFFECT=1
.include "taki-internal.inc"

.include "taki-effect.inc"
.include "taki-debug.inc"

.macpack apple2

.export _TakiVarActiveEffectsNum
_TakiVarActiveEffectsNum:
	.byte $00
; alloc table: tracks the ENDs of allocation!
; Start of alloc for first effect is always
; start of the storage area itself.
.export _TakiEffectTablesStart
_TakiEffectTablesStart:

.export _TakiVarEffectAllocTable
_TakiVarEffectAllocTable = _TakiEffectTablesStart

.export _TakiVarEffectCounterTable
_TakiVarEffectCounterTable = _TakiEffectTablesStart + 2

.export _TakiVarEffectCounterInitTable
_TakiVarEffectCounterInitTable = _TakiEffectTablesStart + 4

.export _TakiVarEffectDispatchTable
_TakiVarEffectDispatchTable = _TakiEffectTablesStart + 6

.export _TakiEffectTablesEnd
_TakiEffectTablesEnd = _TakiEffectTablesStart + 8

; actual table of table addresses:
.res (_TakiEffectTablesEnd - _TakiEffectTablesStart)

; Setup zero page for effect actions.
; Set TakiEffectSetupFn to your fn addr
; before invoking
.export _TakiEffectSetupAndDo
_TakiEffectSetupAndDo:
	; Save various things to stack
        pha
        txa
        pha
        tya
        pha
        
        ldy #kZpStart	; Save ZP items
@Lp:    lda $00,y
        pha
        iny
        cpy #kZpEnd
        bne @Lp
        
        ; Copy CmdBuf location to ZP
        lda #$00
        sta kZpCmdBufL
        lda TakiVarCommandBufferPage
        sta kZpCmdBufH
        
        ; Copy effect tables to ZP
        ; (assumes we keep same order internally!)
        ldy #$00
@LpZp:	lda _TakiEffectTablesStart,y
        sta kZpEffTablesStart,y
        iny
        cpy #1 + kZpEffTablesEnd - kZpEffTablesStart
        bne @LpZp
        
        ; Copy saved registers to ZP
        ;  
        ;pick_ kZpEnd-kZpStart, 3
        ;  ^ ca65 doesn't like, for some reason
        pick_ $1D, 3
        pla
        tay
        sty kZpY
        pla
        tax
        stx kZpX
        pla
        sta kZpAcc
        
        ; Copy status flags
        lda _TakiVarStatusFlags
        sta TakiVarFlags

.export _TakiEffectSetupFn
_TakiEffectSetupFn = * + 1
	jsr $1000
        
        ; Restore various things to stack
        ldy #kZpEnd-1	; Restore ZP items
@Lp:    pla
        sta $00,y
        dey
        cpy #kZpStart
        bcs @Lp
        
        ; Restore registers
        pla
        tay
        pla
        tax
        pla
        
        rts

.export _TakiSetupForEffectY
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

.export _TakiEffectInitializeDirect
_TakiEffectInitializeDirect:
	lda _TakiVarActiveEffectsNum
        asl	; times 2 to count words
        tay
        
        ; Mark "in progress" to prevent screen scrolling
        TakiSetFlag_ flagAnimationActive
        
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
        sta TAKI_ZP_EFF_STORAGE_H
        dey
        lda #$00
        sta TAKI_ZP_EFF_STORAGE_L
        beq @FinishAlloc ; always
@PrevEffAlloc:
	dey ; y -= 3, to get prev eff's end
        dey
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
        
        lda #TAKI_DSP_INIT
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
.export _TakiEffectInitializeDirectFn

.export _TakiEffectDispatchCur
_TakiEffectDispatchCur:
	ldy _TakiVarActiveEffectsNum
        dey
        jsr _TakiSetupForEffectY
        
        tya
        asl ; lookup by words
        tay
        lda (kZpEffDispatchTbl),y
        sta @Dispatch+1
        iny
        lda (kZpEffDispatchTbl),y
        sta @Dispatch+2
        
        tya ; Y is at high byte
        pha
        lda TakiVarDispatchEvent
@Dispatch:
        jsr $1000 ; OVERWRITTEN
        
        pla
        tay ; Y is at high byte
        ; save allocations
        lda kZpCurEffStorageEndH
        sta (kZpEffAllocTbl),y
        dey
        lda kZpCurEffStorageEndL
        sta (kZpEffAllocTbl),y
	rts

pvTickMode:
	.byte TAKI_DSP_UNTICK
pvPendingFlip:
	.byte $00
.export _TakiTick
_TakiTick:
        TakiBranchUnlessFlag_ flagInTick, @NotInTick
        rts
@NotInTick:
	TakiSetFlag_ flagInTick
        ; Run all effect ticks
        lda _TakiVarActiveEffectsNum
        beq @SkipFlip
        ldy #0
        sty pvPendingFlip
        inc TakiVarTickNum
@TickLoop:
        jsr _TakiSetupForEffectY
        
        tya
        asl
        tay ; y *= 2, for tables-of-addresses
        
        ; handle the counter
        sec
        lda (kZpEffCtrValTbl),y
        sbc #1
        sta (kZpEffCtrValTbl),y
        bcs @NoTrip
        iny ; borrow from high byte
        lda (kZpEffCtrValTbl),y
        sbc #0
        sta (kZpEffCtrValTbl),y
        dey
        bcs @NoTrip
        ; counter underflowed!
        ; reset the counter
        lda (kZpEffCtrInitTbl),y
        sta (kZpEffCtrValTbl),y
        iny
        lda (kZpEffCtrInitTbl),y
        sta (kZpEffCtrValTbl),y
        dey
        ; mark tick (vs untick), and the pending flip
        lda #$ff
        sta pvPendingFlip
        lda #TAKI_DSP_TICK
        sta pvTickMode
@NoTrip:
        
        lda (kZpEffDispatchTbl),y
        sta @pEffJsr+1
        iny
        lda (kZpEffDispatchTbl),y
        sta @pEffJsr+2
        
        ldy kZpCurEffect
        lda pvTickMode
@pEffJsr:
	jsr $1000 ; OVERWRITTEN

        lda #TAKI_DSP_UNTICK
        sta pvTickMode
        ldy kZpCurEffect
        iny
	cpy _TakiVarActiveEffectsNum
	bne @TickLoop

@TickLoopDone:
        bit pvPendingFlip
        bpl @SkipFlip
        
        ; We've a pending page flip - loop
        ; through all the effects again for drawing!ldy #0
        ldy #$00
@DrawLoop:
        jsr _TakiSetupForEffectY
        
        tya
        asl
        tay ; y *= 2, for tables-of-addresses
        
        lda (kZpEffDispatchTbl),y
        sta @pEffDrawJsr+1
        iny
        lda (kZpEffDispatchTbl),y
        sta @pEffDrawJsr+2
        
        ldy kZpCurEffect
        lda #TAKI_DSP_DRAW
@pEffDrawJsr:
	jsr $1000

        ldy kZpCurEffect
        iny
	cpy _TakiVarActiveEffectsNum
	bne @DrawLoop

@DrawLoopDone:
	jsr _TakiIoPageFlip
@SkipFlip:
        jsr _TakiDbgDrawBadge
        
        TakiUnsetFlag_ flagInTick
        
        rts

pDbgNoWordEnd:
	scrcode "EFFECT NAME END NOT FOUND"
        .byte 0

;; _TakiEffectFind
;;
;; Assumes running under TakiEffectDo_.
;; 
;; Traverses available effects, looking for a name match
;; against the Taki command buffer starting at position
;; designated by register y.
;;
;; If successful: returns with carry unset,
;; y at next token, x pointing in
;; _TakiBuiltinEffectsTable at the
;; found dispath entry.
;;
;; If unsuccesful: returns with carry set,
;; y where it was on entry.
;;
;; Uses acc, x and y.
.export _TakiEffectFind
_TakiEffectFind:
	sty @SavedY
        
        ; Find how long the command word is
        jsr _TakiCmdFindWordEnd
        cpy #0
        bne @FoundEnd
        ; We never found the end of a word -
        ; yell and exit.
        TakiDbgPrint_ pDbgNoWordEnd
        jmp @NoEffFound
@FoundEnd:
	; Save the found word length.
	tya
        sec
        sbc @SavedY
        sta @WordLn
        
        ; save start of word, for comparisons
        lda kZpCmdBufL
        clc
        adc @SavedY
        sta kZpEffSpecial2
        lda kZpCmdBufH
        adc #0 ; handle carry
        sta kZpEffSpecial3

        lda #$00
@FindEffLp:
	cmp #.lobyte(_TakiNumBuiltinEffects)
        beq @NoEffFound
        
        asl ; double it so it points at words.
        tax
        
        ; Get the effect's dispatch addr
        ; into the zero page
	lda _TakiBuiltinEffectsTable,x
        sta kZpEffSpecial0
        inx
        lda _TakiBuiltinEffectsTable,x
        sta kZpEffSpecial1
        ; X is now at the high byte
        
        ; skip backwards, past words "flag" and "configAddr"
        ; to a tag name character count
        lda kZpEffSpecial0
        sec
        sbc #$05
        sta kZpEffSpecial0
        bcs :+	; need to borrow?
        lda kZpEffSpecial1 ; handle borrow
        sbc #$00
        sta kZpEffSpecial1
:
	ldy #$00 ; get the value there into y
	lda (kZpEffSpecial0),y
        cmp @WordLn ; does it match our word length?
        bne @NextEffect ; no: try next effect
        
        ; YES: eff name same len as our word
        
        ; step back by that many bytes to start of eff name
        lda kZpEffSpecial0
        sec
        sbc (kZpEffSpecial0),y
        sta kZpEffSpecial0
        bcs :+	; need to borrow?
        lda kZpEffSpecial1 ; handle borrow
        sbc #$00
        sta kZpEffSpecial1
:
        ldy @WordLn ; y -> past end of word
@TagCmpLoop:
        dey
        bmi @EffFound ; checked all the chars? found it!
        lda (kZpEffSpecial2),y
        cmp (kZpEffSpecial0),y
        bne @NextEffect
        beq @TagCmpLoop
        
@NextEffect:
	inx ; check next entry
        txa
        lsr ; halve it so it refers to number-of-entries
        
        jmp @FindEffLp
@NoEffFound:
        ldy @SavedY
        sec
        jmp @rts
@EffFound:
	;   -- X is at the high byte of dispatch handler
        ;      so decrement it
        dex
        ; set y to next token
        lda @SavedY
        clc
        adc @WordLn
        tay
@FindNxtTok:
	lda (kZpCmdBufL),y
        cmp #$A0 ; SPC
        bne @AtNxtTok
        iny
        bne @FindNxtTok ; "always"
@AtNxtTok:
        ; clear carry to indicate success
        clc
@rts:
	rts
@SavedY:
	.byte 0
@WordLn:
	.byte 0
