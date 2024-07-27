; taki-os-none: implements OS-specific features
;  when NO OS IS LOADED (bare firmware BASIC).
; This would be the situation if Taki (and the
;  program using it) were loaded directly into
;  memory without a DOS (e.g. from tape cassette).

.include "a2-monitor.inc"
.include "taki-util.inc"
.include "taki-public.inc"

I_AM_TAKI_OS_FOO = 1
.include "taki-internal.inc"

.export _TakiInit
_TakiInit:
    jsr _TakiBareInit
    
    ; Protect Taki from BASIC data
    lda TakiVarEffectsAllocStartPage
    ; Set HIMEM
    sta Mon_MEMSIZE+1
    sta Mon_FRETOP+1
    lda #0
    sta Mon_MEMSIZE
    sta Mon_FRETOP
    
    ; Set up CSW and KSW
    writeWord Mon_CSWL, TakiOut
    writeWord Mon_KSWL, TakiIn
    jsr $3EA ; reconnect DOS

    ; Indicate success
    lda #0
    sta TakiVarInitStatus
    rts
