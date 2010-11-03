#!/usr/bin/env lua

require 'Spore'

require 'Test.More'

plan(9)

local response = { status = 200 }
Spore.Protocols.request = function (req) return response end -- mock

local client = Spore.new_from_spec './test/api.json'

local res = client:get_user_info{ payload = '@file', user = 'john' }
is( res, response, "without middleware" )

client:enable 'Format.JSON'
local res = client:get_user_info{ payload = '@file', user = 'john' }
is( res, response, "with middleware" )

client:enable 'UserAgent'
local res = client:get_info()
is( res, response, "with middleware" )

Spore.errors = io.tmpfile()
response.status = 404
r, ex = pcall( function ()
    local res = client:get_user_info{ payload = '@file', user = 'john' }
end)
is( r, false, "exception" )
is( tostring(ex), "404 not expected", "404 not expected" )

Spore.errors:seek'set'
local msg = Spore.errors:read '*l'
is( msg, "GET http://services.org:9999/restapi/show?user=john" )
local msg = Spore.errors:read '*l'
is( msg, "404" )

package.loaded['Spore.Middleware.Dummy'] = {}
local dummy_resp = { status = 200 }
require 'Spore.Middleware.Dummy'.call = function (self, req)
    return dummy_resp
end

client:reset_middlewares()
client:enable 'Dummy'
local res = client:get_info()
is( res, dummy_resp )

dummy_resp.status = 599
local res = client:get_info()
is( res, dummy_resp )
