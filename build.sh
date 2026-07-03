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

(cd jlox/craftinginterpreters || exit
make get
pushd java/com/craftinginterpreters/lox || exit
git apply ../../../../../../Interpreter.diff
popd || exit
make
)

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
cd jlox || exit
JAVA_HOME="$gradle_java_home" ./gradlew copyJar
JAVA_HOME="$gradle_java_home" bin/jlox ../Lox.lox ../lib/lox.jar
)

(
cd clox || exit
gcc src/*.c -o clox -O3
)
