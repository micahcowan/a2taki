#include <stdio.h>
#include "testlib.h"

int main(void)
{
    int status = 0;

    //testlibInit();

    puts40("Hello!\r");
    dumpLineOne();
    putsTaki("Hello!\r");
    homePosition();
    status = verify40("Hello!\nHello!\n");

    return status;
}
