--
-- lua-Spore : <http://fperrad.github.com/lua-Spore/>
--

local type = type


module 'Spore.Middleware.Mock'

function call (self, req)
    req:finalize()
    for i = 1, #self, 2 do
        local cond, func, r = self[i], self[i+1]
        if type(cond) == 'string' then
            r = req.url:match(cond)
        else
            r = cond(req)
        end
        if r then
            return func(req)
        end
    end
end

--
-- Copyright (c) 2010 Francois Perrad
--
-- This library is licensed under the terms of the MIT/X11 license,
-- like Lua itself.
--
