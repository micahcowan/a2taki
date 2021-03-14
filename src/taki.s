;; taki.s

.segment "TAKI"
.macpack apple2

MON_COut    = $FDF0
MON_InvFlag = $32
DOS_CSWL    = $AA53
CSWL        = $36

.import __TAKI_START__
.export TakiInit, TakiInitNoInstall, TakiPrint

;; Public interfaces ;;;;;;;;;;;;;;;;;;;

; The following calls are arranged in a stable order,
; so that users will always know where to call them, even if the
; "real" routines they jump to change location.
;
; Users should always use e.g. TakiPrint over Print,
; as Print's location could change from one version to another.
TakiInit:
    JMP Init
TakiInitNoInstall:
    JMP InitNoInstall
TakiPrint:
    JMP Print

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


InstanceDataBuffer = __TAKI_START__ - $100

zpCurrentEffectL = $06
zpCurrentEffectH = $07

.enum   State
        Default
        EffectSelect
        EffectText
.endenum

; Indices to the HIGH byte of an effect's jump table.
.enum   EffectJump
        Init        = 1
        Text        = 3
        TextEnd     = 5
        Tick        = 7
.endenum

.define CTRL(char)  (char - $40 + $80)

; TakiCommandChar (Ctrl-T): Use this to send commands/configure Taki.
.define TakiCommandChar #CTRL('T')
; TakiSelectChar (Ctrl-R): Follow this with a pre-arranged character
; to select the text that follows, to receive a text effect. Text
; is captured for the effect until the next occurrence
; of TakiSelectChar.
.define TakiSelectChar #CTRL('R')

;; Vars
RunOurCSW:
    .byt $4C    ; JMP
vOurCSWL:
    .byt $00
    .byt $00

vState:
    .byt $00

vCurrentEDX:
    .byt $00

;; Tables

; EffectsTable
; 
; Lists all the Effects' jump table addresses, so that they can
; be mapped to a single-byte EDX (Effect Index), used to refer
; to that effect everywhere else.
_EffectsTable:
    EF_Flash_EDX = 2
    .word EF_Flash

    EF_Inverse_EDX = 4
    .word EF_Inverse

    .word $0000

; No effect is allowed to have an EDX of 0 (we need as a sentinel value),
; so we pretend the EffectsTablee actually starts one entry
; (word, = 2 bytes) earlier.
EffectsTable = _EffectsTable - 2

; TODO: This table will be initialized at start and configured by the user
;       but for right now it's hard-coded. Must always have a valid
;       fall-back profile (FLASH) as its first entry.
;
;       For right now, this table looks up directly to an EDX;
;       later it will look up into a configuration string to use for
;       instantiating an effect with a particular configuration.
EffectProfilesTable:
    scrcode 'F'
    .byt EF_Flash_EDX

    scrcode 'I'
    .byt EF_Inverse_EDX

    .byt $00, $00

; EffectInstancesTable
;
; List of indexes into InstanceDataBuffer, $FF-terminated
EffectInstancesTable:
    .res 32, $FF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Init:
    ; Install for DOS 3.3 CSW
    ; (We will be called _by_ DOS's own CSW handler - there's no
    ; reasonable way to avoid this. It will do its own processinig,
    ; and Taki will get the lftovers.)
    ; TODO: support ProDOS, no-DOS (from tape)
    ; TODO: does the DOS_CSWL location depend on the memory in the
    ; machine (for e.g. a "master" DOS disk)?
    LDA #<Print
    STA DOS_CSWL
    LDA #>Print
    STA DOS_CSWL+1
InitNoInstall:
    ; Install ROM CSW as the underlying print routine we pass along to
    LDA #<MON_COut
    STA vOurCSWL
    LDA #>MON_COut
    STA vOurCSWL+1
    ; - fall-through -
PageInit:
    ; Initialize processing state
    LDA #State::Default
    STA vState
    ; TODO: Initialize effect profiles
    ;LDA #$00
    ;STA EffectProfilesTable

    ; Initialize effect instances
    ; TODO: run a cleanup/destructor on old instances first?
    LDA #$00
    STA EffectInstancesTable

    RTS

Print:
    CLD         ; ProDOS wants this in any user routine it calls
    ; Save A, X, Y
    PHA
    TXA
    PHA
    TYA
    PHA
    ; Restore A (which we saved a couple spaces back on stack)
    TSX
    INX ; Y
    INX ; X
    INX ; A
    LDA $100, X
    ; What state are we in?
    LDX vState
    BNE StateChk    ; TODO

    ; Zero. Default, pass-it-through state.
    ; ...Is the character a special control character?
    CMP TakiSelectChar
    BNE CookedOutput
    ; It IS our special control. Enter effect name-parsing
    LDX #State::EffectSelect
    STX vState
    BNE PrintExit   ; ALWAYS
StateChk:
    CPX #State::EffectSelect
    BEQ EffectSelect
    CPX #State::EffectText
    BEQ EffectText
    ; ERROR! We are in a state that doesn't exist!
    BRK
CookedOutput:
    JSR RunOurCSW
PrintExit:
    PLA
    TAY
    PLA
    TAX
    PLA
    RTS

EffectSelect:
    ; Look up the effect profile for the current character,
    ; And an instantiate that effect
    LDX #$00
    CLV
@FindEffect:
      LDY EffectProfilesTable, X
      BEQ @NullEffectSelected   ; We didn't find the effect!
      CMP EffectProfilesTable, X
      BEQ @Instantiate
      ; Advance to next entry
      INX
      INX
    BVC @FindEffect
@NullEffectSelected:
    LDX #$00
@Instantiate:
    ; TODO: Instantiate the effect
    ; Set the current effect from EDX
    INX ; advance to the EDX
    LDY EffectProfilesTable, X
    STY vCurrentEDX
    LDA EffectsTable, Y
    STA zpCurrentEffectL
    LDA EffectsTable+1, Y
    STA zpCurrentEffectH
    ; ...and set the state to "feeding text to the effect" mode
    LDY #State::EffectText
    STY vState
    JMP PrintExit

EffectText:
    ; Did we reach the end of the effect's text?
    CMP TakiSelectChar
    BEQ @EndText
    ; ...no. Still feeding text to the effect
    LDY #EffectJump::Text
    JSR RunCurrentEffect
    JMP PrintExit
@EndText:
    ; exit text-feeding
    LDA #State::Default
    STA vState
    LDY #EffectJump::TextEnd
    JSR RunCurrentEffect
    JMP PrintExit

RunCurrentEffect:
    TAX
    LDA (zpCurrentEffectL), Y
    PHA
    DEY
    LDA (zpCurrentEffectL), Y
    PHA
    TXA
    RTS     ; actually a JUMP, since we just pushed an address.

; Include effects definitions:
;.include "e_flash.inc"
;.include "e_inverse.inc"

EF_Flash:
    .word   EF_Flash_Init - 1
    .word   EF_Flash_Text - 1
    .word   EF_Flash_TextEnd - 1
    .word   EF_Flash_Tick - 1
    .word   $0000

EF_Flash_Init:
EF_Flash_Tick:
    RTS

EF_Flash_Text:
    ; Clear the "mask-out-flashing" flag from the monitor
    LDX #$7F
    STX MON_InvFlag
    ORA #$40    ; The "flash" bit
    AND #$DF    ; no lowercase
    JMP (vOurCSWL)
    ; RTS not needed

EF_Flash_TextEnd:
    LDX #$FF
    STX MON_InvFlag
    RTS


EF_Inverse:
    .word   EF_Flash_Init - 1
    .word   EF_Inverse_Text - 1
    .word   EF_Inverse_TextEnd - 1
    .word   EF_Flash_Tick - 1
    .word   $0000

EF_Inverse_Text:
    ; Clear the "mask-out-inverse" flag from the monitor
    LDX #$3F
    STX MON_InvFlag
    AND #$DF    ; no lowercase
    JMP (vOurCSWL)
    ; RTS not needed

EF_Inverse_TextEnd:
    ; Set the "mask-out-inverse" flag from the monitor
    LDX #$FF
    STX MON_InvFlag
    RTS
