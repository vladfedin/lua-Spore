#!/usr/bin/env lua

require 'Test.More'

plan(2)

if not require_ok 'Spore.Middleware.DefaultParameters' then
    skip_rest "no Spore.Middleware.DefaultParameters"
    os.exit()
end
local mw = require 'Spore.Middleware.DefaultParameters'

is( require 'Spore'.early_validate, false, "early_validate" )

