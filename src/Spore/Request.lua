--
-- lua-Spore : <http://fperrad.github.com/lua-Spore/>
--

local pairs = pairs
local setmetatable = setmetatable
local table = require 'table'
local url = require 'socket.url'


module 'Spore.Request'

function new (env)
    local obj = {
        env = env,
        headers = {
            ['user-agent'] = env.HTTP_USER_AGENT,
        },
    }
    return setmetatable(obj, {
        __index = _M,
    })
end

function finalize (self)
    local env = self.env
    local path_info = env.PATH_INFO
    local query = {}
    for k, v in pairs(env.spore.params) do
        k = url.escape(k)
        v = url.escape(v)
        local n
        path_info, n = path_info:gsub(':' .. k, v)
        if n == 0 then
            query[#query+1] = k .. '=' .. v
        end
    end
    if #query > 0 then
        query = table.concat(query, '&')
    else
        query = nil
    end
    env.PATH_INFO = path_info
    env.QUERY_STRING = query
    self.url = url.build {
        scheme  = env.spore.url_scheme,
        host    = env.HTTP_HOST or env.SERVER_NAME,
        port    = env.SERVER_PORT,
        path    = (env.SCRIPT_NAME or '/') .. path_info,
        query   = query,
    }
    self.method = env.REQUEST_METHOD
end

--
-- Copyright (c) 2010 Francois Perrad
--
-- This library is licensed under the terms of the MIT/X11 license,
-- like Lua itself.
--
