--
-- lua-Spore : <http://fperrad.github.com/lua-Spore/>
--

local pairs = pairs
local setmetatable = setmetatable
local tostring = tostring
local tconcat = require 'table'.concat
local url = require 'socket.url'


module 'Spore.Request'

redirect = false

function new (env)
    local obj = {
        env = env,
        redirect = redirect,
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
        v = url.escape(tostring(v))
        local n
        path_info, n = path_info:gsub(':' .. k, (v:gsub('%%', '%%%%')))
        if n == 0 then
            query[#query+1] = url.escape(k) .. '=' .. v
        end
    end
    local query_string
    if #query > 0 then
        query_string = tconcat(query, '&')
    end
    env.PATH_INFO = path_info
    env.QUERY_STRING = query_string or ''
    self.url = url.build {
        scheme  = env.spore.url_scheme,
        host    = env.HTTP_HOST or env.SERVER_NAME,
        port    = env.SERVER_PORT,
        path    = (env.SCRIPT_NAME or '/') .. path_info,
        query   = query_string,
    }
    self.method = env.REQUEST_METHOD
end

--
-- Copyright (c) 2010 Francois Perrad
--
-- This library is licensed under the terms of the MIT/X11 license,
-- like Lua itself.
--
