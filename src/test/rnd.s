.export rnd, _rnd
.import _RNDH, _RNDL

RNDH = _RNDH
RNDL = _RNDL
_rnd = rnd

rnd:
     LDA RNDH
     BNE skp
     CMP RNDL
     ADC #0
skp:
     AND #$7F
     STA RNDH
     LDY #$11
lp:
     LDA RNDH
     ASL
     CLC
     ADC #$40
     ASL
     ROL RNDL
     ROL RNDH
     DEY
     BNE lp
     RTS
