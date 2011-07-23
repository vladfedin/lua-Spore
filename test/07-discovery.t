#!/usr/bin/env lua

require 'Test.More'

plan(4)

local m = require 'Spore.GoogleDiscovery'
type_ok( m, 'table', "Spore.GoogleDiscovery" )
is( m, package.loaded['Spore.GoogleDiscovery'] )

type_ok( m.new_from_discovery, 'function' )
type_ok( m.convert, 'function' )

