#/bin/sh

# The craftinginterpreters test runner is pre-null-safety Dart, which Dart 3+ cannot run.
DART="${DART:-$HOME/.local/share/dart-2.19.6/dart-sdk/bin/dart}"
[ -x "$DART" ] || DART=dart
"$DART" --version 2>&1 | grep -q 'version: 2\.' || { echo "Dart 2.x required (set DART to override)" >&2; exit 1; }

(
echo "Testing Lox.lox with clox compiler"
cd jlox || exit
cd craftinginterpreters || exit
"$DART" tool/bin/test.dart jlox -i ../../bin/cloxloxlox
)
