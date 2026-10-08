# Lox.lox

A Lox interpreter written in Lox which passes the tests in the Lox test suite.

## Native functions

The following native functions are required to run Lox.lox:

* read(): number
    Returns 1 byte read from standard in.
    Returns `nil` if the end of the stream is reached.
* chr(number): string
    Takes a Unicode codepoint and returns the corresponding character.
    The Lox function `ascii` is a short-hand for chr(b) where b < 128.
    Lox supports UTF characters in strings but not other tokens.
* exit(number)
    Exits with the given exit code; used to exit with 65 (error) or 70 (runtime error).
* printerr(string)
    Prints the string to standard error.

These are implemented in a [patch for the original jlox interpreter](https://github.com/mrjameshamilton/loxlox/blob/main/Interpreter.diff), in the [jlox compiler](https://github.com/mrjameshamilton/jlox) and in my implementation of [clox](https://github.com/mrjameshamilton/clox).

## Sources

`Lox.lox` is generated (and not checked in): edit the files in `src/` and run
`./bundle.sh` to regenerate it; `build.sh` and `test.sh` do this automatically.
The files making up each bundle are listed, in order, in a `MANIFEST.*` file,
which can `include` another manifest (shared sources are in `MANIFEST.core`):

* `MANIFEST.interpreter` builds `build/loxi.lox`, which is copied to `Lox.lox`.
* `MANIFEST.astprinter` builds `build/loxast.lox`, a debug tool which prints a
  script's AST instead of running it.

Each bundle also gets a runner script in `build/bin/`, which runs the bundle
on a Lox script using the host interpreter chosen by `LOX_HOST`: `clox` (the
default), `jlox` (the patched jlox interpreter), `jloxc` (the jlox compiler) or
`jar` (the jar compiled from the bundle by `build.sh`).

```shell
$ build/bin/loxi hello.lox
$ LOX_HOST=jlox build/bin/loxast hello.lox
```

Each bundle also gets a `.map` file, which the runners use to rewrite clox
stack traces from a crash inside the bundle to the source file and line. A
line number can also be traced back to its source by hand:

```shell
$ ./bundle.sh where build/loxi.map 1234
src/frontend/Parser.lox:297
```

## Building

Lox.lox has been tested with the original jlox interpreter, the jlox compiler and clox which are provided as a git submodules, which should be checked out:

```shell
$ git submodule update --init --recursive
```

You'll need Java 20, Dart 2.19 and GCC to build. A build script is provided to bundle the sources, patch and build the original jlox interpreter, build clox, and compile each bundle to a jar with the jlox compiler:

```shell
$ ./build.sh
```

A Lox script can be run with Lox.lox using the `build/bin/loxi` runner, here
with the jar compiled from it:

```shell
$ echo "print \"Hello World\";" > hello.lox
$ LOX_HOST=jar build/bin/loxi hello.lox
Hello World
```

The Lox tests can be run by running the `test.sh` script, which runs them
against Lox.lox on every host that has been built, or only the given hosts.

```shell
$ ./test.sh
$ ./test.sh clox jar
```

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
    <td>24 seconds</td>
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
