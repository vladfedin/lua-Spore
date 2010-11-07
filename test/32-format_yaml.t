#!/usr/bin/env lua

require 'Test.More'

if not pcall(require, 'yaml') then
    skip_all 'no yaml'
end

plan(13)

if not require_ok 'Spore.Middleware.Format.YAML' then
    skip_rest "no Spore.Middleware.Format.YAML"
    os.exit()
end
local mw = require 'Spore.Middleware.Format.YAML'

local env = {
    spore = {
        payload = {
            lua = 'table',
        },
    },
}
local req = require 'Spore.Request'.new(env)
local cb = mw.call({}, req)
type_ok( cb, 'function', "returns a function" )
is( env.spore.payload, [[
--- 
lua: table
]], "payload encoded")

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
env.spore.errors = io.tmpfile()
local r, ex = pcall(cb, resp)
nok( r )
like( ex.reason, "syntax error" )
env.spore.errors:seek'set'
local msg = env.spore.errors:read '*l'
like( msg, "syntax error", "syntax error" )

local msg = env.spore.errors:read '*a'
is( msg, resp.body .. "\n")

