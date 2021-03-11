#include <stdio.h>
#include "testlib.h"

int main(void)
{
    int status = 0;

    testlibInit();

    puts40("Hello!\n");
    putsTaki("Hello!\n");
    homePosition();
    status = verify40("Hello!\nHello!\n");

    return status;
}
