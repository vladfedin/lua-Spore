--
-- lua-Spore : <http://fperrad.github.com/lua-Spore/>
--

local pairs = pairs
local setmetatable = setmetatable
local tostring = tostring
local string = string
local tconcat = require 'table'.concat
local tsort = require 'table'.sort
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

function escape5849(s)
    -- see RFC 5849, Section 3.6
    return string.gsub(s, '[^-._~%w]', function(c)
        return string.upper(string.format('%%%02x', string.byte(c)))
    end)
end

function finalize (self, oauth)
    local env = self.env
    local path_info = env.PATH_INFO
    local form_data = env.spore.form_data
    local headers = env.spore.headers
    local query, query_keys, query_vals = {}, {}, {}
    local form = {}
    for k, v in pairs(env.spore.params) do
        k = tostring(k)
        v = tostring(v)
        local e = url.escape(v)
        local n
        path_info, n = path_info:gsub(':' .. k, (e:gsub('%%', '%%%%')))
        if form_data then
            for kk, vv in pairs(form_data or {}) do
                kk = tostring(kk)
                vv = tostring(vv)
                local nn
                vv, nn = vv:gsub(':' .. k, v)
                if nn > 0 then
                    form[kk] = vv
                    n = n + 1
                end
            end
        end
        if headers then
            for kk, vv in pairs(headers or {}) do
                kk = tostring(kk)
                vv = tostring(vv)
                local nn
                vv, nn = vv:gsub(':' .. k, v)
                if nn > 0 then
                    headers[kk] = vv
                    self.headers[kk] = vv
                    n = n + 1
                end
            end
        end
        if n == 0 then
            if oauth then
                query_keys[#query_keys+1] = escape5849(k)
                query_vals[k] = escape5849(v)
            else
                query[#query+1] = url.escape(k) .. '=' .. e
            end
        end
    end
    if oauth then
        tsort(query_keys)
        for i = 1, #query_keys do
            local k = query_keys[i]
            local v = query_vals[k]
            query[#query+1] = k .. '=' .. v
        end
    end
    local query_string
    if #query > 0 then
        query_string = tconcat(query, '&')
    end
    env.PATH_INFO = path_info
    env.QUERY_STRING = query_string or ''
    if form_data then
        self.env.spore.form_data = form
    end
    self.method = env.REQUEST_METHOD
    if oauth then
        local base_url = url.build {
            scheme  = env.spore.url_scheme,
            host    = env.HTTP_HOST or env.SERVER_NAME,
            port    = env.SERVER_PORT,
            path    = (env.SCRIPT_NAME or '/') .. path_info,
            -- no query
        }
        for k, v in pairs(env.spore.params) do
            k = tostring(k)
            if k:match'^oauth_' and not query_vals[k] then
                query_keys[#query_keys+1] = k
                query_vals[k] = escape5849(tostring(v))
            end
        end
        tsort(query_keys)
        params = {}
        for i = 1, #query_keys do
            local k = query_keys[i]
            local v = query_vals[k]
            params[#params+1] = k .. '=' .. v
        end
        local normalized = tconcat(params, '&')
        self.oauth_signature_base_string = self.method:upper() .. '&' .. escape5849(base_url)
                                                               .. '&' .. escape5849(normalized)
    end
    self.url = url.build {
        scheme  = env.spore.url_scheme,
        host    = env.HTTP_HOST or env.SERVER_NAME,
        port    = env.SERVER_PORT,
        path    = (env.SCRIPT_NAME or '/') .. path_info,
        query   = query_string,
    }
end

--
-- Copyright (c) 2010 Francois Perrad
--
-- This library is licensed under the terms of the MIT/X11 license,
-- like Lua itself.
--
