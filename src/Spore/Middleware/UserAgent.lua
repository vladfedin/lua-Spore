--
-- lua-Spore : <http://fperrad.github.com/lua-Spore/>
--


_ENV = nil
local m = {}

function m:call (req)
    if self.useragent then
        req.headers['user-agent'] = self.useragent
    end
end

return m
--
-- Copyright (c) 2010 Francois Perrad
--
-- This library is licensed under the terms of the MIT/X11 license,
-- like Lua itself.
--
