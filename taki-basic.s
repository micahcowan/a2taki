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
;
line "HTAB 5:VTAB 5"
lineTAKI "MARK SANIM(FDLY=0)"
lineP "",":REM TIMER VALUES"
lineP "0,2-,0TSR 4,0TSR",":REM ANIMATION CODE"
lineP "MICAH ",";:REM TEXT"
line "? Q$;"
;
lineTAKI "MARK SANIM(FDLY=0)"
lineP "",":REM TIMER VALUES"
lineP "0,2-,0T,32+,SR 4,0T,32+,SR",":REM ANIMATION CODE"
lineP "COWAN ",";:REM TEXT"
line "? Q$;"
;
lineTAKI "MARK SANIM(FDLY=0)"
lineP "",":REM TIMER VALUES"
lineP "0,2-,0T,64+,SR 4,0T,64+,SR",":REM ANIMATION CODE"
lineP "PRODUCTIONS ",";:REM TEXT"
line "? Q$;"
;
lineTAKI "MARK SANIM(FDLY=0)"
lineP "",":REM TIMER VALUES"
lineP "0,2-,0T,96+,SR 4,0T,96+,SR",":REM ANIMATION CODE"
lineP "PRESENTS ",";:REM TEXT"
line "? Q$;"
;
line "HTAB 18:VTAB 14"
lineTAKI "MARK SANIM(FDLY=0)"
lineP "",":REM TIMER VALUES"
lineP "16,0TSR 0R",":REM ANIMATION CODE"
lineP "TAKI",";:REM TEXT"
line "? Q$;"
;
lineP ""
line "REM SET SCROLL/WNDTOP"
line "POKE 34, PEEK(37)"

;lineTAKI "INSTANT SPINR(FDLY=3)"
;
;line "?:?:?"
;line "INPUT ",'"',"CMD>",'"',";A$"
;
;scrcode "9000 ? T$;",'"',"DELAY 255",'"',$0D
;scrcode "9010 GOTO 9000",$0D
;
line "REM DISABLE EXIT-ON-PROMPT"
line "POKE ",.sprintf("%d",$608A),", 0"

.if 0
lineP "HELLO, THIS IS AN EXAMPLE"
lineP "OF A ",';'
lineTAKI "MARK SCAN(FDLY=10)"
lineP "< SCANNING >",";Q$;"
lineP " WORD"
lineP
lineP "NOTHING HAPPENS ",';'
lineTAKI "WORD EMPH",":REM BAD EFFECT"
lineP "HERE"
lineP
lineTAKI "OR HERE",":REM BAD CMD"
lineP "OH, AND ALSO YOU MAY BE INTERESTED"
lineP "TO FIND THAT HERE IS ",';'
lineTAKI "WORD SCAN(FDLY=96)"
lineP "ANOTHER SUCH WORD",":?:?"

line "FOR I=5 TO 1 STEP -1"
line "HTAB 1"
line "? I;",'"',"...",'"',';'
lineTAKI "DELAY 168"
line "NEXT"
line "HTAB 1:PRINT ",'"',"      ",'"',':',"HTAB 1"

lineTAKI "CONFIG 0 FDLY=5 PAUSE=180"

;line "INPUT ",'"',"INTERNAL",'"',";A$",$0D

line "REM DISABLE EXIT-ON-PROMPT"
line "POKE ",.sprintf("%d",$608D),", 0"
line "POKE ",.sprintf("%d",$608E),", 0"
lineP "PROGRAM EXIT (ANIMATIONS REMAIN)"
.endif

scrcode "RUN",$0D
ASoftEnd: