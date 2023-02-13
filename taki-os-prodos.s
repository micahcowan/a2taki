; taki-os-prodos: implements OS-specific features
;  for ProDOS.

.macpack apple2

.include "a2-monitor.inc"
.include "taki-util.inc"
.include "taki-public.inc"

I_AM_TAKI_OS_FOO = 1
.include "taki-internal.inc"

; ProDOS Addresses
GETBUFR = $BEF5
VECTOUT = $BE30
VECTIN  = $BE32

.export _TakiInit
_TakiInit:
	jsr _TakiBareInit
        
        ; Protect Taki from BASIC data
        lda #$96 ; bottom of BASIC.SYSTEM, should be our top
        sec
        sbc TakiVarEffectsAllocStartPage
        jsr GETBUFR
        bcs @oom
        cmp TakiVarEffectsAllocStartPage
        bne @bad
        
        ; Set up CSW and KSW
        writeWord VECTOUT, TakiOut
        writeWord VECTIN, TakiIn

        ; Indicate success
        lda #0
        sta TakiVarInitStatus
	rts
@oom:
        lda #<FailMsg
        ldy #>FailMsg
        jsr PrintStr
        lda #<OomMsg
        ldy #>OomMsg
        jsr PrintStr
        lda #3
        sta TakiVarInitStatus
        rts
@bad:
        lda #<FailMsg
        ldy #>FailMsg
        jsr PrintStr
        lda #<BadMsg
        ldy #>BadMsg
        jsr PrintStr
        lda #2
        sta TakiVarInitStatus
        rts

FailMsg:
        scrcode "!!!PRODOS ALLOC FAILED!!!", $0D
        .byte 0
OomMsg:
        scrcode "COULD NOT ALLOCATE BUFFERS", $0D
        .byte 0
BadMsg:
        scrcode "SOMETHING ELSE WAS ALLOCATED", $0D
        scrcode "IN AN AREA NEEDED BY TAKI.", $0D
        .byte 0

PrintStr:
        sta @str
        sty @str+1
@lp:    
@str = * + 1
        lda $1234 ; addr overwritten at start
        beq @out
        jsr Mon_COUT
        inc @str
        bne @lp
        inc @str+1
        bne @lp
@out:   rts
