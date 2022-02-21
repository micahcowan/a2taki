.macpack apple2

.export ASoftProg, ASoftEnd

ASoftProg:
scrcode "CALL ",.sprintf("%d",$8000),":REM  MOVE APPLESOFT",$0D
scrcode "10 R$=CHR$(ASC(",'"',"R",'"',")-64)",$0D
;scrcode "50 HOME",$0D
scrcode "95 PRINT ",'"',"THIS ISN'T INCLUDED",'"',$0D
scrcode "100 CALL ",.sprintf("%d",$8003)
scrcode   ":REM INIT TAKI",$0D
.if 1
scrcode "101 CALL ",.sprintf("%d",$800F)
scrcode   ":REM TAKI DEBUG MODE",$0D
.endif
scrcode "102 PRINT ",'"',"1234567890123456789012345678901234567890",'"',';',$0D
scrcode "103 ?:?",$0D
scrcode "105 PRINT ",'"',"HELLO, THIS IS AN EXAMPLE",'"',$0D
scrcode "110 PRINT ",'"',"OF A ",'"',';',$0D
scrcode "120 PRINT R$;",'"',"S< SCANNING >",'"',";R$;",$0D
scrcode "130 PRINT ",'"'," WORD",'"',":?:?",$0D
scrcode "171 ?:?:?",'"',"FAKE PROMPT:",'"'
scrcode  ":INPUT ",'"',']','"',";A$",$0D

scrcode "172 REM DISABLE EXIT-ON-PROMPT",$0D
scrcode "175 POKE ",.sprintf("%d",$808D),", 0",$0D
scrcode "176 POKE ",.sprintf("%d",$808E),", 0",$0D

.if 0
scrcode "135 REM CHECKS FOR CR HANDLING IN INPUT",$0D
scrcode "140 ? ",'"',"SENTENCE INTERRUPTED BY INPUT",'"',$0D
scrcode "145 ?",$0D
scrcode "150 ? ",'"',"SENTENCE INTERRUPTED BY GETKEY",'"',$0D
scrcode "152 FOR I=1 TO 450:NEXT",$0D
scrcode "155 HTAB(1):VTAB(8):INPUT ",'"',"INPUT:",'"',";A$",$0D
scrcode "160 ? ",'"',"INPUT GOT: <",'"',";A$;",'"',">",'"',$0D
scrcode "170 HTAB(1):?",'"',"GET",'"',";:GET A$",$0D
scrcode "171 ?:?:?",'"',"FAKE PROMPT:",'"'
scrcode  ":INPUT ",'"',']','"',";A$",$0D

scrcode "172 REM DISABLE EXIT-ON-PROMPT, RUN THE MONITOR",$0D
scrcode "175 POKE ",.sprintf("%d",$808E),", 0",$0D
scrcode "180 CALL-151",$0D
scrcode "190 ? ",'"',"INPUT",'"',";:INPUT A$",$0D
scrcode "200 GOTO 180",$0D
.endif

scrcode "RUN",$0D
ASoftEnd: