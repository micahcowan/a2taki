.ifndef TAKI_PUBLIC_INC_
TAKI_PUBLIC_INC_=1

;; taki.s
.ifndef I_AM_TAKI
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
.import _TakiPreEffAcc
.import _TakiPreEffX
.import _TakiPreEffY
.import _TakiSetupForEffectY
.import _TakiEffectInitializeDirect
.import _TakiEffectInitializeDirectFn
.import _TakiDelay
.import _TakiVarInTick
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

.endif ; TAKI_PUBLIC_INC_
