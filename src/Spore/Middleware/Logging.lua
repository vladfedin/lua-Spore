--
-- lua-Spore : <http://fperrad.github.com/lua-Spore/>
--


module 'Spore.Middleware.Logging'

function call (self, req)
    req.env.sporex.logger = self.logger
end

--
-- Copyright (c) 2010 Francois Perrad
--
-- This library is licensed under the terms of the MIT/X11 license,
-- like Lua itself.
--
