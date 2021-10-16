#include <stdio.h>

extern unsigned char RNDH = 0;
extern unsigned char RNDL = 0;

extern void rnd(void);

void
printIt(void)
{
    printf("%u\n", (unsigned int)((RNDH << 8) + RNDL) );
}

int
main(void)
{
    printIt();
    do {
        rnd();
        printIt();
    } while (RNDL != 0 || (RNDH != 0 && RNDH != 1));
    rnd();
    printIt();
    rnd();
    printIt();

    return 0;
}
