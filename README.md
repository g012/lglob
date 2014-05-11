lglob
=====

Lua implementation of UNIX shell glob.
Ported blindly from Python.

##Dependencies

pl (PenLight), lfs (LuaFileSystem), lpeg (or LuLPeg), _ (Underscore.lua), globtopattern
pl and _ dependencies should be easy to remove if desired.

##Example

```lua
glob = require"lglob"
for v in iglob('../?ua/*.[ch]') do print(v) end
```
