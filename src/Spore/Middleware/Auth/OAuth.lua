--
-- lua-Spore : <http://fperrad.github.com/lua-Spore/>
--

local assert = assert
local tostring = tostring
local math = require 'math'
local os = require 'os'
local crypto = require 'crypto'.hmac
local OAuth = require 'OAuth'
local Spore = require 'Spore'


module 'Spore.Middleware.Auth.OAuth'

local function generate_timestamp()
    return tostring(os.time())
end

local function generate_nonce()
    return crypto.digest('sha1', tostring(math.random()) .. 'random' .. tostring(os.time()), 'keyyyy')
end

function call (self, req)
    if req.env.spore.authentication
    and self.consumer_key and self.consumer_secret
    and self.token and self.token_secret then
        local env = req.env
        local spore = env.spore
        assert(not spore.form_data, "TODO: filter form-data")
        assert(not spore.headers, "TODO: filter headers")
        local client = OAuth.new(
            self.consumer_key,
            self.consumer_secret,
            nil, {
                OAuthToken = self.token,
                OAuthTokenSecret = self.token_secret,
        })
        local params = spore.params
        params.oauth_consumer_key = self.consumer_key
        params.oauth_nonce = generate_nonce()
        params.oauth_signature_method = 'HMAC-SHA1'
        params.oauth_timestamp = generate_timestamp()
        params.oauth_token = self.token
        params.oauth_version = '1.0'
        req:finalize()
        local base = req.url
        base = base:sub(1, base:find('?') - 1)
        local _, query, auth = client:Sign(req.method, base, params, self.token_secret)
--        req.headers['authorization'] = auth
        req.url = base .. '?' .. query
        return Spore.request(req)
    end
end

--
-- Copyright (c) 2010 Francois Perrad
--
-- This library is licensed under the terms of the MIT/X11 license,
-- like Lua itself.
--
