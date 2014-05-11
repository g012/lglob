--[[
  Filename globbing utility - ported from python.
  Dependencies: pl (PenLight), lfs (LuaFileSystem), lpeg (or LuLPeg), _ (Underscore.lua), globtopattern
  pl and _ dependencies should be easy to remove if desired.
]]

local lrequire = function(l)
    for k,v in pairs(l) do
        local ok,modorerr = pcall(require, v)
        if ok then return modorerr end
    end
    require(l[1]) -- trigger error
end

local re = lrequire{"re", "lulpeg.re"}
local pl = { dir=require"pl.dir", path=require"pl.path" }
local lfs = require"lfs"
local _ = require"underscore"
local globtopattern = require"globtopattern".globtopattern

local M = {}

--- Alternate filter version from pl.dir's.
-- It seems pl.dir.fnmatch/filter do not handle [], as they escape
-- them (wrongly I suppose).
local function filter(files, pattern)
    local i,t,mask = 1,{},globtopattern(pattern)
    for x,f in ipairs(files) do if f:find(mask) then t[i]=f i=i+1 end end
    return t
end

local magicregexp = re.compile('{[*?[]}')

local function hasmagic(s) return re.find(s, magicregexp) end
local function ishidden(path) return path:sub(1,1) == '.' end
local function splitdrive(path) if path:sub(2,1) == ':' then return path:sub(1,2), path:sub(3) end return '', path end
--- Escape the path to prevent processing of metacharacters.
-- Escaping is done by wrapping any of "*?[" between square brackets.
-- Metacharacters do not work in the drive part and shouldn't be escaped.
function M.escape(pathname)
    local drive
    drive, pathname = splitdrive(pathname)
    pathname = re.gsub(pathname, magicregexp, '[%1]')
    return drive .. pathname
end

local function iteratortotable(...)
    local i,t = 1,{}
    for v in ... do t[i]=v i=i+1 end
    return t
end
local function listit(t)
      local i,n = 0,#t
      return function() i=i+1 if i<=n then return t[i] end end
end

--[[
  These 2 helper functions non-recursively glob inside a literal directory.
  They return a list of basenames. `glob1` accepts a pattern while `glob0`
  takes a literal basename (so it only has to check for its existence).
]]
local function glob1(dirname, pattern)
    if not dirname then dirname = lfs.currentdir() end
    local names = iteratortotable(lfs.dir(dirname))
    if not ishidden(pattern) then names = _.reject(names, ishidden) end
    return filter(names, pattern)
end
local function glob0(dirname, basename)
    if not basename then
        -- pl.path.splitpath returns an empty basename for paths ending with a
        -- directory separator. 'q*x/' should match only directories.
        if pl.path.isdir(dirname) then return { basename } end
    else
        if pl.path.exists(pl.path.join(dirname, basename)) then return { basename } end
    end
    return {}
end

--- Return a list of paths matching a pathname pattern.
-- The pattern may contain simple shell-style wildcards a la
-- fnmatch. However, unlike fnmatch, filenames starting with a
-- dot are special cases that are not matched by '*' and '?'
-- patterns.
function M.glob(pathname)
    return iteratortotable(M.iglob(pathname))
end

--- Return an iterator which yields the paths matching a pathname pattern.
-- The pattern may contain simple shell-style wildcards a la
-- fnmatch. However, unlike fnmatch, filenames starting with a
-- dot are special cases that are not matched by '*' and '?'
-- patterns.
function M.iglob(pathname)
    local f
    f = function(p) return coroutine.wrap(function()
        if not hasmagic(p) then
            if pl.path.exists(p) then coroutine.yield(p) end
            return
        end
        local dirname, basename = pl.path.splitpath(p)
        if #dirname == 0 then
            for k,v in ipairs(glob1(nil, basename)) do coroutine.yield(v) end
            return
        end
        -- pl.path.splitpath returns the argument itself as a dirname if it is a
        -- drive or UNC path. Prevent an infinite recursion if a drive or UNC path
        -- contains magic characters (i.e. [[\\?\C:]]).
        local dirs
        if dirname ~= p and hasmagic(dirname) then dirs = function() return f(dirname) end
        else dirs = function() return listit{dirname} end end
        local globindir = hasmagic(basename) and glob1 or glob0
        for dirname in dirs() do
            for k,name in ipairs(globindir(dirname, basename)) do
                coroutine.yield(pl.path.join(dirname, name))
            end
        end
    end) end
    return f(pl.path.normcase(pl.path.normpath(pathname)))
end

return M
