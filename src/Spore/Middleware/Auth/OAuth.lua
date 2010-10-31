--
-- lua-Spore : <http://fperrad.github.com/lua-Spore/>
--

local tostring = tostring
local math = require 'math'
local os = require 'os'
local crypto = require 'crypto'.hmac
local OAuth = require 'OAuth'


module 'Spore.Middleware.Auth.OAuth'

local function generate_timestamp()
    return tostring(os.time())
end

local function generate_nonce()
    return crypto.digest('sha1', tostring(math.random()) .. "random" .. tostring(os.time()),"keyyyy")
end

function call (self, req)
    if req.env.spore.authentication
    and self.consumer_key and self.consumer_secret
    and self.token and self.token_secret then
        local client = OAuth.new(
            self.consumer_key,
            self.consumer_secret, {
                req.url,
                method = req.method,
            }, {
                OAuthToken = self.token,
                OAuthTokenSecret = self.token_secret,
                SignatureMethod = 'HMAC-SHA1',
        })
        local args = {
            oauth_consumer_key = self.consumer_key,
            oauth_nonce = generate_nonce(),
            oauth_signature_method = req.method,
            oauth_timestamp = generate_timestamp(),
            oauth_version = '1.0',
        }
        local _, _, auth = client:Sign(req.method, req.url, args, self.token_secret)
        req.headers['authorization'] = auth
    end
end

--
-- Copyright (c) 2010 Francois Perrad
--
-- This library is licensed under the terms of the MIT/X11 license,
-- like Lua itself.
--
