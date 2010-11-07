#!/usr/bin/env lua

local Spore = require 'Spore'

require 'Test.More'

plan(5)

local response = { status = 200 }
require 'Spore.Protocols'.request = function (req) return response end -- mock

local client = Spore.new_from_spec './test/api.json'

local res = client:get_user_info{ payload = '@file', user = 'john' }
is( res, response, "without middleware" )

client:enable 'Format.JSON'
local res = client:get_user_info{ payload = '@file', user = 'john' }
is( res, response, "with middleware" )

client:enable 'UserAgent'
local res = client:get_info()
is( res, response, "with middleware" )

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
