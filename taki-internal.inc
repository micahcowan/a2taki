.ifndef TAKI_INTERNAL_INC_
TAKI_INTERNAL_INC_=1

;; used with _TakiStatusFlags
flagAnimationActive = 1
flagDebugActive     = flagAnimationActive << 1
flagInInput         = flagDebugActive << 1
flagTicksPaused     = flagInInput << 1
flagInGETLN         = flagTicksPaused << 1
flagInTick          = flagInGETLN << 1
flagInDebugPrint    = flagInTick << 1

.macro TakiSetFlag_ flag
    pha
    lda _TakiVarStatusFlags
    ora #flag
    sta _TakiVarStatusFlags
    pla
.endmacro

.macro TakiUnsetFlag_ flag
    pha
    lda _TakiVarStatusFlags
    and #.lobyte(~(flag))
    sta _TakiVarStatusFlags
    pla
.endmacro

.macro TakiBranchIfFlag_ flag, dest
    lda #flag
    bit _TakiVarStatusFlags
    bne dest
.endmacro

.macro TakiBranchUnlessFlag_ flag, dest
    lda #flag
    bit _TakiVarStatusFlags
    beq dest
.endmacro

;; taki.s
.ifndef I_AM_TAKI
.import _TakiVarStatusFlags
.import _TakiMoveASoft
.import _TakiInit
.import _TakiExit
.import _TakiDelay
.endif

;; taki-debug.s
.ifndef I_AM_TAKI_DEBUG
.import _TakiDbgInit
.import _TakiDbgExit
.import _TakiDbgPrint
.import _TakiDbgVarPrintStr
.import _TakiDbgVarInDebug
.import _TakiDbgCOUT
.import _TakiDbgUndrawBadge
.import _TakiDbgDrawBadge
.import _TakiDbgPrintCmdBufWordAtY
.endif

;; taki-effect.s
.ifndef I_AM_TAKI_EFFECT
.import _TakiVarActiveEffectsNum
.import TakiEffectTablesStart
.import _TakiVarEffectAllocTable
.import _TakiVarEffectCounterTable
.import _TakiVarEffectCounterInitTable
.import _TakiVarEffectDispatchTable
.import TakiEffectTablesEnd
.import _TakiEffectSetupAndDo
.import _TakiEffectSetupFn
.import _TakiSetupForEffectY
.import _TakiEffectInitializeDirect
.import _TakiEffectInitializeDirectFn
.import _TakiEffectCollectA
.import _TakiEffectEndCollect
.import _TakiTick
.import _TakiEffectFind
.endif

;; taki-io.s
.ifndef I_AM_TAKI_IO
.import _TakiOut
.import _TakiIn
.import _TakiIoPageTwoBasCalc
.import _TakiIoDoubledOut
.import _TakiIoClearPageTwo
.import _TakiIoPageFlip
.import _TakiIoSetPageOne
.import _TakiIoSetPageTwo
.import _TakiIoCollectUntilCtrlQ
.import _TakiIoCollectWord
.endif

;; taki-cmd.s
.ifndef I_AM_TAKI_CMD
.import _TakiCmdFindWordEnd
.import _TakiIoCtrlExecCmd
.import _TakiCmdFind
.endif

;; taki.cfg
.import _TakiNumBuiltinEffects
.import _TakiBuiltinEffectsTable

.ifndef I_AM_TAKI_PUBLIC
.import _TakiIndirect ; taki-public.s
.endif

.macro maybe_import name
    .ifndef name
        .import name
    .endif
.endmacro

;; effects
maybe_import TE_NONE
maybe_import TE_Scan
maybe_import TE_Spinner

.delmacro maybe_import

;;;; Less general, more Taki-specific facilities

.include "taki-effect.inc"

kZpStart		= $60
kZpCurEffStorageL	= TAKI_ZP_EFF_STORAGE_L	; $66
kZpCurEffStorageH	= TAKI_ZP_EFF_STORAGE_H	; $67
kZpCurEffStorageEndL	= TAKI_ZP_EFF_STORAGE_END_L ; $68
kZpCurEffStorageEndH	= TAKI_ZP_EFF_STORAGE_END_H ; $69
kZpCmdBufL		= TAKI_ZP_CMDBUF_L ; $6A
kZpCmdBufH		= TAKI_ZP_CMDBUF_H ; $6B
kZpDispatchMode		= TAKI_ZP_DSP_MODE ; $6C
kZpAcc			= TAKI_ZP_ACC ; $6D
kZpX			= TAKI_ZP_X ; $6E
kZpY			= TAKI_ZP_Y ; $6F
kZpEffSpecial0		= TAKI_ZP_EFF_SPECIAL_0 ; $70
kZpEffSpecial1		= TAKI_ZP_EFF_SPECIAL_1 ; $71
kZpEffSpecial2		= TAKI_ZP_EFF_SPECIAL_2 ; $72
kZpEffSpecial3		= TAKI_ZP_EFF_SPECIAL_3 ; $73
kZpCurEffect		= $74
kZpEffTablesStart	= $75
kZpEffAllocTbl		= kZpEffTablesStart
kZpEffCtrValTbl		= kZpEffTablesStart + 2
kZpEffCtrInitTbl	= kZpEffTablesStart + 4
kZpEffDispatchTbl	= kZpEffTablesStart + 6

kZpEffTablesEnd		= kZpEffTablesStart + 8
kZpEnd			= kZpEffTablesEnd

; Make space in zero page for effect stuff
;   NOTE: users of this macro must import the relevant
;   symbols
.macro TakiEffectDo_ fn
	pha
        lda #<fn
        sta _TakiEffectSetupFn
        lda #>fn
        sta _TakiEffectSetupFn+1
        pla
        
        jsr _TakiEffectSetupAndDo
.endmacro

; Initialize an effect instance
;   NOTE: users of this macro must import the relevant
;   symbols
.macro TakiEffectInitializeDirect_ effAddr
	pha
	lda #<effAddr
        sta _TakiEffectInitializeDirectFn
        lda #>effAddr
        sta _TakiEffectInitializeDirectFn+1
        pla
	TakiEffectDo_ _TakiEffectInitializeDirect
.endmacro

; Initialize an effect instance
;   NOTE: users of this macro must import the relevant
;   symbols
.macro TakiEffectInitializeAX_
        sta _TakiEffectInitializeDirectFn
        stx _TakiEffectInitializeDirectFn+1
	TakiEffectDo_ _TakiEffectInitializeDirect
.endmacro

.endif ; TAKI_INTERNAL_INC_
