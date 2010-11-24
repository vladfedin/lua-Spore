#!/usr/bin/env lua

require 'Test.More'

plan(9)

if not require_ok 'Spore.Middleware.Parameter.Default' then
    skip_rest "no Spore.Middleware.Parameter.Default"
    os.exit()
end

local status = 200
require 'Spore.Protocols'.request = function (req) return { request = req, status = status } end -- mock

local Spore = require 'Spore'
local client = Spore.new_from_spec('./test/api.json', {})
client:enable('Parameter.Default', {
    user = 'John',
    border = 0,
    dummy = 1,
})

is( Spore.early_validate, false, "early_validate" )

local r = client:get_info()
is( r.request.env.spore.params.user, 'John' )
is( r.request.env.spore.params.border, 0 )
is( r.request.env.spore.params.dummy, nil )

local r = client:get_info{ user = 'Joe', border = 1 }
is( r.request.env.spore.params.user, 'Joe' )
is( r.request.env.spore.params.border, 1 )

local r = client:get_user_info{ payload = '@file' }
is( r.request.env.spore.params.user, 'John' )
is( r.request.env.spore.params.border, 0 )

