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

SCANDEMO=0
SINEDEMO=1
FLUORDEMO=2
PAKKUDEMO=3
BOUNCEDEMO=4

DEMO = BOUNCEDEMO

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

.if DEMO = PAKKUDEMO

line "POKE ",.sprintf("%d",$608A),", 0"
line "POKE ",.sprintf("%d",$608B),", 0"
lineTAKI "INSTANT PAKKU(FDLY=12)"
kLoop = LINE_NUMBER
line "VTAB 18"
line "INPUT A"
line "IF A<0 OR A>3 THEN A=0"
lineTAKI "CONFIG 0 ORIENT=",";A"
line "GOTO ",.sprintf("%d", kLoop)
line "REM DISABLE EXIT-ON-PROMPT"

.elseif DEMO = SINEDEMO
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

.elseif DEMO = BOUNCEDEMO

;line "----------------------------------------"
line "HOME"
lineTAKI "MARK BOUNCE-IN(FDLY=8 FBTW=16)"
lineP " - THE BASEMENT OFFICE - "
lineP
lineP "YOU ARE SITTING IN A BUTT-NUMBINGLY HARD",';'
lineP "CHAIR, AT YOUR WOOD-VENEERED PLASTIC "
lineP "DESK, WHERE THE ",';'
lineP "CONSTANT SPUTTERING",';'
lineP " OF"
lineP "THE OVERHEAD FLUORESCENT LIGHTS IS"
lineP "SLOWLY DRIVING YOU INSANE."
lineP
lineP "UPON YOUR DESK RESTS THE MAGIC ",';'
lineP "STAPLER"
lineP "FROM YESTERDAY, QUIETLY MOCKING YOUR"
lineP "PREVIOUS ATTEMPTS AT PICKING IT UP."
line  "PRINT Q$;"

line "REM SET SCROLL/WNDTOP"
line "POKE 34, PEEK(37)"
line "REM DISABLE EXIT-ON-PROMPT"
line "POKE ",.sprintf("%d",$608A),", 0"


.elseif DEMO = FLUORDEMO

;line "----------------------------------------"
line "HOME"
lineP " - THE BASEMENT OFFICE - "
lineP
lineP "YOU ARE SITTING IN A BUTT-NUMBINGLY HARD",';'
lineP "CHAIR, AT YOUR WOOD-VENEERED PLASTIC "
lineP "DESK, WHERE THE ",';'
.if 1
lineTAKI "MARK FLUORESCENT(FDLY=10)"
lineP "CONSTANT SPUTTERING",";Q$;"
lineP " OF"
.else
lineTAKI "WORD FLUORESCENT(FDLY=10)"
lineP "CONSTANT ",';'
lineTAKI "WORD FLUORESCENT(FDLY=9)"
lineP "SPUTTERING OF"
.endif
lineP "THE OVERHEAD FLUORESCENT LIGHTS IS"
lineP "SLOWLY DRIVING YOU INSANE."
lineP
lineP "UPON YOUR DESK RESTS THE MAGIC ",';'
lineTAKI "WORD CURSED(FDLY=2)"
lineP "STAPLER"
lineP "FROM YESTERDAY, QUIETLY MOCKING YOUR"
lineP "PREVIOUS ATTEMPTS AT PICKING IT UP."

line "REM SET SCROLL/WNDTOP"
line "POKE 34, PEEK(37)"
line "REM DISABLE EXIT-ON-PROMPT"
line "POKE ",.sprintf("%d",$608A),", 0"

.else ; SCANDEMO
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
lineP "ANOTHER SUCH WORD",":?"

line "REM SET SCROLL/WNDTOP"
line "POKE 34, PEEK(37)"

.if 1
line "FOR I=5 TO 1 STEP -1"
line "HTAB 1"
line "? I;",'"',"...",'"',';'
lineTAKI "DELAY 168"
line "NEXT"
line "HTAB 1:PRINT ",'"',"      ",'"',':',"HTAB 1"
.endif

lineTAKI "CONFIG 0 FDLY=5 PAUSE=180"

;line "INPUT ",'"',"INTERNAL",'"',";A$",$0D

line "REM DISABLE EXIT-ON-PROMPT"
line "POKE ",.sprintf("%d",$608A),", 0"
;line "POKE ",.sprintf("%d",$608D),", 0"
;line "POKE ",.sprintf("%d",$608E),", 0"

line "CALL ",.sprintf("%d",$6020)
scrcode   ":REM END TAKI DEBUG",$0D

lineP "PROGRAM EXIT (ANIMATIONS REMAIN)"
.endif

scrcode "RUN",$0D
ASoftEnd:
