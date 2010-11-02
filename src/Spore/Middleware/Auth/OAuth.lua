--
-- lua-Spore : <http://fperrad.github.com/lua-Spore/>
--

local tostring = tostring
local math = require 'math'
local os = require 'os'
local crypto = require 'crypto'.hmac
local mime = require 'mime'
local Spore = require 'Spore'
local escape = Spore.Request.escape5849


module 'Spore.Middleware.Auth.OAuth'

--[[
        Homepage: http://oauth.net/

        RFC 5849 : The OAuth 1.0 Protocol
--]]

local function generate_timestamp()
    return tostring(os.time())
end

local function generate_nonce()
    return crypto.digest('sha1', tostring(math.random()) .. 'random' .. tostring(os.time()), 'keyyyy')
end

function call (self, req)
    if req.env.spore.authentication
    and self.consumer_key and self.consumer_secret then
        local env = req.env
        local spore = env.spore
        local params = spore.params
        params.oauth_consumer_key = self.consumer_key
        params.oauth_nonce = generate_nonce()
        params.oauth_signature_method = 'HMAC-SHA1'
        params.oauth_timestamp = generate_timestamp()
        params.oauth_token = self.token
        params.oauth_version = '1.0'
        req:finalize(true)
        local signature_key = escape(self.consumer_secret) .. '&' .. escape(self.token_secret or '')
        local hmac_binary = crypto.digest('sha1', req.oauth_signature_base_string, signature_key, true)
        local hmac_b64 = mime.b64(hmac_binary)
        local oauth_signature = escape(hmac_b64)
        req.url = req.url .. '&oauth_signature=' .. oauth_signature
        return Spore.request(req)
    end
end

--
-- Copyright (c) 2010 Francois Perrad
--
-- This library is licensed under the terms of the MIT/X11 license,
-- like Lua itself.
--
