.macpack apple2

.export ASoftProg, ASoftEnd

LINE_NUMBER .set 10

.macro line arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9
scrcode .concat(.sprintf("%d ", LINE_NUMBER),arg1), arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9
LINE_NUMBER .set LINE_NUMBER+10
.endmacro

ASoftProg:
scrcode "CALL ",.sprintf("%d",$8000),":REM  MOVE APPLESOFT",$0D
line "CALL ",.sprintf("%d",$8003)
scrcode   ":REM INIT TAKI",$0D
line "T$=CHR$(ASC(",'"',"T",'"',")-64)"
scrcode ":REM CONTROL-T",$0D
line "Q$=CHR$(ASC(",'"',"Q",'"',")-64)"
scrcode ":REM CONTROL-S",$0D
;scrcode "50 HOME",$0D
line "PRINT ",'"',"THIS ISN'T INCLUDED",'"',$0D
.if 1
line "CALL ",.sprintf("%d",$800F)
scrcode   ":REM TAKI DEBUG MODE",$0D
.endif
line "PRINT ",'"',"1234567890123456789012345678901234567890",'"',';',$0D
line "?:?",$0D
line "PRINT ",'"',"HELLO, THIS IS AN EXAMPLE",'"',$0D
line "PRINT ",'"',"OF A ",'"',';',$0D
line "PRINT T$;",'"',"MARK SCAN(FDLY=10 PAUSE=180)",$0D
line "PRINT ",'"',"< SCANNING >",'"',";Q$;",$0D
line "PRINT ",'"'," WORD",'"',":?",$0D
line "PRINT ",'"',"NOTHING HAPPENS",'"',';',$0D
line "PRINT T$;",'"',"WORD EMPH",'"',":REM BAD EFFECT",$0D
line "PRINT ",'"',"HERE",'"',":PRINT",$0D
line "PRINT T$",'"',"OR HERE",'"',":REM BAD CMD",$0D
line "PRINT ",'"',"OH, AND ALSO YOU MAY BE INTERESTED",'"',$0D
line "PRINT ",'"',"TO FIND THAT HERE IS ",'"',';',$0D
line "PRINT T$;",'"',"WORD SCAN",$0D
line "PRINT ",'"',"ANOTHER SUCH WORD",'"',":?:?",$0D

line "PRINT T$;",'"',"INSTANT SPINR",'"',$0D

line "REM DISABLE EXIT-ON-PROMPT",$0D
line "POKE ",.sprintf("%d",$808D),", 0",$0D
line "POKE ",.sprintf("%d",$808E),", 0",$0D
line "? ",'"',"PROGRAM EXIT (ANIMATIONS REMAIN)",'"',$0D

scrcode "RUN",$0D
ASoftEnd: