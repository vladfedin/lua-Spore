#!/usr/bin/env lua

require 'Spore'

require 'Test.More'

plan(10)

local client = Spore.new_from_spec '../test/api.json'
is( #client.middlewares, 0 )

error_like( function () client:enable(true) end,
            "bad argument #2 to enable %(string expected, got boolean%)" )

error_like( function () client:enable('MyMiddleware', true) end,
            "bad argument #3 to enable %(table expected, got boolean%)" )

error_like( function () client:enable 'Spore.Middleware.Unknown' end,
            "module 'Spore%.Middleware%.Unknown' not found" )

error_like( function () client:enable 'Unknown' end,
            "module 'Spore%.Middleware%.Unknown' not found" )

package.loaded['Spore.Middleware.Dummy'] = { call = true }

error_like( function () client:enable 'Dummy' end,
            "Spore%.Middleware%.Dummy without a function call" )

package.loaded['Spore.Middleware.Dummy'] = { call = function () end }

client:enable 'Dummy'
is( #client.middlewares, 1 )
type_ok( client.middlewares[1], 'function' )

client:enable 'Dummy'
is( #client.middlewares, 2 )

client:reset_middlewares()
is( #client.middlewares, 0 )

