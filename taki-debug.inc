.include "taki-util.inc"

DEBUG = 1

.macro DebugPrint_ strAddr
  .if DEBUG
    pha
    writeWord DebugPrintStr, strAddr
    jsr DebugPrint
    pla
  .endif
.endmacro

.macro DebugInit_
  .if DEBUG
    jsr DebugInit
  .endif
.endmacro

.macro DebugExit_
  .if DEBUG
    jsr DebugExit
  .endif
.endmacro

.macro DebugDrawBadge_
  .if DEBUG
    jsr DebugDrawBadge
  .endif
.endmacro

.macro DebugUndrawBadge_
  .if DEBUG
    jsr DebugUndrawBadge
  .endif
.endmacro

