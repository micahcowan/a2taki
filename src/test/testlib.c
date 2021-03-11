#include "testlib.h"

#define COUT    "FDED"

void
testlibInit(void) {
}

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
    __asm__ ("jsr $" COUT);
}

void
homePosition(void) {
}

int
verify40(const char *s) {
    return 0;
}
