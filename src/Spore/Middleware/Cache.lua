--
-- lua-Spore : <http://fperrad.github.com/lua-Spore/>
--


module 'Spore.Middleware.Cache'

local cache = {}

function reset ()
    cache = {}
end

function call (self, req)
    req:finalize()
    local res = cache[req.url]
    if res then
        return res
    else
        return  function (res)
                    cache[req.url] = res
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
