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
(
cd jlox || eixt
./gradlew copyJar
bin/jlox ../Lox.lox ../lib/lox.jar
)

(
cd clox || exit
gcc src/*.c -o clox
)
