CSWL = $36

.segment "IOFIRM"
.org $FDED

COUT:
    JMP (CSWL)
COUT1:
    BRK
