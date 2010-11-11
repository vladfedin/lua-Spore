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


_ENV = nil
local m = {}

m.redirect = false

function m.new (env)
    local obj = {
        env = env,
        redirect = m.redirect,
        headers = {
            ['user-agent'] = env.HTTP_USER_AGENT,
        },
    }
    return setmetatable(obj, {
        __index = m,
    })
end

local function escape5849(s)
    -- see RFC 5849, Section 3.6
    return string.gsub(s, '[^-._~%w]', function(c)
        return string.upper(string.format('%%%02x', string.byte(c)))
    end)
end
m.escape5849 = escape5849

function m:finalize (oauth)
    local env = self.env
    local spore = env.spore
    if not require 'Spore'.early_validate then
        require 'Spore'.validate(spore.caller, spore.method, spore.params, spore.payload)
    end
    local path_info = env.PATH_INFO
    local query_string = env.QUERY_STRING
    local form_data = {}
    for k, v in pairs(spore.form_data or {}) do form_data[k] = v end
    local headers = {}
    for k, v in pairs(spore.headers or {}) do headers[k] = v end
    local payload = spore.payload
    local query, query_keys, query_vals = {}, {}, {}
    if query_string then
        if oauth then
            for k, v in query_string:gmatch '([^=]+)=([^&])&?' do
                query_keys[#query_keys+1] = k
                query_vals[k] = v
            end
        else
            query[1] = query_string
        end
    end
    local form = {}
    for k, v in pairs(spore.params) do
        k = tostring(k)
        v = tostring(v)
        local e = url.escape(v)
        local n
        path_info, n = path_info:gsub(':' .. k, (e:gsub('%%', '%%%%')))
        for kk, vv in pairs(form_data) do
            kk = tostring(kk)
            vv = tostring(vv)
            local nn
            vv, nn = vv:gsub(':' .. k, v)
            if nn > 0 then
                form_data[kk] = vv
                form[kk] = vv
                n = n + 1
            end
        end
        for kk, vv in pairs(headers) do
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
        if n == 0 then
            if oauth then
                if not k:match'^oauth_' or payload ~= '@oauth' then
                    query_keys[#query_keys+1] = escape5849(k)
                    query_vals[k] = escape5849(v)
                end
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
    if #query > 0 then
        query_string = tconcat(query, '&')
    end
    env.PATH_INFO = path_info
    env.QUERY_STRING = query_string
    if spore.form_data then
        spore.form_data = form
    end
    self.method = env.REQUEST_METHOD
    if oauth then
        local base_url = url.build {
            scheme  = env.spore.url_scheme,
            host    = env.SERVER_NAME,
            port    = env.SERVER_PORT,
            path    = path_info,
            -- no query
        }
        for k, v in pairs(spore.params) do
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
        scheme  = spore.url_scheme,
        host    = env.SERVER_NAME,
        port    = env.SERVER_PORT,
        path    = path_info,
        query   = query_string,
    }
end

return m
--
-- Copyright (c) 2010 Francois Perrad
--
-- This library is licensed under the terms of the MIT/X11 license,
-- like Lua itself.
--
