.ifndef MATH_CA65_INC_
MATH_CA65_INC_ = 1

.macro maybe_import name
  .ifndef MATH_CA65_NO_IMPORT
    .import name
  .endif
.endmacro

maybe_import prBin8_A
maybe_import prBin16_AY
maybe_import div10w_AY
maybe_import mul10w_AY
maybe_import prDec16u_AY
maybe_import rdDec16u

.delmacro maybe_import

.endif ; MATH_CA65_INC_
