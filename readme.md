# SimpleDoc Compiler

HTML compiler for the SimpleDoc markup language, initialization example below.

```nim
import src/sdcompiler

var compiler = Compiler()

let path: string = "<YourPath>"

var html = sdcompiler(path)

stdout.write(html)
```
