#!/bin/sh

#set -o pipefail
set -e -u -C

MAINFILE=taki.s
CA65=ca65
LD65=ld65

main() {
    SOURCES="${MAINFILE} $(get_sources "${MAINFILE}" | \
        grep -v '^taki-os' | \
        grep -v -E '^(taki-basic|taki-startup|load-and-run-basic)\.s$')"
    AUXSOURCES=taki-os-*.s
    EBWS_SOURCES='taki-basic.s taki-startup.s load-and-run-basic.s'

    if test "${1-}" = watch; then
        shift
        do_watch "$@"
        exit 0
    fi
    OBJECTS=$(get_objects $SOURCES)
    EBWS_OBJS=$(get_objects $EBWS_SOURCES)

    compile $SOURCES $AUXSOURCES $EBWS_SOURCES
    mkdir -p bin
    link bin/taki.s.rom     taki.cfg $EBWS_OBJS $OBJECTS taki-os-none.o
    link TAKI-CASSETTE taki-real.cfg $OBJECTS taki-os-none.o
    link TAKI-PRODOS   taki-real.cfg $OBJECTS taki-os-prodos.o
    link TAKI-DOS      taki-real.cfg $OBJECTS taki-os-dos33.o
}

do_watch() {
    while true; do
        if $0 "$@"; then
            echo "Success ($?)"
        else
            echo "Failure ($?)"
        fi
        inotifywait -e modify -e close_write -q $SOURCES $AUXSOURCES $EBWS_SOURCES || true
    done
}

get_sources() {
    file=$1; shift
    sed -n -e 's/^;#link *"\(.*\)" *$/\1/p' < "$file"
}

get_objects() {
    for arg; do
        echo "${arg%.s}.o"
    done
}

compile() {
    for arg; do
        cmd="$CA65 -o $(get_objects $arg) $arg"
        printf ': %s\n' "$cmd"
        $cmd
    done
}

get_config() {
    file=$1; shift
    sed -n -e 's/;#define *CFGFILE *\([^ ]*\) *$/\1/p' < "$file"
}

link() {
    target=$1; shift
    config=$1; shift
    cmd="ld65 -o $target -C $config $*"
    printf ': %s\n' "$cmd"
    $cmd
}

####################

main "$@"

echo; echo "Done."
exit 0
