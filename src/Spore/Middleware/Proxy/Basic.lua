--
-- lua-Spore : <http://fperrad.github.com/lua-Spore/>
--

local mime = require 'mime'
local url = require 'socket.url'


module 'Spore.Middleware.Proxy.Basic'

function call (self, req)
    local env = req.env
    req.headers['host'] = env.SERVER_NAME

    local proxy = url.parse(self.proxy)
    env.SERVER_NAME = proxy.host
    env.SERVER_PORT = proxy.port

    if self.username and self.password then
        req.headers['proxy-authorization'] =
            'Basic ' .. mime.b64(self.username .. ':' .. self.password)
    end
end

--
-- Copyright (c) 2010 Francois Perrad
--
-- This library is licensed under the terms of the MIT/X11 license,
-- like Lua itself.
--
