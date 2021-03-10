#include <stdio.h>

#define FMT "%02X"
#define PP  (printf(FMT, (unsigned int)*p++))
#define ZP  ((unsigned char *)(0x0000))

int main(void)
{
    unsigned char *p = ZP;
    while (p - ZP != 255) {
        unsigned char col = (p - ZP) % 8;
        if (col != 0) {
            putchar(' ');
        }
        else if (p != ZP) {
            putchar('\n');
        }
        PP;

    }
    putchar(' ');
    PP;
    putchar('\n');

    return 0;
}
