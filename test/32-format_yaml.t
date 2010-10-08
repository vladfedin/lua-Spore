#!/usr/bin/env lua

require 'Spore.Request'

require 'Test.More'

r, msg = pcall(require, 'yaml')
if not r then
    skip_all 'no yaml'
end

plan(9)

if not require_ok 'Spore.Middleware.Format.YAML' then
    skip_rest "no Spore.Middleware.Format.YAML"
    os.exit()
end

local env = {
    spore = {},
}
local req = Spore.Request.new(env)
local cb = Spore.Middleware.Format.YAML.call({}, req)
type_ok( cb, 'function', "returns a function" )

local resp = {
    status = 200,
    headers = {},
    body = [[
username : "john"
password : "s3kr3t"
]]
}

local ret = cb(resp)
is( req.headers['accept'], 'text/x-yaml' )
is( ret, resp, "returns same table" )
is( ret.status, 200, "200 OK" )
local data = ret.body
type_ok( data, 'table' )
is( data.username, 'john', "username is john" )
is( data.password, 's3kr3t', "password is s3kr3t" )

resp.body = [[
username : "john"
INV?LID
]]
error_like( function () cb(resp) end,
            "syntax error" )
