#include <stdio.h>
#include "testlib.h"

int
main(void) {
    int s = 0;

    putsTaki(
        "Hello. There is some " RS "Fflashing" RS " and "
        RS "Iinverse" RS " text here."
    );
    dumpLine(0);
    dumpLine(1);
    homePosition();
    s |= verify40("Hello. There is some ");
    s |= verify40flash("flashing");
    s |= verify40(" and ");
    s |= verify40inv("inverse");
    s |= verify40(" text here.");

    return s;
}
