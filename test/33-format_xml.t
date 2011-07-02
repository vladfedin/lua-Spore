#!/usr/bin/env lua

require 'Test.More'

if not pcall(require, 'lxp.lom') then
    skip_all 'no xml'
end

plan(14)

if not require_ok 'Spore.Middleware.Format.XML' then
    skip_rest "no Spore.Middleware.Format.XML"
    os.exit()
end
local mw = require 'Spore.Middleware.Format.XML'

local payload = {
    config = {
        logdir = '/var/log/foo/',
        debugfile = '/tmp/foo.debug',
        server = {
            sahara = {
                address = {
                    '10.0.0.101',
                    '10.0.1.101',
                },
            },
            gobi = {
                address = {
                    '10.0.0.102',
                },
            },
            kalahari = {
                address = {
                    '10.0.0.103',
                    '10.0.1.103',
                },
            },
        },
    },
}
local env = {
    spore = {
        payload = payload
    },
}
local req = require 'Spore.Request'.new(env)
local cb = mw.call({}, req)
type_ok( cb, 'function', "returns a function" )
is( env.spore.payload, [[<config logdir="/var/log/foo/" debugfile="/tmp/foo.debug"><server><sahara><address>10.0.0.101</address><address>10.0.1.101</address></sahara><gobi><address>10.0.0.102</address></gobi><kalahari><address>10.0.0.103</address><address>10.0.1.103</address></kalahari></server></config>]], "payload encoded")

env.spore.payload = payload
local req = require 'Spore.Request'.new(env)
local cb = mw.call({ indent = '  ', key_attr = { server = 'name' } }, req)
is( env.spore.payload, [[
<config logdir="/var/log/foo/" debugfile="/tmp/foo.debug">
  <server name="sahara">
    <address>10.0.0.101</address>
    <address>10.0.1.101</address>
  </server>
  <server name="gobi">
    <address>10.0.0.102</address>
  </server>
  <server name="kalahari">
    <address>10.0.0.103</address>
    <address>10.0.1.103</address>
  </server>
</config>
]], "payload encoded with options")

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
is( data.user.username, 'john', "username is john" )
is( data.user.password, 's3kr3t', "password is s3kr3t" )

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
