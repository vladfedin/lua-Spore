#!/usr/bin/env lua

--[[
        http://term.ie/oauth/example is an OAuth Test Server
--]]

local Spore = require 'Spore'

local keys = {
    oauth_consumer_key    = 'key',
    oauth_consumer_secret = 'secret',
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
        },
        "echo_p" : {
            "path" : "/echo_api.php",
            "method" : "POST",
            "required_payload" : true
        }
    },
    "expected_status" : [ 200 ],
    "authentication" : true
}
]]
client:enable('Auth.OAuth', keys)

local r = client:get_request_token()
print(r.body)
for k, v in r.body:gmatch'([^&=]+)=([^&=]*)&?' do keys[k] = v end
assert(keys.oauth_token == 'requestkey')
assert(keys.oauth_token_secret == 'requestsecret')

local r = client:get_access_token()
print(r.body)
for k, v in r.body:gmatch'([^&=]+)=([^&=]*)&?' do keys[k] = v end
assert(keys.oauth_token == 'accesskey')
assert(keys.oauth_token_secret == 'accesssecret')

local r = client:echo{ method = 'foo', bar = 'baz' }
print(r.body)
assert(r.body == 'bar=baz&method=foo')

local r = client:echo_p{ payload = '@oauth' }
print(r.body)
assert(r.body == '')

print 'ok - http://term.ie/oauth/example'
