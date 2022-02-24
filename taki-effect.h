#ifndef TAKI_EFFECT_H_
#define TAKI_EFFECT_H_

#define TAKI_DSP_INIT		0
#define TAKI_DSP_COLLECT	1
#define TAKI_DSP_ENDCOLLECT	2
#define TAKI_DSP_DESTROY	3
#define TAKI_DSP_TICK		4
#define TAKI_DSP_UNTICK		5  /* "idle" tick, for delay-smoothing */
#define TAKI_DSP_DRAW		6  /* draw, whether ticked or not
				      (someone somewhere ticked) */
#define TAKI_DSP_USER_INPUT	7

#define TakiDebugPrint(str)	\
  do { \
    const char *s = str; \
    __asm__("bit TakiVarDebugActive"); \
    __asm__("bpl %g", skip); \
    __asm__("lda %v", s); \
    __asm__("ldy %v+1", s); \
    __asm__("jsr _TakiDbgPrint"); \
  skip: \
    ; \
  } while(0)

/* Allocation helpers */
#define TE_ALLOC_PTR		(*((uint8_t **)0x66))
#define TE_ALLOC_END_PTR	(*((uint8_t **)0x68))
#define TE_ALLOC_START(type) \
	(*(type *)(TE_ALLOC_PTR))
#define TE_ALLOC_NEXT(type, prev) \
	(*(type *)(unsigned char *)(&(prev) + 1))
#define TE_RESERVE_UNTIL(fakeItem) \
	(TE_ALLOC_END_PTR = &(fakeItem))

#endif /* TAKI_EFFECT_H_ */
