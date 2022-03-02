.ifndef TAKI_PUBLIC_INC_
TAKI_PUBLIC_INC_ = 1

.macro maybe_import name
    .ifndef name
        .import name
    .endif
.endmacro

.macro TF_BRANCH_IF_FLG flag, dest
    lda #flag
    bit TakiVarFlags
    bne dest
.endmacro

.macro TF_BRANCH_UNLESS_FLG flag, dest
    lda #flag
    bit TakiVarFlags
    beq dest
.endmacro

TF_ANIMATION_ACTIVE = 1
TF_DEBUG_ACTIVE     = 2
TF_IN_INPUT         = 4

maybe_import TakiStart
maybe_import TakiVarReleaseVersion
maybe_import TakiVarEffectsAllocNumPages
maybe_import TakiVarMaxActiveEffects
maybe_import TakiVarDefaultCountdown
maybe_import TakiVarEffectsAllocStartPage
maybe_import TakiVarEffectsAllocEndPage
maybe_import TakiVarCommandBufferPage
maybe_import TakiVarOrigCSW
maybe_import TakiVarOrigKSW
maybe_import TakiVarExitPrompts
maybe_import TakiVarIndirectFn
maybe_import TakiVarCurPageBase
maybe_import TakiVarNextPageBase
maybe_import TakiVarFlags
maybe_import TakiVarTickNum

maybe_import TakiDbgPrint
.ifndef TAKI_INTERNAL
maybe_import TakiInit
maybe_import TakiExit
maybe_import TakiDbgInit
maybe_import TakiDbgExit
maybe_import TakiDbgCOUT
maybe_import TakiDbgUndrawBadge
maybe_import TakiDbgDrawBadge
maybe_import TakiIn
maybe_import TakiOut
maybe_import TakiDelay
maybe_import TakiIoPageTwoBasCalc
maybe_import TakiIoClearPageTwo
maybe_import TakiIoDoubledOut
.endif

.delmacro maybe_import

.endif ; TAKI_PUBLIC_INC_
