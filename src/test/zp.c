#include <stdio.h>
#include <stdlib.h>

#define STR_(x) #x
#define STR(x) STR_(x)

#define FMT "%02X"
#define PP  (printf(FMT, (unsigned int)*p++))
#define ZP  ((unsigned char *)(0x0000))
#define MIN_USE  0x80

/* Handy routine for filling the stack up with values */
#if 0
void callABunch(int depth, int var1, int var2, int var3, int var4, int var5, int var6, int var7, int var8, int var9, int var10, int var11, int var12, int var13, int var14, int var15, int var16) {
    if (depth != 0)
        callABunch(depth-1, var1, var2, var3, var4, var5, var6, var7, var8, var9, var10, var11, var12, var13, var14, var15, var16);
    return;
}
#endif

int main(int argc, char *argv[])
{
    unsigned char *zp;
    unsigned char *p;
    unsigned char *zpe;
    unsigned char *q;

    //callABunch(30, 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16);
    if (argc < 2) {
        puts("Zero page contents:\n");
        p = zp = ZP;
    }
    else {
        zp = (unsigned char *)(strtoul(argv[1], NULL, 16) << 8);
        p = zp;
        printf("Displaying page starting $%04X:\n\n", (unsigned int)(zp - ZP));
    }
    q = zpe = zp + 0x0100;

    while (p - zp != 255) {
        unsigned char col = (p - zp) % 8;
        if (col != 0) {
            putchar(' ');
        }
        else if (p != zp) {
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

    if (zp != ZP)
        return 0;   /* Not actually checking zero page. */

    if (q == zpe) {
        puts("NO detected use of the zero page.\n"
             "Test may need adjusting.");
        return 25;
    }
    else if ((unsigned int)q >= MIN_USE) {
        printf("Success. First detected zp use at 0x%02X, "
               "above the min (" STR(MIN_USE) ").\n", (unsigned int)q);
        return 0;
    }
    else {
        printf("FAILURE. First detected zp use at 0x%02X, "
               "BELOW the min (" STR(MIN_USE) "). Fix test.cfg!\n", (unsigned int)q);
        return 1;
    }

    return 1;   /* can't get here */
}
