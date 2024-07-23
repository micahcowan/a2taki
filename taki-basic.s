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
line "CALL ",.sprintf("%d",$6000)
scrcode   ":REM INIT TAKI",$0D
line "T$=CHR$(ASC(",'"',"T",'"',")-64)"
scrcode ":REM CONTROL-T",$0D
line "Q$=CHR$(ASC(",'"',"Q",'"',")-64)"
scrcode ":REM CONTROL-S",$0D
;scrcode "50 HOME",$0D
.if 1
line "CALL ",.sprintf("%d",$601D)
scrcode   ":REM TAKI DEBUG MODE",$0D
.endif

.if 1

;line "POKE ",.sprintf("%d",$608A),", 0"
;line "POKE ",.sprintf("%d",$608B),", 0"
line "POKE 34,0"
line "HOME"
lineTAKI "MARK BOUNCE-IN(FDLY=7 FBTW=50 SHUF=0)"
line "VTAB 8:HTAB 14"
lineP "MICAH COWAN"
line "HTAB 16"
lineP "PRESENTS"
line "PRINT Q$;"
rptCnt = 5
.repeat rptCnt, I
vert   .set <(I * (256/rptCnt))
horiz  .set <(192 + (I * (256/rptCnt)))
line "VTAB 9:HTAB 18"
lineTAKI "MARK SANIM"
lineP "",": REM  TIMER VALUES"
lineP .sprintf("0,12-,0T%u+SR 4,0T%u+SR",horiz,vert),": REM  ANIMATION CODE"
lineP "TAKI",";: REM  TEXT"
line "PRINT Q$;"
.endrepeat
line "VTAB 20:HTAB 1"
line "INPUT \">\";A$"
.endif

scrcode "RUN",$0D
ASoftEnd:
