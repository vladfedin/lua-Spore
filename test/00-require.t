#!/usr/bin/env lua

require 'Test.More'

plan(8)

if not require_ok 'Spore' then
    BAIL_OUT "no lib"
end

local m = require 'Spore'
type_ok( m, 'table' )
is( m, Spore )
is( m, package.loaded.Spore )

like( m._COPYRIGHT, 'Perrad', "_COPYRIGHT" )
like( m._DESCRIPTION, 'ReST client', "_DESCRIPTION" )
type_ok( m._VERSION, 'string', "_VERSION" )
like( m._VERSION, '^%d%.%d%.%d$' )

