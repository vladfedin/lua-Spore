#!/usr/bin/env lua

require 'Spore'

require 'Test.More'

plan(8)

local i = 0
Spore.Protocols.request = function (req)
    i = i + 1
    return { body = tostring(i) }
end -- mock

if not require_ok 'Spore.Middleware.Cache' then
    skip_rest "no Spore.Middleware.Cache"
    os.exit()
end

local client = Spore.new_from_spec './test/api.json'

local r = client:get_info()
is( r.body, '1' )
local r = client:get_info()
is( r.body, '2', "not cached" )

client:enable 'Cache'
local r = client:get_info()
is( r.body, '3' )

local r = client:get_info{ user = 'john' }
is( r.body, '4' )

local r = client:get_info()
is( r.body, '3', "cached" )

local r = client:get_info{ user = 'john' }
is( r.body, '4', "cached" )

Spore.Middleware.Cache.reset()

local r = client:get_info()
is( r.body, '5', "reset" )
