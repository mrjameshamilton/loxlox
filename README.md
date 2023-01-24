# Lox.lox

A Lox interpreter written in Lox which passes the tests in the Lox test suite.

## Native functions

The following native functions are required to run Lox.lox:

* read(): number
    Returns 1 byte read from standard in.
    Returns `nil` if the end of the stream is reached.
* utf(number, number, number, number): string
    Takes 1, 2, 3, or 4 bytes and returns a corresponding UTF character.
    The Lox function `ascii` is a short-hand for utf(b1, nil, nil, nil).
    Lox supports UTF characters in strings but not other tokens.
* exit(number)
    Exits with the given exit code; used to exit with 65 (error) or 70 (runtime error).
* printerr(string)
    Prints the string to standard error.

These are implemented in the [jlox compiler](https://github.com/mrjameshamilton/jlox).

## Building

Lox.lox has been tested with jlox which is provided as a git submodule, which should be checked out:

```shell
$ git submodule update --init --recursive
```

Lox.lox can then be compiled to a jar with jlox:

```shell
$ ./build.sh
```

A Lox script can be run with the `bin/loxlox` script which will
pipe the contents of the specified file to Lox.lox.

```shell
$ echo "print \"Hello World\";" > hello.lox
$ bin/loxlox hello.lox
Hello World
```

The Lox tests can be run by running the `test.sh` script.

```shell
$ ./test.sh
```

