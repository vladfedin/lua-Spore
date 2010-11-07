--
-- lua-Spore : <http://fperrad.github.com/lua-Spore/>
--

local collectgarbage = collectgarbage
local setmetatable = setmetatable


_ENV = nil
local m = {}

local cache = setmetatable({}, {__mode = 'v'})

function m.reset ()
    collectgarbage 'collect'
end

function m:call (req)
    req:finalize()
    local key = req.url
    local res = cache[key]
    if res then
        return res
    else
        return  function (res)
                    cache[key] = res
                    return res
                end
    end
end

return m
--
-- Copyright (c) 2010 Francois Perrad
--
-- This library is licensed under the terms of the MIT/X11 license,
-- like Lua itself.
--
