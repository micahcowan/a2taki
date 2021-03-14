#include <stdio.h>
#include <stdlib.h>

#include "testlib.h"

#define COUT    "FDED"

void
puts40(const char *s) {
    while (*s != '\0') {
        putc40(*s++);
    }
}

void
putsTaki(const char *s) {
}

void __fastcall__
putc40(const char c) {
    /* c should already be in A, because of fastcall. */
    /* Set its high bet, so it confirms with Apple 2 chars in-memory. */
    __asm__ ("ORA #$80");
    __asm__ ("jsr _putc40raw");
}

void __fastcall__
putc40raw(const char c) {
    /* c should already be in A, because of fastcall. */
    __asm__ ("jsr $" COUT);
}

int
verify40(const char *s) {
    return 0;
}

void brkHandler(void) {
    puts("BRK encountered. Exiting.");
    exit(42);
}

void dumpLineOne(void) {
    const unsigned char *start = (const unsigned char *)0x400;
    const unsigned char *end   = start + 40;
    const unsigned char *p;

    puts("Line one of text:");
    for (p = start; p != end; ++p) {
        printf(" %02X", *p);
        if ((p - start) % 8 == 7)
            putchar('\n');
    }
}

void testMessage(void) {
    puts ("testMessage");
}
