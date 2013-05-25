#!/usr/bin/env lua

require 'Test.More'

plan(4)

local m = require 'Spore.WADL'
type_ok( m, 'table', "Spore.WADL" )
is( m, package.loaded['Spore.WADL'] )

type_ok( m.new_from_wadl, 'function' )
type_ok( m.convert, 'function' )

