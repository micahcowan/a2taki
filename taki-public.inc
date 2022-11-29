.ifndef TAKI_PUBLIC_INC_
TAKI_PUBLIC_INC_ = 1

.macro maybe_import name
    .ifndef name
        .import name
    .endif
.endmacro

.macro TF_ST_BRANCH_IF_FLG flag, dest
    lda #flag
    bit TakiVarStatusFlags
    bne dest
.endmacro

.macro TF_ST_BRANCH_UNLESS_FLG flag, dest
    lda #flag
    bit TakiVarStatusFlags
    beq dest
.endmacro

.macro TF_BEH_BRANCH_IF_FLG flag, dest
    lda #flag
    bit TakiVarBehaviorFlags
    bne dest
.endmacro

.macro TF_BEH_BRANCH_UNLESS_FLG flag, dest
    lda #flag
    bit TakiVarBehaviorFlags
    beq dest
.endmacro

.macro TF_BEH_BRANCH_SET_FLG flag
    lda #flag
    ora TakiVarBehaviorFlags
    sta TakiVarBehaviorFlags
.endmacro

.macro TF_BEH_BRANCH_UNSET_FLG flag
    lda TakiVarBehaviorFlags
    and #~{flag}
    sta TakiVarBehaviorFlags
.endmacro

TF_ST_ANIMATION_ACTIVE = 1
TF_ST_DEBUG_ACTIVE     = 2
TF_ST_IN_INPUT         = 4

TF_BEH_DETECT_HOME     = 1

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
maybe_import TakiVarStatusFlags
maybe_import TakiVarBehaviorFlags
maybe_import TakiVarIndirectFn
maybe_import TakiVarTickNum
maybe_import TakiVarDispatchEvent

maybe_import TakiDbgPrint
.ifndef TAKI_INTERNAL
maybe_import TakiInit
maybe_import TakiExit
maybe_import TakiReset
maybe_import TakiDbgInit
maybe_import TakiDbgExit
maybe_import TakiDbgCOUT
maybe_import TakiDbgUndrawBadge
maybe_import TakiDbgDrawBadge
maybe_import TakiDbgPrintCmdBufWordAtY
maybe_import TakiIn
maybe_import TakiOut
maybe_import TakiDelay
maybe_import TakiIoScreenOut
maybe_import TakiMySetCounter
maybe_import TakiMyGetCounter
maybe_import TakiMySetCounterInit
maybe_import TakiMyGetCounterInit
.endif

.delmacro maybe_import

.endif ; TAKI_PUBLIC_INC_
