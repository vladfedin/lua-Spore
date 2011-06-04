#!/usr/bin/env lua

local Spore = require 'Spore'

require 'Test.More'

plan(31)

local status = 200
require 'Spore.Protocols'.request = function (req) return { request = req, status = status } end -- mock

local client = Spore.new_from_spec('./test/api.json', {})

error_like( function () client:get_info(true) end,
            "bad argument #2 to get_info %(table expected, got boolean%)" )

local res = client:get_info{ 'border'; user = 'john' }
local env = res.request.env
type_ok( res, 'table' )
is( env.REQUEST_METHOD, 'GET' )
is( env.SERVER_NAME, 'services.org' )
is( env.SERVER_PORT, '9999' )
is( env.PATH_INFO, '/restapi/show' )
like( env.HTTP_USER_AGENT, '^lua%-Spore' )
type_ok( env.spore, 'table' )
is( env.spore.url_scheme, 'http' )
is( env.spore.params.user, 'john' )
is( env.spore.params.border, 'border' )

error_like( function () client:get_user_info{} end,
            "payload is required for method get_user_info" )

error_like( function () client:get_user_info{ payload = '@file' } end,
            "user is required for method get_user_info" )

local res = client:get_info{ user = 'joe' }
local env = res.request.env
is( env.spore.params.user, 'joe' )

error_like( function () client:get_info{ payload = '@file' } end,
            "payload is not expected for method get_info" )

error_like( function () client:get_info{ mode = 'raw' } end,
            "mode is not expected for method get_info" )

client = Spore.new_from_spec('./test/api.json', { unattended_params = true })
lives_ok( function () client:get_info{ mode = 'raw' } end )

Spore.errors = io.tmpfile()
status = 404
r, ex = pcall( function ()
    local res = client:get_user_info{ payload = '@file', user = 'john' }
end)
is( r, false, "exception" )
is( tostring(ex), "404 not expected", "404 not expected" )

Spore.errors:seek'set'
local msg = Spore.errors:read '*l'
is( msg, "GET http://services.org:9999/restapi/show?user=john" )
local msg = Spore.errors:read '*l'
is( msg, "404" )

local res = client:action1{ user = 'john' }
local env = res.request.env
is( env.REQUEST_METHOD, 'GET' )
is( env.SERVER_NAME, 'services.org' )
is( env.SERVER_PORT, '9999' )
is( env.PATH_INFO, '/restapi/doit' )
is( env.QUERY_STRING, 'action=action1&user=john' )
is( res.request.url, 'http://services.org:9999/restapi/doit?action=action1&user=john' )

local client = Spore.new_from_string([[
{
    base_url : "http://services.org/restapi/get_info",
    methods : {
        get_info : {
            path : "",
            method : "GET",
        }
    }
}
]])
type_ok( client, 'table', "empty path")
local res = client:get_info()
local env = res.request.env
is( env.PATH_INFO, '/restapi/get_info' )
nok( env.QUERY_STRING )
is( res.request.url, 'http://services.org/restapi/get_info' )

