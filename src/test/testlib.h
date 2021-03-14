#ifndef TAKI_TESTLIB_H
#define TAKI_TESTLIB_H


/* Control-R - special Taki formatting character */
#define RS  "\x12"

extern void puts40(const char *s);
extern void putsTaki(const char *s);
extern void __fastcall__ putc40(const char c);
extern void __fastcall__ putc40raw(const char c);
extern void __fastcall__ putcTaki(const char c);
extern void printEscapedStr(const char *s);
extern unsigned char *cursor(int noisy);
extern void homePosition(void);

extern void __fastcall__ putcTakiRaw(const char c);
    /* ^ defined in testlib-asm.s */

extern int  verify40mode(const char *s, unsigned char orval, unsigned char mask);
#define verify40(s) (verify40mode((s), 0x80, 0xff))
#define verify40inv(s) (verify40mode((s), 0, 0x1f))
#define verify40flash(s) (verify40mode((s), 0x40, 0x5f))

extern void dumpLine(unsigned int);

#endif
