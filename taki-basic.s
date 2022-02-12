.macpack apple2

.export ASoftProg, ASoftEnd

ASoftProg:
scrcode "CALL 32768:REM  START TAKI",$0D
scrcode "10 R$=CHR$(ASC(",'"',"R",'"',")-64)",$0D
;scrcode "50 HOME",$0D
scrcode "95 PRINT ",'"',"THIS ISN'T INCLUDED",'"',$0D
scrcode "100 CALL ",.sprintf("%d",$8003)
scrcode   ":REM INIT TAKI",$0D
scrcode "105 PRINT ",'"',"HELLO, THIS IS AN EXAMPLE",'"',$0D
scrcode "110 PRINT ",'"',"OF A ",'"',';',$0D
scrcode "120 PRINT R$;",'"',"SSCANNING",'"',";R$;",$0D
scrcode "130 PRINT ",'"'," WORD",'"',$0D

scrcode "135 REM CHECKS FOR CR HANDLING IN INPUT",$0D
scrcode "140 ? ",'"',"SENTENCE INTERRUPTED BY INPUT",'"',';',$0D
scrcode "150 HTAB(1):INPUT ",'"',"INPUT:",'"',";A$",$0D
scrcode "160 ? ",'"',"SENTENCE INTERRUPTED BY GETKEY",'"',';',$0D
scrcode "170 HTAB(1):?",'"',"GET",'"',";:GET A$",$0D
scrcode "RUN",$0D
ASoftEnd: