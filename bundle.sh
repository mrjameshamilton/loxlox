#!/bin/bash
#
# Concatenates the Lox sources listed in a MANIFEST.* file into a single
# script, plus a .map file for translating bundle line numbers back to sources.
#
#   ./bundle.sh                         bundle every known MANIFEST.*, then
#                                       copy build/loxi.lox to Lox.lox
#   ./bundle.sh MANIFEST.x build/out    write build/out.lox and build/out.map
#   ./bundle.sh where build/out.map N   print the source file:line of bundle line N
#
# A manifest lists one path per line, relative to the repository root; blank
# lines and lines starting with '#' are ignored. A line "include MANIFEST.y"
# lists MANIFEST.y's sources at that point. The .map file has one line per
# source: "<first bundle line> <path>".

set -euo pipefail

cd "$(dirname "$0")"

fail() {
    echo "bundle: $*" >&2
    exit 1
}

# expand MANIFEST [INCLUDING...]: appends MANIFEST's sources to SOURCES,
# expanding includes; INCLUDING is the chain of manifests including it.
SOURCES=()
expand() {
    local manifest="$1"
    shift
    [ -f "$manifest" ] || fail "no such manifest: $manifest${1:+ (included by $1)}"
    local m
    for m in "$@"; do
        [ "$m" = "$manifest" ] || continue
        fail "include cycle: $manifest"
    done

    local entry
    while IFS= read -r entry || [ -n "$entry" ]; do
        case "$entry" in
            ''|'#'*) ;;
            'include '*) expand "${entry#include }" "$manifest" "$@" ;;
            *)
                [ -f "$entry" ] || fail "no such file: $entry (in $manifest)"
                SOURCES+=("$entry")
                ;;
        esac
    done < "$manifest"
}

# bundle MANIFEST OUT: writes OUT.lox and OUT.map.
bundle() {
    local manifest="$1" out="$2"
    SOURCES=()
    expand "$manifest"
    mkdir -p "$(dirname "$out")"

    local lox="$out.lox.tmp" map="$out.map.tmp"
    trap "rm -f '$lox' '$map'" EXIT
    : > "$lox"
    : > "$map"

    local line=1 path
    for path in "${SOURCES[@]}"; do
        [ -s "$path" ] && [ "$(tail -c1 "$path")" = "" ] || fail "missing final newline: $path"
        echo "$line $path" >> "$map"
        cat "$path" >> "$lox"
        line=$((line + $(wc -l < "$path")))
    done

    local dups
    dups=$(grep -oE '^(var|fun|class) [A-Za-z_][A-Za-z0-9_]*' "$lox" | awk '{print $2}' | sort | uniq -d)
    if [ -n "$dups" ]; then
        local name
        for name in $dups; do
            echo "bundle: duplicate top-level name: $name" >&2
            grep -nE "^(var|fun|class) $name\b" "$lox" | while IFS=: read -r n _; do
                echo "  $(where "$map" "$n")" >&2
            done
        done
        exit 1
    fi

    if [ "$(basename "$manifest")" = "MANIFEST.runtime" ]; then
        : # TODO: runtime-mode check (Step 23).
    fi

    mv "$lox" "$out.lox"
    mv "$map" "$out.map"
    echo "bundled $manifest -> $out.lox ($((line - 1)) lines)"
}

# where MAP LINE: maps a bundle line to "path:line" using the last map entry
# whose first line is <= LINE.
where() {
    awk -v n="$2" '$1 <= n { first = $1; path = $2 }
        END {
            if (path == "") exit 1
            print path ":" (n - first + 1)
        }' "$1" || fail "line $2 is not in $1"
}

# Manifests built when run without arguments, with their output names.
ALL="MANIFEST.interpreter:build/loxi MANIFEST.compiler:build/loxc MANIFEST.astprinter:build/loxast"

case "${1:-}" in
    "")
        for entry in $ALL; do
            manifest="${entry%%:*}"
            [ -f "$manifest" ] && bundle "$manifest" "${entry#*:}"
        done
        cp build/loxi.lox Lox.lox
        echo "copied build/loxi.lox -> Lox.lox"
        ;;
    where)
        [ $# -eq 3 ] || fail "usage: $0 where MAP LINE"
        where "$2" "$3"
        ;;
    *)
        [ $# -eq 2 ] || fail "usage: $0 [MANIFEST OUT | where MAP LINE]"
        bundle "$1" "$2"
        ;;
esac
