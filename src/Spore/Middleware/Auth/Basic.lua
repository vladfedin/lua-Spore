--
-- lua-Spore : <http://fperrad.github.com/lua-Spore/>
--

local mime = require 'mime'


module 'Spore.Middleware.Auth.Basic'

function call (self, req)
    if req.env.spore.authentication and self.username and self.password then
        req.headers['authorization'] =
            'Basic ' .. mime.b64(self.username .. ':' .. self.password)
    end
end

--
-- Copyright (c) 2010 Francois Perrad
--
-- This library is licensed under the terms of the MIT/X11 license,
-- like Lua itself.
--
