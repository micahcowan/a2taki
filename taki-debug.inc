.include "taki-util.inc"
.include "taki-public.inc"

.macro TakiDbgPrint_ strAddr
    pha
    TF_BRANCH_UNLESS_FLG TF_DEBUG_ACTIVE, :+
    tya
    pha

    lda #<strAddr
    ldy #>strAddr
    jsr TakiDbgPrint

    pla
    tay
:
    pla
.endmacro
