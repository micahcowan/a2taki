.macpack apple2

.include "taki-public.inc"

.export ASoftProg, ASoftEnd

.feature string_escapes

LINE_NUMBER .set 10

.macro line arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9
scrcode .concat(.sprintf("%d ", LINE_NUMBER),arg1), arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9
scrcode $0D
LINE_NUMBER .set LINE_NUMBER+10
.endmacro

.macro lineP arg1, arg2, arg3, arg4, arg5, arg6
line "? ",'"',arg1,'"', arg2, arg3, arg4, arg5, arg6
.endmacro

.macro lineTAKI arg1, arg2, arg3, arg4, arg5, arg6
line "? T$;",'"',arg1,'"', arg2, arg3, arg4, arg5, arg6
.endmacro

ASoftProg:
    .incbin "SINE.DEMO.BAS"
    .byte $8D
    .byte "RUN", $8D
ASoftEnd:
