#!/usr/bin/env lua

require 'Test.More'

plan(52)

local status = 200
package.loaded['socket.http'] = {
    request = function (req) return req, status end -- mock
}

local Spore = require 'Spore'

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

error_like( function () client:get_user_info{ payload = 'opaque data' } end,
            "user is required for method get_user_info" )

local res = client:get_user_info{ user = 'joe', payload = 'OPAQUE' }
local env = res.request.env
is( env.spore.payload, 'OPAQUE', 'opaque payload' )

local res = client:get_info{ user = 'joe' }
local env = res.request.env
is( env.spore.params.user, 'joe' )

error_like( function () client:get_info{ payload = 'opaque data' } end,
            "payload is not expected for method get_info" )

error_like( function () client:get_info{ mode = 'raw' } end,
            "mode is not expected for method get_info" )

client = Spore.new_from_spec('./test/api.json', { unattended_params = true })
lives_ok( function () client:get_info{ mode = 'raw' } end )

Spore.errors = io.tmpfile()
status = 404
r, ex = pcall( function ()
    local res = client:get_user_info{ payload = 'opaque data', user = 'john' }
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

local client = Spore.new_from_string([[
{
    "base_url" : "http://services.org:9999/restapi/",
    "methods" : {
        "action" : {
            "path" : "/doit/:prm1",
            "method" : "POST",
            "required_params" : [
                "prm1",
                "prm2"
            ],
            "optional_params" : [
                "prm3",
                "prm4"
            ],
            "payload" : [
                "prm2",
                "prm3"
            ],
        }
    }
}
]])
type_ok( client, 'table', "payload")
local res = client:action{ prm1 = 'action1', prm2 = 2, prm3 = 'val3', prm4 = 'val4' }
local env = res.request.env
is( env.PATH_INFO, '/restapi/doit/action1' )
is( res.request.url, 'http://services.org:9999/restapi/doit/action1?prm4=val4' )
local spore = env.spore
type_ok( spore.payload, 'table', 'payload')
is( spore.payload.prm2, 2 )
is( spore.payload.prm3, 'val3' )

local res = client:action{ prm1 = 'action1', prm2 = 2, payload = 'this OPAQUE payload will be trashed' }
local env = res.request.env
is( res.request.url, 'http://services.org:9999/restapi/doit/action1' )
is( res.request.headers['content-type'], 'application/x-www-form-urlencoded' )
ok( res.request.headers['content-length'] )
local spore = env.spore
type_ok( spore.payload, 'table', 'payload')
is( spore.payload.prm2, 2 )
is( spore.payload.prm3, nil )

local client = Spore.new_from_string([[
{
    "base_url" : "http://services.org:9999/restapi/",
    "methods" : {
        "action" : {
            "path" : "/doit/:prm1",
            "method" : "POST",
            "required_params" : [
                "prm1",
                "prm2"
            ],
            "optional_params" : [
                "prm3",
                "prm4"
            ],
            "form-data" : {
                "form2": "g(:prm2)",
                "form3": "h(:prm3)"
            },
        }
    }
}
]])
type_ok( client, 'table', "form_data")
local res = client:action{ prm1 = 'action1', prm2 = 2, prm3 = 'val3', prm4 = 'val4' }
local env = res.request.env
is( env.PATH_INFO, '/restapi/doit/action1' )
is( res.request.url, 'http://services.org:9999/restapi/doit/action1?prm4=val4' )
like( res.request.headers['content-type'], '^multipart/form%-data; boundary=' )
ok( res.request.headers['content-length'] )
local spore = env.spore
type_ok( spore.form_data, 'table', 'form_data')
is( spore.form_data.form2, 'g(2)' )
is( spore.form_data.form3, 'h(val3)' )
