#!/usr/bin/env lua

require 'Test.More'

if not pcall(require, 'lxp.lom') then
    skip_all 'no xml'
end

plan(4)

local m = require 'Spore.WADL'
type_ok( m, 'table', "Spore.WADL" )
is( m, package.loaded['Spore.WADL'] )

type_ok( m.new_from_wadl, 'function' )
type_ok( m.convert, 'function' )

