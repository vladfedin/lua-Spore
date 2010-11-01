#!/usr/bin/env lua

--[[
        http://term.ie/oauth/example is an OAuth Test Server
--]]

local Spore = require 'Spore'

local client = Spore.new_from_string [[
{
    "base_url" : "http://term.ie/oauth/example",
    "name" : "term.ie",
    "methods" : {
        "echo" : {
            "path" : "/echo_api.php",
            "method" : "GET",
            "unattended_params" : true,
            "expected_status" : [ 200 ]
        }
    },
    "authentication" : true
}
]]
client:enable('Auth.OAuth', {
    consumer_key    = 'key',
    consumer_secret = 'secret',
    token           = 'accesskey',
    token_secret    = 'accesssecret',
})
local r = client:echo{ method = 'foo', bar = 'baz' }
print(r.body)

