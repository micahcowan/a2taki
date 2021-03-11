#ifndef TAKI_TESTLIB_H
#define TAKI_TESTLIB_H

extern void testlibInit(void);

extern void puts40(const char *s);
extern void putsTaki(const char *s);
extern void __fastcall__ putc40(const char c);

extern void homePosition();
extern int  verify40(const char *s);

#endif
