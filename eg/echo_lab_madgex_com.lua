#!/usr/bin/env lua

--[[
        http://echo.lab.madgex.com is an OAuth Test Server
--]]

local Spore = require 'Spore'

local keys = {
    consumer_key    = 'key',
    consumer_secret = 'secret',
}
local client = Spore.new_from_string [[
{
    "base_url" : "http://echo.lab.madgex.com",
    "name" : "madgex",
    "methods" : {
        "get_request_token" : {
            "path" : "/request-token.ashx",
            "method" : "GET",
            "expected_status" : [ 200, 400 ]
        },
        "get_access_token" : {
            "path" : "/access-token.ashx",
            "method" : "GET",
            "expected_status" : [ 200, 400 ]
        },
        "echo" : {
            "path" : "/echo.ashx",
            "method" : "GET",
            "unattended_params" : true,
            "expected_status" : [ 200, 400, 401 ]
        },
        "echo_h" : {
            "path" : "/echo.ashx",
            "method" : "GET",
            "headers" : {
                "authorization" : "OAuth realm=\"\", oauth_consumer_key=\":oauth_consumer_key\", oauth_token=\":oauth_token\", oauth_signature_method=\":oauth_signature_method\", oauth_signature=\":oauth_signature\", oauth_timestamp=\":oauth_timestamp\", oauth_nonce=\":oauth_nonce\", oauth_version=\":oauth_version\""
            },
            "unattended_params" : true,
            "expected_status" : [ 200, 400, 401 ]
        }
    },
    "authentication" : true
}
]]
client:enable('Auth.OAuth', keys)

local r = client:get_request_token()
assert(#r.body > 0, r.status)
print(r.body)
for k, v in r.body:gmatch'([^&=]+)=([^&=]*)&?' do keys[k:sub(7)] = v end
assert(keys.token == 'requestkey')
assert(keys.token_secret == 'requestsecret')

local r = client:get_access_token()
assert(#r.body > 0, r.status)
print(r.body)
for k, v in r.body:gmatch'([^&=]+)=([^&=]*)&?' do keys[k:sub(7)] = v end
assert(keys.token == 'accesskey')
assert(keys.token_secret == 'accesssecret')

local r = client:echo{ method = 'foo bar', bar = 'baz' }
print(r.body)
assert(r.body == 'bar=baz&method=foo bar')

local r = client:echo_h{ method = 'foo bar', bar = 'baz' }
print(r.body)
assert(r.body == 'bar=baz&method=foo bar')

print 'ok - http://echo.lab.madgex.com'
