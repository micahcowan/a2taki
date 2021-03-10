#include <stdio.h>

int
main(int argc, char *argv[])
{
    printf("Here is some standard output\n");
    fprintf(stderr, "...and here is some stderr.\n");
    ++argv;
    if (*argv) {
        printf("\n\nUser argument: %s\n", *argv);
    }
    ++argv;
    if (*argv) {
        if (**argv > '0' && **argv <= '9') {
            return **argv - '0';
        }
    }
    return 0;
}
