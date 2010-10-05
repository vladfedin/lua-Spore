#!/usr/bin/env lua

require 'Spore.Request'

require 'Test.More'

plan(6)

if not require_ok 'Spore.Middleware.Format.JSON' then
    skip_rest "no Spore.Middleware.Format.JSON"
    os.exit()
end

local req = Spore.Request.new({ spore = {} })
local cb = Spore.Middleware.Format.JSON.call({}, req)
type_ok( cb, 'function', "returns a function" )

local resp = {
    status = 200,
    headers = {},
    body = [[
{
    "username" : "john",
    "password" : "s3kr3t"
}
]]
}

local ret = cb(resp)
is( ret, resp, "returns same table" )
local data = ret.body
type_ok( data, 'table' )
is( data.username, 'john', "username is john" )
is( data.password, 's3kr3t', "password is s3kr3t" )

