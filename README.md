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

These are implemented in a [patch for the original jlox interpreter](https://github.com/mrjameshamilton/loxlox/blob/main/Interpreter.diff) and in the [jlox compiler](https://github.com/mrjameshamilton/jlox).

## Building

Lox.lox has been tested with the original jlox interpreter and the jlox compiler which is provided as a git submodule, which should be checked out:

```shell
$ git submodule update --init --recursive
```

A build script is provided to patch and build the original jlox interpreter and compile the Lox.lox to a jar with the jlox compiler:

```shell
$ ./build.sh
```

A Lox script can be run with the `bin/loxlox` script which will
pipe the contents of the specified file to the compiled Lox.lox.

```shell
$ echo "print \"Hello World\";" > hello.lox
$ bin/loxlox hello.lox
Hello World
```

The Lox tests can be run by running the `test.sh` script.

```shell
$ ./test.sh
```

It's not possible to run Lox.lox with clox without modifications beyond adding the native functions due to constraints on the number of constants ("Too many constants in one chunk").

## Performance

As a quick performance test, running the below fibonacci example, gives the following run times (on my laptop, approximate average over several runs):

<table>
  <tr>
    <td></td>
    <td>jlox interpreter</td>
    <td>jlox compiler</td>
    <td>clox</td>
  </tr>
  <tr>
    <td>Directly</td>
    <td>1 second</td>
    <td>0.10 seconds</td>
    <td>0.19 seconds</td>
  </tr>
  <tr>
    <td>Lox.lox</td>
    <td>280 seconds</td>
    <td>18 seconds</td>
    <td>N/A</td>
  </tr>
</table>

```name=fib.lox
fun fib(n) {
  if (n < 2) return n;
  return fib(n - 2) + fib(n - 1);
}

var start = clock();
print fib(30);
var end = clock();
print end - start;
```
