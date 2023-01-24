#/bin/sh


cd jlox/craftinginterpreters
make get
cd ..
./gradlew copyJar
bin/jlox ../Lox.lox ../lib/lox.jar
cd craftinginterpreters
dart tool/bin/test.dart jlox -i ../../bin/loxlox

