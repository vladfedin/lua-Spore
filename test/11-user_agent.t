#!/usr/bin/env lua

require 'Spore.Request'

require 'Test.More'

plan(8)

if not require_ok 'Spore.Middleware.UserAgent' then
    skip_rest "no Spore.Middleware.UserAgent"
    os.exit()
end

local req = Spore.Request.new({})
type_ok( req, 'table', "Spore.Request.new" )
type_ok( req.headers, 'table' )
is( req.headers['user-agent'], nil )

local r = Spore.Middleware.UserAgent.call( {}, req )
is( req.headers['user-agent'], nil, "user-agent is not set" )
is( r, nil )

r = Spore.Middleware.UserAgent.call( { useragent = "MyAgent" }, req )
is( req.headers['user-agent'], "MyAgent", "user-agent is set" )
is( r, nil )
