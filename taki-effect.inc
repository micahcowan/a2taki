.ifndef _TAKI_EFFECT_INC_
_TAKI_EFFECT_INC_ = 1

TAKI_DSP_INIT		= 0
TAKI_DSP_COLLECT	= 1
TAKI_DSP_ENDCOLLECT	= 2
TAKI_DSP_DESTROY	= 3
TAKI_DSP_TICK		= 4
TAKI_DSP_UNTICK		= 5	; "idle" tick, for delay-smoothing
TAKI_DSP_DRAW		= 6	; draw, whether ticked or not
				; (someone somewhere ticked)
TAKI_DSP_USER_INPUT	= 7

;; Effects Zero-Page Resources
;; 
;; When an effect's dispatch routine is called,
;; various convenient values are placed in
;; the zer page; some of them can be modified
;; to communicate things back to Taki.
;;
;; ZERO PAGE ITEMS:
;;  $00.05	(reserved - text page BAS info?)
;;  $06.07	Start of this effect's allocated storage
;;  $09.09	End of this effect's allocated storage
;;  $0A.0B	Taki's command buffer
;;  $0C		Dispatch mode (also in A on entry)
;;
;; The storage end pointer can be incremented as needed
;; (as long as the high byte doesn't exceed the value at
;; TakiVarEffectsAllocEndPage!), but only when in the
;; TAKI_DSP_INIT, TAKI_DSP_COLLECT, or TAKI_DSP_ENDCOLLECT
;; modes, to expand the storage allocated to your effect.
;;
;; The command buffer in ($04.$05) is used
;; to communicate to the effect during TAKI_DSP_INIT
;; any user-supplied config string.

TAKI_ZP_EFF_STORAGE_L		= $66
TAKI_ZP_EFF_STORAGE_H		= $67
TAKI_ZP_EFF_STORAGE_END_L	= $68
TAKI_ZP_EFF_STORAGE_END_H	= $69
TAKI_ZP_CMDBUF_L		= $6A
TAKI_ZP_CMDBUF_H		= $6B
TAKI_ZP_DSP_MODE		= $6C
TAKI_ZP_ACC			= $6D
TAKI_ZP_X			= $6E
TAKI_ZP_Y			= $6F
TAKI_ZP_EFF_SPECIAL_0		= $70
TAKI_ZP_EFF_SPECIAL_1		= $71
TAKI_ZP_EFF_SPECIAL_2		= $72
TAKI_ZP_EFF_SPECIAL_3		= $73

; config var types
TAKI_CFGTY_FN			= $00
TAKI_CFGTY_BYTE			= $01
TAKI_CFGTY_WORD			= $02

; Used to declare an effect and provide metadata
.macro TAKI_EFFECT effectFn, name, flags, configAddr
.scope
pTag:
	scrcode name
pTagEnd:
	.byte pTagEnd - pTag
        .word configAddr
	.word flags 
	.condes effectFn, 6
	.export effectFn
	effectFn:
.endscope
.endmacro

kVarSpaceNeeded .set 0
.macro declVar varName, sz
    varName = kVarSpaceNeeded
    kVarSpaceNeeded .set kVarSpaceNeeded + sz
.endmacro

; perform some operation on an effect variable
.macro effOpVar op, var
	ldy #(var)
        op (TAKI_ZP_EFF_STORAGE_L),y
.endmacro

; set y to a variable position (constant) and fetch byte
.define effGetVar effOpVar lda,
; set y to a variable position (constant) and set byte
.define effSetVar effOpVar sta,

; increment y and get byte to acc
.macro effGetNext
	iny
        lda (TAKI_ZP_EFF_STORAGE_L),y
.endmacro

; increment y and set byte from acc
.macro effSetNext
	iny
        sta (TAKI_ZP_EFF_STORAGE_L),y
.endmacro

; leave y where it is and get byte from acc
.macro effGetCur
        lta (TAKI_ZP_EFF_STORAGE_L),y
.endmacro

; leave y where it is and set byte from acc
.macro effSetCur
        sta (TAKI_ZP_EFF_STORAGE_L),y
.endmacro

; move storage-end ptr to allocate N additional bytes
.macro effAllocate amt
	clc
        lda TAKI_ZP_EFF_STORAGE_END_L
        adc #(amt)
        sta TAKI_ZP_EFF_STORAGE_END_L
        bcc :+
        inc TAKI_ZP_EFF_STORAGE_END_H
:
.endmacro

; move storage-end ptr to allocate a number of addt'l bytes
;  specified in the accumulator
.macro effAllocateA
	clc
        adc TAKI_ZP_EFF_STORAGE_END_L
        sta TAKI_ZP_EFF_STORAGE_END_L
        bcc :+
        inc TAKI_ZP_EFF_STORAGE_END_H
:
.endmacro

; increment storage to accommodate an additional byte
.macro effAllocateOne
	inc TAKI_ZP_EFF_STORAGE_END_L
        bne :+
        inc TAKI_ZP_EFF_STORAGE_END_H
:
.endmacro

; append accumulator value to end of storage space
.macro effAppendByte
	ldy #0
        sta (TAKI_ZP_EFF_STORAGE_END_L),y
        effAllocateOne
.endmacro

.endif ; _TAKI_EFFECT_INC_
