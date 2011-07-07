--
-- lua-Spore : <http://fperrad.github.com/lua-Spore/>
--

local error = error
local tostring = tostring
local random = require 'math'.random
local time = require 'os'.time
local crypto = require 'crypto'.hmac
local mime = require 'mime'
local escape = require 'Spore.Request'.escape5849
local request = require 'Spore.Protocols'.request


_ENV = nil
local m = {}

--[[
        Homepage: http://oauth.net/

        RFC 5849 : The OAuth 1.0 Protocol
--]]

local function generate_timestamp()
    return tostring(time())
end

function m.generate_nonce()
    return crypto.digest('sha1', tostring(random()) .. 'random' .. tostring(time()), 'keyyyy')
end

function m:call (req)
    if req.env.spore.authentication
    and self.oauth_consumer_key and self.oauth_consumer_secret then
        local env = req.env
        local spore = env.spore
        local params = spore.params
        params.oauth_consumer_key = self.oauth_consumer_key
        params.oauth_nonce = m.generate_nonce()
        params.oauth_signature_method = self.oauth_signature_method or 'HMAC-SHA1'
        params.oauth_timestamp = generate_timestamp()
        params.oauth_version = '1.0'
        local auth = 'OAuth'
        if self.realm then
            auth = auth .. ' realm="' .. tostring(self.realm) .. '",'
        end
        auth = auth .. [[ oauth_consumer_key=":oauth_consumer_key", oauth_signature_method=":oauth_signature_method", oauth_timestamp=":oauth_timestamp", oauth_nonce=":oauth_nonce", oauth_signature=":oauth_signature", oauth_version=":oauth_version"]]
        if not self.oauth_token then    -- 1) request token
            params.oauth_callback = self.oauth_callback or 'oob'        -- out-of-band
            auth = auth .. [[, oauth_callback=":oauth_callback"]]
        else
            params.oauth_token = self.oauth_token
            if self.oauth_verifier then -- 2) access token
                params.oauth_verifier = self.oauth_verifier
                auth = auth .. [[, oauth_token=":oauth_token", oauth_verifier=":oauth_verifier"]]
            else                        -- 3) client requests
                auth = auth .. [[, oauth_token=":oauth_token"]]
            end
        end
        if not req.env.spore.headers then
            req.env.spore.headers = {}
        end
        req.env.spore.headers['authorization'] = auth
        req:finalize(true)

        local signature_key = escape(self.oauth_consumer_secret) .. '&' .. escape(self.oauth_token_secret or '')
        local oauth_signature
        if params.oauth_signature_method == 'PLAINTEXT' then
            oauth_signature = escape(escape(signature_key))
        else
            if params.oauth_signature_method == 'HMAC-SHA1' then
                local hmac_binary = crypto.digest('sha1', req.oauth_signature_base_string, signature_key, true)
                local hmac_b64 = mime.b64(hmac_binary)
                oauth_signature = escape(hmac_b64)
            else
                error(params.oauth_signature_method .. " is not supported")
            end
        end

        local auth = req.headers['authorization']
        req.headers['authorization'] = auth:gsub(':oauth_signature', (oauth_signature:gsub('%%', '%%%%')))
        return request(req)
    end
end

return m
--
-- Copyright (c) 2010-2011 Francois Perrad
--
-- This library is licensed under the terms of the MIT/X11 license,
-- like Lua itself.
--
