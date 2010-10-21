#!/usr/bin/env lua

require 'Spore.Request'
require 'Spore'

require 'Test.More'

plan(5)

local response = { status = 222, headers = {} }
Spore.request = function (req) return response end -- mock

if not require_ok 'Spore.Middleware.Redirection' then
    skip_rest "no Spore.Middleware.Redirection"
    os.exit()
end

local req = Spore.Request.new({ spore = {} })
type_ok( req, 'table', "Spore.Request.new" )

local cb = Spore.Middleware.Redirection.call( {}, req )
type_ok( cb, 'function' )

local res = { status = 200, headers = {} }
r = cb(res)
is( r, res )

local res = { status = 301, headers = { location = "http://next.org" } }
r = cb(res)
is( r, response )
