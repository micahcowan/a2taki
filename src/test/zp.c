#include <stdio.h>

#define STR_(x) #x
#define STR(x) STR_(x)

#define FMT "%02X"
#define PP  (printf(FMT, (unsigned int)*p++))
#define ZP  ((unsigned char *)(0x0000))
#define MIN_USE  0x80

int main(void)
{
    unsigned char *p = ZP;
    unsigned char *zpe = ZP + 0x100;
    unsigned char *q = zpe;

    puts("Zero page contents:\n");
    while (p - ZP != 255) {
        unsigned char col = (p - ZP) % 8;
        if (col != 0) {
            putchar(' ');
        }
        else if (p != ZP) {
            putchar('\n');
        }

        /* Look for the first value that's not 0xFF */
        if (q == zpe && *p != 255)  q = p;

        PP;
    }
    putchar(' ');
    PP;
    putchar('\n');
    putchar('\n');
    if (q == zpe) {
        puts("NO detected use of the zero page.\n"
             "Test may need adjusting.");
        return 25;
    }
    else if ((unsigned int)q >= MIN_USE) {
        printf("Success. First detected ZP use at 0x%02X, "
               "above the min (" STR(MIN_USE) ").\n", (unsigned int)q);
        return 0;
    }
    else {
        printf("FAILURE. First detected ZP use at 0x%02X, "
               "BELOW the min (" STR(MIN_USE) "). Fix test.cfg!\n", (unsigned int)q);
        return 1;
    }

    return 1;   /* can't get here */
}
