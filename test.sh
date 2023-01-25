#/bin/sh

(
echo "Testing Lox.lox with original jlox interpreter"
cd jlox || exit
cd craftinginterpreters || exit
dart tool/bin/test.dart jlox
)
(
echo "Testing Lox.lox with jlox compiler"
cd jlox || exit
cd craftinginterpreters || exit
dart tool/bin/test.dart jlox -i ../../bin/loxlox-nojar
)
(
echo "Testing Lox.lox with jlox compiler compiled jar"
cd jlox || exit
bin/jlox ../Lox.lox ../lib/lox.jar
cd craftinginterpreters || exit
dart tool/bin/test.dart jlox -i ../../bin/loxlox
)
