#/bin/sh

if type -p java; then
    echo found java executable in PATH
    _java=java
elif [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]];  then
    echo found java executable in JAVA_HOME
    _java="$JAVA_HOME/bin/java"
else
    echo "Java version 20 required"
    exit
fi

if [[ "$_java" ]]; then
    version=$("$_java" -version 2>&1 | awk -F '"' '/version/ {print $2}')
    echo version "$version"
    if [[ "$version" < "20" ]]; then
        echo "Java version 20 required"
        exit
    fi
fi

# The craftinginterpreters Makefile runs `dart` from PATH, and its tools are
# pre-null-safety Dart, which Dart 3+ cannot run.
DART="${DART:-$HOME/.local/share/dart-2.19.6/dart-sdk/bin/dart}"
[ -x "$DART" ] || DART=$(command -v dart)
"$DART" --version 2>&1 | grep -q 'version: 2\.' || { echo "Dart 2.x required (set DART to override)" >&2; exit 1; }
PATH="$(dirname "$DART"):$PATH"

# Regenerate Lox.lox from the sources in src/.
./bundle.sh || exit 1

(cd jlox/craftinginterpreters || exit
# --enforce-lockfile keeps Dart 2.19 from rewriting the old-format pubspec.lock.
(cd tool && dart pub get --enforce-lockfile) || exit 1
pushd java/com/craftinginterpreters/lox || exit 1
if git apply --reverse --check ../../../../../../Interpreter.diff 2>/dev/null; then
    echo "Interpreter.diff already applied"
else
    git apply ../../../../../../Interpreter.diff || exit 1
fi
popd || exit 1
make jlox || exit 1
) || exit 1

gradle_java_home="$JAVA_HOME"
if [[ -d "$HOME/.sdkman/candidates/java" ]]; then
    for candidate in "$HOME"/.sdkman/candidates/java/20* "$HOME"/.sdkman/candidates/java/19* "$HOME"/.sdkman/candidates/java/18* "$HOME"/.sdkman/candidates/java/17*; do
        if [[ -x "$candidate/bin/java" ]]; then
            gradle_java_home="$candidate"
            break
        fi
    done
fi
if [[ -z "$gradle_java_home" ]]; then
    echo "Warning: no Java <=20 found for building the jlox compiler with Gradle; using the active JDK, which may fail."
else
    echo "Using $gradle_java_home to build the jlox compiler (Gradle needs <=20)"
fi
(
cd jlox || exit 1
JAVA_HOME="$gradle_java_home" ./gradlew copyJar || exit 1
# Compile each bundle to a jar, run by its runner with LOX_HOST=jar.
for bundle in ../build/*.lox; do
    jar="${bundle%.lox}.jar"
    rm -f "$jar"
    JAVA_HOME="$gradle_java_home" bin/jlox "$bundle" "$jar" && [ -f "$jar" ] || {
        echo "Failed to compile $bundle with the jlox compiler" >&2
        exit 1
    }
done
) || exit 1

(
cd clox || exit 1
gcc src/*.c -o clox -O3
) || exit 1
