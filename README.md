#lglob

Lua implementation of UNIX shell glob.

Ported blindly from Python.

##Dependencies

pl (PenLight), lfs (LuaFileSystem), lpeg (or LuLPeg), _ (Underscore.lua), globtopattern

pl: https://github.com/stevedonovan/Penlight  
lfs: https://github.com/keplerproject/luafilesystem  
lpeg: http://www.inf.puc-rio.br/~roberto/lpeg/  
underscore: https://github.com/mirven/underscore.lua  
globtopattern: https://github.com/davidm/lua-glob-pattern

pl and _ dependencies should be easy to remove if desired.

##Example

```lua
glob = require"lglob"
for v in glob.iglob('../?ua/*.[ch]') do print(v) end
```
