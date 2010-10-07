
--
-- lua-Spore : <http://fperrad.github.com/lua-Spore/>
--

local require = require
local type = type
local tconcat = require 'table'.concat
local ltn12 = require 'ltn12'
local Request = require 'Spore.Request'


module 'Spore.Core'

local protocol = {
    http    = require 'socket.http',
    https   = require 'ssl.https',
}

function enable (self, mw, args)
    local checktype = require 'Spore'.checktype
    checktype('enable', 2, mw, 'string')
    args = args or {}
    checktype('enable', 3, args, 'table')
    if not mw:match'^Spore%.Middleware%.' then
        mw = 'Spore.Middleware.' .. mw
    end
    local m = require(mw)
    local f = function (req)
        return m.call(args, req)
    end
    local t = self.middlewares; t[#t+1] = f
end

function reset_middlewares (self)
    self.middlewares = {}
end

function http_request (self, env)
    local req = Request.new(env)
    local callbacks = {}
    local response
    local middlewares = self.middlewares
    for i = 1, #middlewares do
        local mw = middlewares[i]
        local res = mw(req)
        if type(res) == 'function' then
            callbacks[#callbacks+1] = res
        elseif res then
            if res.status == 599 then
                return res
            end
            response = res
            break
        end
    end

    if response == nil then
        req:finalize()
        response = self:request(req)
    end

    for i = #callbacks, 1, -1 do
        local cb = callbacks[i]
        response = cb(response)
    end
    return response
end

function request (self, req)
    local t = {}
    req.sink = ltn12.sink.table(t)
    local spore = req.env.spore
    local payload = spore.payload
    if payload then
        req.source = ltn12.source.string(payload)
        req.headers['content-length'] = payload:len()
        req.headers['content-type'] = 'application/x-www-form-urlencoded'
    end
    local prot = protocol[spore.url_scheme]
    local r, status, headers = prot.request(req)
    return {
        status = status,
        headers = headers,
        body = tconcat(t),
    }
end

--
-- Copyright (c) 2010 Francois Perrad
--
-- This library is licensed under the terms of the MIT/X11 license,
-- like Lua itself.
--
