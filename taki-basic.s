.macpack apple2

.export ASoftProg, ASoftEnd

ASoftProg:
scrcode "CALL ",.sprintf("%d",$8000),":REM  MOVE APPLESOFT",$0D
scrcode "5 CALL ",.sprintf("%d",$8003)
scrcode   ":REM INIT TAKI",$0D
scrcode "10 T$=CHR$(ASC(",'"',"T",'"',")-64)"
scrcode ":REM CONTROL-T",$0D
scrcode "20 Q$=CHR$(ASC(",'"',"Q",'"',")-64)"
scrcode ":REM CONTROL-S",$0D
;scrcode "50 HOME",$0D
scrcode "95 PRINT ",'"',"THIS ISN'T INCLUDED",'"',$0D
.if 1
scrcode "101 CALL ",.sprintf("%d",$800F)
scrcode   ":REM TAKI DEBUG MODE",$0D
.endif
scrcode "102 PRINT ",'"',"1234567890123456789012345678901234567890",'"',';',$0D
scrcode "103 ?:?",$0D
scrcode "105 PRINT ",'"',"HELLO, THIS IS AN EXAMPLE",'"',$0D
scrcode "110 PRINT ",'"',"OF A ",'"',';',$0D
scrcode "120 PRINT T$;",'"',"MARK SCAN(FDLY=10 PAUSE=180)",$0D
scrcode "125 PRINT ",'"',"< SCANNING >",'"',";Q$;",$0D
scrcode "130 PRINT ",'"'," WORD",'"',":?",$0D
scrcode "131 PRINT ",'"',"NOTHING HAPPENS",'"',';',$0D
scrcode "132 PRINT T$;",'"',"WORD EMPH",'"',":REM BAD EFFECT",$0D
scrcode "133 PRINT ",'"',"HERE",'"',":PRINT",$0D
scrcode "134 PRINT T$",'"',"OR HERE",'"',":REM BAD CMD",$0D
scrcode "135 PRINT ",'"',"OH, AND ALSO YOU MAY BE INTERESTED",'"',$0D
scrcode "140 PRINT ",'"',"TO FIND THAT HERE IS ",'"',';',$0D
scrcode "150 PRINT T$;",'"',"WORD SCAN",$0D
scrcode "155 PRINT ",'"',"ANOTHER SUCH WORD",'"',":?:?",$0D

scrcode "172 REM DISABLE EXIT-ON-PROMPT",$0D
scrcode "175 POKE ",.sprintf("%d",$808D),", 0",$0D
scrcode "176 POKE ",.sprintf("%d",$808E),", 0",$0D
scrcode "180 ? ",'"',"PROGRAM EXIT (ANIMATIONS REMAIN)",'"',$0D

scrcode "RUN",$0D
ASoftEnd: