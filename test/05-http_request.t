#!/usr/bin/env lua

require 'Test.More'

plan(5)

local headers = {}
package.loaded['socket.http'] = {
    request = function (req) return req, 200, headers end -- mock
}

local Spore = require 'Spore'

local client = Spore.new_from_spec './test/api.json'

local res = client:get_user_info{ payload = 'opaque data', user = 'john' }
is( res.headers, headers, "without middleware" )

client:enable 'Format.JSON'
local res = client:get_user_info{ payload = 'opaque data', user = 'john' }
is( res.headers, headers, "with middleware" )

client:enable 'UserAgent'
local res = client:get_info()
is( res.headers, headers, "with middleware" )

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
