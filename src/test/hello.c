#include <stdio.h>
#include "testlib.h"

int main(void)
{
    int status = 0;

    //testlibInit();

    puts40("Hello!\r");
    putsTaki("Hello!\r");
    dumpLine(0);
    dumpLine(1);
    homePosition();
    status = verify40("Hello!\rHello!\r");

    return status;
}
