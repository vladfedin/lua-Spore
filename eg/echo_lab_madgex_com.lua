#!/usr/bin/env lua

--[[
        http://echo.lab.madgex.com is an OAuth Test Server
--]]

local Spore = require 'Spore'

local keys = {
    realm = '',
    oauth_consumer_key    = 'key',
    oauth_consumer_secret = 'secret',
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
        "echo_p" : {
            "path" : "/echo.ashx",
            "method" : "POST",
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
for k, v in r.body:gmatch'([^&=]+)=([^&=]*)&?' do keys[k] = v end
assert(keys.oauth_token == 'requestkey')
assert(keys.oauth_token_secret == 'requestsecret')

local r = client:get_access_token()
assert(#r.body > 0, r.status)
print(r.body)
for k, v in r.body:gmatch'([^&=]+)=([^&=]*)&?' do keys[k] = v end
assert(keys.oauth_token == 'accesskey')
assert(keys.oauth_token_secret == 'accesssecret')

local r = client:echo{ method = 'foo bar', bar = 'baz' }
print(r.body)
assert(r.body == 'method=foo bar&bar=baz')

local r = client:echo_p{ method = 'foo bar', bar = 'baz' }
print(r.body)
assert(r.body == 'method=foo bar&bar=baz')

print 'ok - http://echo.lab.madgex.com'
print '1..1'
