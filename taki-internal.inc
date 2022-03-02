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
.import _TakiVarActiveEffectsNum
.import TakiEffectTablesStart
.import _TakiVarEffectAllocTable
.import _TakiVarEffectCounterTable
.import _TakiVarEffectCounterInitTable
.import _TakiVarEffectDispatchTable
.import TakiEffectTablesEnd
.import _TakiMoveASoft
.import _TakiInit
.import _TakiExit
.import _TakiEffectSetupAndDo
.import _TakiEffectSetupFn
.import _TakiSetupForEffectY
.import _TakiEffectInitializeDirect
.import _TakiEffectInitializeDirectFn
.import _TakiDelay
.import _TakiTick
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

.endif ; TAKI_INTERNAL_INC_
