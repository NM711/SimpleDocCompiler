# SimpleDoc Compiler

HTML compiler for the SimpleDoc markup language, initialization example below.

```nim
import src/sdcompiler

var compiler = Compiler()

let path: string = "./test.sd"

var html = compiler.compile(CompilationMode.FILE, path)

stdout.write(html)
```
