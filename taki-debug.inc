.include "taki-util.inc"

.macro TakiDbgPrint_ strAddr
    bit TakiVarDebugActive
    bpl :+

    pha
    tya
    pha

    lda #<strAddr
    ldy #>strAddr
    jsr TakiDbgPrint

    pla
    tay
    pla

    :
.endmacro
