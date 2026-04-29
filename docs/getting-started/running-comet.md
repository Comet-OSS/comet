---
icon: lucide/play
---

# Running Comet

To run comet, you can use our official loader.

!!! important
    Your execution environment needs to have `#!luau loadstring()` supported.
    </br>
    Otherwise, you can download the raw source.

```luau
local comet = loadstring(game:HttpGetAsync("https://github.com/Comet-OSS/comet/releases/latest/download/comet.luau"))()

comet.Load()
```
