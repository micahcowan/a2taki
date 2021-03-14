#ifndef TAKI_TESTLIB_H
#define TAKI_TESTLIB_H

extern void puts40(const char *s);
extern void putsTaki(const char *s);
extern void __fastcall__ putc40(const char c);

extern void homePosition();     /* defined in testlib-asm.s */
extern int  verify40(const char *s);

extern void dumpLineOne();

#endif
