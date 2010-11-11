#!/usr/bin/env lua

require 'Test.More'

plan(6)

if not require_ok 'Spore.Middleware.SetParameters' then
    skip_rest "no Spore.Middleware.SetParameters"
    os.exit()
end
local mw = require 'Spore.Middleware.SetParameters'

is( require 'Spore'.early_validate, false, "early_validate" )

local req = require 'Spore.Request'.new({ spore = { params = { prm1 = 0 } }})
type_ok( req, 'table', "Spore.Request.new" )
is( req.env.spore.params.prm1, 0 )

local r = mw.call( {
    prm1 = 1,
    prm2 = 2,
}, req )
is( req.env.spore.params.prm1, 1 )
is( req.env.spore.params.prm2, 2 )

