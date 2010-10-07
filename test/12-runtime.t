#!/usr/bin/env lua

require 'Spore.Request'

require 'Test.More'

plan(6)

if not require_ok 'Spore.Middleware.Runtime' then
    skip_rest "no Spore.Middleware.Runtime"
    os.exit()
end

local req = Spore.Request.new({})
type_ok( req, 'table', "Spore.Request.new" )

local cb = Spore.Middleware.Runtime.call( {}, req )
type_ok( cb, 'function' )

for i = 1, 1000000 do end
local res = { headers = {} }
is( res, cb(res) )
local header = res.headers['x-spore-runtime']
type_ok( header, 'string' )
diag(header)
local val = tonumber(header)
ok( val > 0 )
