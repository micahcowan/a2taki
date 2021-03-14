#include <stdio.h>
#include <stdlib.h>

#include "testlib.h"

#define ASM_COUT    "FDED"
#define ASM_VTAB    "FC22"

#define SCRCODE(c) ((c) | 0x80)

#define DCPTR(p)  (*(unsigned char *)(p))
#define DPPTR(p)  (*(unsigned char * *)(p))
#define CH      DCPTR(0x24)
#define CV      DCPTR(0x25)
#define PTR_BAS	        DPPTR(0x28)

void
puts40(const char *s) {
    while (*s != '\0') {
        putc40(*s++);
    }
}

void
putsTaki(const char *s) {
    while (*s != '\0') {
        putcTaki(*s++);
    }
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
    __asm__ ("jsr $" ASM_COUT);
}

void __fastcall__
putcTaki(const char c) {
    /* c should already be in A, because of fastcall. */
    /* Set its high bet, so it confirms with Apple 2 chars in-memory. */
    __asm__ ("ORA #$80");
    __asm__ ("jsr _putcTakiRaw");
}

int
verify40mode(const char *s, unsigned char oradj, unsigned char mask) {
    int status = 0;
    const unsigned char *o = cursor(1);
    const unsigned char *p = (const unsigned char *)s;

    fputs("Verifying text: \"", stdout);
    printEscapedStr(s);
    puts("\"");

    while (*p != '\0') {
        const unsigned char c = ((*p | oradj) & mask);
        if (*p == '\r') {
            /* TODO: confirm only spaces to end of line. */
            CH = 0;
            CV += 1;
            o = cursor(1);
        }
        else if (*o != c) {
            status = 1;
            printf("MISMATCH: pos %u, '%c'. ",
                   (unsigned int)(p - s), (int)*p);
            printf("Expected %02X, got %02X.\n",
                   (unsigned)c, (unsigned)*o);
        }

        if (*p == '\r') {
            /* We already set o, CH above */
        }
        else if (CH < 40-1) {
            ++o;
            ++CH;
        }
        else {
            CH = 0;
            CV += 1;
            o = cursor(1);
        }
        ++p;
        /* TODO: check for when we exceed the line?
           ...or just require caller to use \r appropriately? */
    }

    return status;
}

void printEscapedStr(const char *s) {
    while (*s != '\0') {
        switch (*s) {
            case '\r':
                fputs("\\r", stdout);
                break;
            default:
                putchar(*s);
        }
        ++s;
    }
}

unsigned char *cursor(int noisy) {
    unsigned char *p;
    __asm__ ("jsr $" ASM_VTAB);
    p = PTR_BAS + CH;

    if (noisy) {
        printf("BASL is %02X; cursor at %02X.\n",
               (unsigned)PTR_BAS, (unsigned)p);
    }
    return p;
}

void brkHandler(void) {
    puts("BRK encountered. Exiting.");
    exit(42);
}

void dumpLine(unsigned int line) {
    const unsigned char *start;
    const unsigned char *end;
    const unsigned char *p;
    unsigned char ch, cv;
    unsigned short basl;

    /* "Go to" line we want to print, save existing location */
    ch = CH, cv = CV;
    basl = (unsigned short)PTR_BAS;
    CH = 0, CV = line;
    start = cursor(0);

    /* Print it. */
    printf("Line %02u, BASL %02X:\n", line, (unsigned int)start);
    end = start + 40;
    for (p = start; p != end; ++p) {
        printf(" %02X", *p);
        if ((p - start) % 16 == 15)
            putchar('\n');
    }
    putchar('\n');

    CH = ch, CV = cv;
    PTR_BAS = (unsigned char *)basl;
    // printf("Saved BASL was %02X\n", basl);
}

void homePosition(void) {
    CH = 0;
    CV = 0;
    __asm__ ("jsr $" ASM_VTAB);
}

void testMessage(void) {
    puts ("testMessage");
}
