#!/bin/sh

#set -o pipefail
set -e -u -C

MAINFILE=taki.s
BINROM=bin/${MAINFILE}.rom
CA65=ca65
LD65=ld65

main() {
    SOURCES="${MAINFILE} $(get_sources "${MAINFILE}")"
    OBJECTS=$(get_objects $SOURCES)

    compile $SOURCES
    link "$BINROM" $(get_config "$MAINFILE") $OBJECTS
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
