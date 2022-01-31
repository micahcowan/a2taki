.macpack apple2

.export ASoftProg, ASoftEnd

ASoftProg:
scrcode "100 PRINT ",'"',"HELLO",'"',$0D
scrcode "105 PRINT ",'"',"THIS IS AN EXAMPLE OF A ",'"',';',$0D
scrcode "110 & ",'"',"TAKI LINE SCAN",'"',$0D
scrcode "120 PRINT ",'"',"SCANNING",'"',$0D
scrcode "130 PRINT ",'"'," WORD",'"',$0D
scrcode "RUN",$0D
ASoftEnd: