#include <stdint.h>

#include "taki-effect.h"

#define Base		TE_ALLOC_START(uint16_t)
#define NumChars	TE_ALLOC_NEXT(uint8_t, Base)
#define HilitePos	TE_ALLOC_NEXT(uint8_t, NumChars)
#define End		TE_ALLOC_NEXT(uint8_t, HilitePos)

void TE_Scan2(void) {
  unsigned char mode;
  __asm__("sta %v", mode);
  
  switch (mode) {
    case TAKI_DSP_INIT:
      TakiDebugPrint("SCAN2 DISPATCH CALLED!\n");
      TE_RESERVE_UNTIL(End);
      Base = 0;
      NumChars = 0;
      HilitePos = 0;
      break;
    case TAKI_DSP_COLLECT:
      //++NumChars;
      /* TODO: sanity-check character values */
      break;
  }
}

/*
	; COLLECT
        ; TODO: sanity-check character value
	; increment numChars by 1
	lda #$0
        sec ; so, 1
        ldy #kLocNumChars
	adc (TAKI_ZP_EFF_STORAGE_L),y
	sta (TAKI_ZP_EFF_STORAGE_L),y
        lda TAKI_ZP_ACC
        jmp _TakiIoDoubledOut
*/