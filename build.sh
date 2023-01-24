#/bin/sh


cd jlox/craftinginterpreters
make get
cd ..
./gradlew copyJar
bin/jlox ../Lox.lox ../lib/lox.jar
cd ..
