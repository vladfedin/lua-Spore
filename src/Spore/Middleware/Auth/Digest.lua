--
-- lua-Spore : <http://fperrad.github.com/lua-Spore/>
--

local time = require 'os'.time
local format = require 'string'.format
local evp = require 'crypto'.evp
local url = require 'socket.url'
local Protocols = require 'Spore.Protocols'


_ENV = nil
local m = {}

--  see RFC-2617

function m.generate_nonce ()
    return format('%08x', time())
end

local function path_query (uri)
    local t = url.parse(uri)
    return url.build{ path = t.path, query = t.query }
end

local function add_header(challenge, req)
    challenge.nc = challenge.nc + 1
    local nc = format('%08X', challenge.nc)
    local cnonce = m.generate_nonce()
    local uri = path_query(req.url)
    local ha1, ha2, response
    ha1 = evp.digest('md5', challenge.username .. ':'
                         .. challenge.realm .. ':'
                         .. challenge.password)
    ha2 = evp.digest('md5', req.method .. ':'
                         .. uri)
    if challenge.qop then
        response = evp.digest('md5', ha1 .. ':'
                                  .. challenge.nonce .. ':'
                                  .. nc .. ':'
                                  .. cnonce .. ':'
                                  .. challenge.qop .. ':'
                                  .. ha2)
    else
        response = evp.digest('md5', ha1 .. ':'
                                  .. challenge.nonce .. ':'
                                  .. ha2)
    end
    local auth = 'Digest username="' .. challenge.username
              .. '", realm="' .. challenge.realm
              .. '", nonce="' .. challenge.nonce
              .. '", uri="' .. uri
              .. '", algorithm="' .. challenge.algorithm
              .. '", nc=' .. nc
              .. ', cnonce="' .. cnonce
              .. '", response="' .. response
              .. '", opaque="' .. challenge.opaque .. '"'
    if challenge.qop then
        auth = auth .. ', qop=' .. challenge.qop
    end
    req.headers['authorization'] = auth
end

function m:call (req)
    if req.env.spore.authentication and self.username and self.password then
        if self.nonce then
            req:finalize()
            add_header(self, req)
        end

        return  function (res)
            if res.status == 401 and res.headers['www-authenticate'] then
                for k, v in res.headers['www-authenticate']:gmatch'(%w+)="([^"]*)"' do
                    self[k] = v
                end
                if self.qop and self.qop ~= 'auth-int' then
                    self.qop = 'auth'
                end
                if not self.algorithm then
                    self.algorithm = 'MD5'
                end
                self.nc = 0
                add_header(self, req)
                return Protocols.request(req)
            end
            return res
        end
    end
end

return m
--
-- Copyright (c) 2011 Francois Perrad
--
-- This library is licensed under the terms of the MIT/X11 license,
-- like Lua itself.
--
