#!/usr/bin/env lua

require 'Test.More'

plan(17)

if not require_ok 'Spore' then
    BAIL_OUT "no lib"
end

local m = require 'Spore'
type_ok( m, 'table', "Spore" )
is( m, Spore )
is( m, package.loaded['Spore'] )

like( m._COPYRIGHT, 'Perrad', "_COPYRIGHT" )
like( m._DESCRIPTION, 'ReST client', "_DESCRIPTION" )
type_ok( m._VERSION, 'string', "_VERSION" )
like( m._VERSION, '^%d%.%d%.%d$' )

m = require 'Spore.Core'
type_ok( m, 'table', "Spore.Core" )
is( m, Spore.Core )
is( m, package.loaded['Spore.Core'] )

m = require 'Spore.Protocols'
type_ok( m, 'table', "Spore.Protocols" )
is( m, Spore.Protocols )
is( m, package.loaded['Spore.Protocols'] )

m = require 'Spore.Request'
type_ok( m, 'table', "Spore.Request" )
is( m, Spore.Request )
is( m, package.loaded['Spore.Request'] )

