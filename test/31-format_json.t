#!/usr/bin/env lua

require 'Spore.Request'

require 'Test.More'

plan(11)

if not require_ok 'Spore.Middleware.Format.JSON' then
    skip_rest "no Spore.Middleware.Format.JSON"
    os.exit()
end

local env = {
    spore = {},
}
local req = Spore.Request.new(env)
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
is( req.headers['accept'], 'application/json' )
is( ret, resp, "returns same table" )
is( ret.status, 200, "200 OK" )
local data = ret.body
type_ok( data, 'table' )
is( data.username, 'john', "username is john" )
is( data.password, 's3kr3t', "password is s3kr3t" )

resp.body = [[
{
    "username" : "john",
    INVALID
}
]]
env.spore.errors = io.tmpfile()
error_like( function () cb(resp) end,
            "Invalid JSON data" )
env.spore.errors:seek'set'
local msg = env.spore.errors:read '*l'
like( msg, "Invalid JSON data", "Invalid JSON data" )

local msg = env.spore.errors:read '*a'
is( msg, resp.body .. "\n")
