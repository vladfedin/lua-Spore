#!/usr/bin/env lua

require 'Spore.Request'

require 'Test.More'

if not pcall(require, 'OAuth') then
    skip_all 'no OAuth'
end

plan(11)

OAuth.Sign = function () return nil, nil, 'mocked' end -- mock

if not require_ok 'Spore.Middleware.Auth.OAuth' then
    skip_rest "no Spore.Middleware.Auth.OAuth"
    os.exit()
end

local req = Spore.Request.new({ spore = {} })
type_ok( req, 'table', "Spore.Request.new" )
type_ok( req.headers, 'table' )
is( req.headers['authorization'], nil )

local r = Spore.Middleware.Auth.OAuth.call({}, req)
is( req.headers['authorization'], nil, "authorization is not set" )
is( r, nil )

local data = {
        consumer_key    = 'xxx',
        consumer_secret = 'yyy',
        token           = '123',
        token_secret    = '456',
}
r = Spore.Middleware.Auth.OAuth.call(data, req)
is( req.headers['authorization'], nil, "authorization is not set" )
is( r, nil )

req.env.spore.authentication = true
r = Spore.Middleware.Auth.OAuth.call(data, req)
local auth = req.headers['authorization']
type_ok( auth, 'string', "authorization is set" )
is( auth, 'mocked' )
is( r, nil )
