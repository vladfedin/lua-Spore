--
-- lua-Spore : <http://fperrad.github.com/lua-Spore/>
--

local collectgarbage = collectgarbage
local setmetatable = setmetatable


module 'Spore.Middleware.Cache'

local cache = setmetatable({}, {__mode = 'v'})

function reset ()
    collectgarbage 'collect'
end

function call (self, req)
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

--
-- Copyright (c) 2010 Francois Perrad
--
-- This library is licensed under the terms of the MIT/X11 license,
-- like Lua itself.
--
