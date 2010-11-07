#!/usr/bin/env lua

require 'Test.More'

if not pcall(require, 'crypto') then
    skip_all 'no crypto'
end

plan(8)

local response = { status = 200, headers = {} }
require 'Spore.Protocols'.request = function (req)
    like(req.url, "^http://services.org:9999/restapi/show%?dummy&oauth_signature=[%%%w]+$")
    return response
end -- mock
require 'Spore.Request'.finalize = function (self)
    self.method = 'GET'
    self.url = 'http://services.org:9999/restapi/show?dummy'
    self.oauth_signature_base_string = self.url
end -- mock

if not require_ok 'Spore.Middleware.Auth.OAuth' then
    skip_rest "no Spore.Middleware.Auth.OAuth"
    os.exit()
end
local mw = require 'Spore.Middleware.Auth.OAuth'

local req = require 'Spore.Request'.new({ spore = { params = {} } })
type_ok( req, 'table', "Spore.Request.new" )
type_ok( req.headers, 'table' )

local r = mw.call({}, req)
is( r, nil )

local data = {
    oauth_consumer_key    = 'xxx',
    oauth_consumer_secret = 'yyy',
    oauth_token           = '123',
    oauth_token_secret    = '456',
}
r = mw.call(data, req)
is( r, nil )

req.env.spore.authentication = true
r = mw.call(data, req)
is( r, response )

error_like( function ()
    data.oauth_signature_method = 'UNKNOWN'
    mw.call(data, req)
end, "UNKNOWN is not supported" )

