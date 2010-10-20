#!/usr/bin/env lua

require 'Spore.Request'

require 'Test.More'

if not pcall(require, 'lxp.lom') then
    skip_all 'no xml'
end

plan(12)

if not require_ok 'Spore.Middleware.Format.XML' then
    skip_rest "no Spore.Middleware.Format.XML"
    os.exit()
end

local env = {
    spore = {},
}
local req = Spore.Request.new(env)
local cb = Spore.Middleware.Format.XML.call({}, req)
type_ok( cb, 'function', "returns a function" )

local resp = {
    status = 200,
    headers = {},
    body = [[
<user username="john" password="s3kr3t" />
]]
}

local ret = cb(resp)
is( req.headers['accept'], 'text/xml' )
is( ret, resp, "returns same table" )
is( ret.status, 200, "200 OK" )
local data = ret.body
type_ok( data, 'table' )
is( data.attr.username, 'john', "username is john" )
is( data.attr.password, 's3kr3t', "password is s3kr3t" )

resp.body = [[
{ INVALID }
]]
env.spore.errors = io.tmpfile()
local r, ex = pcall(cb, resp)
nok( r )
is( ex.reason, "not well-formed (invalid token)" )
env.spore.errors:seek'set'
local msg = env.spore.errors:read '*l'
is( msg, "not well-formed (invalid token)", "Invalid XML" )

local msg = env.spore.errors:read '*a'
is( msg, resp.body .. "\n")
