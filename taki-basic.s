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
line "HOME"
lineP
lineP
lineTAKI "WORD DOOR"
lineP "DOOR"
lineP
lineP
lineP
lineP
myLoop = LINE_NUMBER
line "HTAB 1:VTAB 12"
line "GET A$"
line "IF ASC(A$) = 3 THEN END"
line "DO=NOT DO"
line "IF DO<>0 THEN DO=1"
lineP "DO: ",";DO"
lineTAKI "CONFIG 0 OPEN=",";DO"
line .concat("GOTO ",.sprintf("%d",myLoop))
.endif

scrcode "RUN",$0D
ASoftEnd:
