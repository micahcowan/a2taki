.include "taki-util.inc"

.macro TakiDbgPrint_ strAddr
    pha
    tya
    pha

    lda #<strAddr
    ldy #>strAddr
    jsr TakiDbgPrint

    pla
    tay
    pla
.endmacro
