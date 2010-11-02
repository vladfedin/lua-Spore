#!/usr/bin/env lua

--[[
        http://term.ie/oauth/example is an OAuth Test Server
--]]

local Spore = require 'Spore'

local keys = {
    consumer_key    = 'key',
    consumer_secret = 'secret',
}
local client = Spore.new_from_string [[
{
    "base_url" : "http://term.ie/oauth/example",
    "name" : "term.ie",
    "methods" : {
        "get_request_token" : {
            "path" : "/request_token.php",
            "method" : "GET"
        },
        "get_access_token" : {
            "path" : "/access_token.php",
            "method" : "GET"
        },
        "echo" : {
            "path" : "/echo_api.php",
            "method" : "GET",
            "unattended_params" : true
        }
    },
    "expected_status" : [ 200 ],
    "authentication" : true
}
]]
client:enable('Auth.OAuth', keys)

local r = client:get_request_token()
print(r.body)
for k, v in r.body:gmatch'([^&=]+)=([^&=]*)&?' do keys[k:sub(7)] = v end
assert(keys.token == 'requestkey')
assert(keys.token_secret == 'requestsecret')

local r = client:get_access_token()
print(r.body)
for k, v in r.body:gmatch'([^&=]+)=([^&=]*)&?' do keys[k:sub(7)] = v end
assert(keys.token == 'accesskey')
assert(keys.token_secret == 'accesssecret')

local r = client:echo{ method = 'foo', bar = 'baz' }
print(r.body)
assert(r.body, 'bar=baz&method=foo')

print 'ok - http://term.ie/oauth/example'
