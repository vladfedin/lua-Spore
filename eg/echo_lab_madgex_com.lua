#!/usr/bin/env lua

--[[
        http://echo.lab.madgex.com is an OAuth Test Server
--]]

local Spore = require 'Spore'

local client = Spore.new_from_string [[
{
    "base_url" : "http://echo.lab.madgex.com",
    "name" : "madgex",
    "methods" : {
        "echo" : {
            "path" : "/echo.ashx",
            "method" : "GET",
            "unattended_params" : true,
            "expected_status" : [ 200, 401 ]
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
local r = client:echo{ method = 'foo bar', bar = 'baz' }
print(r.body)

