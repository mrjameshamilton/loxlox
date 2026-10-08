#!/bin/sh
#
# Runs the Lox test suite against Lox.lox (build/bin/loxi) on each host:
#
#   ./test.sh             every host that has been built (see ./build.sh)
#   ./test.sh clox jar    only the given hosts (clox, jlox, jloxc or jar)

cd "$(dirname "$0")" || exit 1

# The craftinginterpreters test runner is pre-null-safety Dart, which Dart 3+ cannot run.
DART="${DART:-$HOME/.local/share/dart-2.19.6/dart-sdk/bin/dart}"
[ -x "$DART" ] || DART=dart
"$DART" --version 2>&1 | grep -q 'version: 2\.' || { echo "Dart 2.x required (set DART to override)" >&2; exit 1; }

# Test the current sources, not a stale Lox.lox.
./bundle.sh || exit 1

hosts="$*"
if [ -z "$hosts" ]; then
    [ -x clox/clox ]                              && hosts="$hosts clox"
    [ -d jlox/craftinginterpreters/build/java ]   && hosts="$hosts jlox"
    [ -f jlox/lib/jlox.jar ]                      && hosts="$hosts jloxc"
    [ -f build/loxi.jar ]                         && hosts="$hosts jar"
    [ -n "$hosts" ] || { echo "No hosts built: run ./build.sh" >&2; exit 1; }
fi

# The jar is only rebuilt by ./build.sh, so would otherwise test old sources.
case " $hosts " in
    *" jar "*)
        if [ build/loxi.jar -ot build/loxi.lox ]; then
            echo "build/loxi.jar is older than the sources: run ./build.sh" >&2
            exit 1
        fi
        ;;
esac

failed=""
for host in $hosts; do
    echo "Testing Lox.lox with LOX_HOST=$host"
    (
        cd jlox/craftinginterpreters || exit 1
        LOX_HOST=$host "$DART" tool/bin/test.dart jlox -i ../../build/bin/loxi
    ) || failed="$failed $host"
done

if [ -n "$failed" ]; then
    echo "Failed hosts:$failed" >&2
    exit 1
fi
echo "All hosts passed:$hosts"
