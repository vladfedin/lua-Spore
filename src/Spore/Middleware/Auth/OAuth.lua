--
-- lua-Spore : <http://fperrad.github.com/lua-Spore/>
--

local error = error
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
    and self.oauth_consumer_key and self.oauth_consumer_secret then
        local env = req.env
        local spore = env.spore
        local params = spore.params
        params.oauth_consumer_key = self.oauth_consumer_key
        params.oauth_nonce = generate_nonce()
        params.oauth_signature_method = self.oauth_signature_method or 'HMAC-SHA1'
        params.oauth_timestamp = generate_timestamp()
        params.oauth_token = self.oauth_token
        params.oauth_version = '1.0'
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

        local headers = req.headers
        local authorization = headers['authorization']
        if authorization then
            headers['authorization'] = authorization:gsub(':oauth_signature', (oauth_signature:gsub('%%', '%%%%')))
        else
            local www_authenticate = headers['www-authenticate']
            if www_authenticate then
                headers['www-authenticate'] = www_authenticate:gsub(':oauth_signature', (oauth_signature:gsub('%%', '%%%%')))
            else
                if spore.payload == '@oauth' then
                    spore.payload = 'oauth_consumer_key='     .. params.oauth_consumer_key
                                .. '&oauth_nonce='            .. params.oauth_nonce
                                .. '&oauth_signature_method=' .. params.oauth_signature_method
                                .. '&oauth_timestamp='        .. params.oauth_timestamp
                                .. '&oauth_token='            .. params.oauth_token
                                .. '&oauth_version='          .. params.oauth_version
                                .. '&oauth_signature='        .. oauth_signature
                else
                    req.url = req.url .. '&oauth_signature=' .. oauth_signature
                end
            end
        end
        return Spore.request(req)
    end
end

--
-- Copyright (c) 2010 Francois Perrad
--
-- This library is licensed under the terms of the MIT/X11 license,
-- like Lua itself.
--
