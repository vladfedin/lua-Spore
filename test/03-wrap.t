#!/usr/bin/env lua

require 'Spore'

require 'Test.More'

plan(18)

Spore.Core.http_request = function (self, env) return env end -- mock

local client = Spore.new_from_spec('../test/api.json', {})

error_like( function () client:get_info(true) end,
            "bad argument #2 to get_info %(table expected, got boolean%)" )

local res = client:get_info{ 'border'; user = 'john' }
type_ok( res, 'table' )
is( res.REQUEST_METHOD, 'GET' )
is( res.SERVER_NAME, 'services.org' )
is( res.SERVER_PORT, '9999' )
is( res.SCRIPT_NAME, '/restapi/' )
is( res.PATH_INFO, '/show' )
like( res.HTTP_USER_AGENT, '^lua%-Spore' )
type_ok( res.spore, 'table' )
is( res.spore.url_scheme, 'http' )
is( res.spore.params.user, 'john' )
is( res.spore.params.border, 'border' )

error_like( function () client:get_user_info{} end,
            "payload is required for method get_user_info" )

error_like( function () client:get_user_info{ payload = '@file' } end,
            "user is required for method get_user_info" )

local res = client:get_info{ user = 'joe' }
is( res.spore.params.user, 'joe' )

error_like( function () client:get_info{ payload = '@file' } end,
            "payload is not expected for method get_info" )

error_like( function () client:get_info{ mode = 'raw' } end,
            "mode is not expected for method get_info" )

client = Spore.new_from_spec('../test/api.json', { unattended_params = true })
lives_ok( function () client:get_info{ mode = 'raw' } end )
