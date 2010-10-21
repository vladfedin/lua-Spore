#!/usr/bin/env lua

require 'Spore'

require 'Test.More'

plan(1)

local response = {}
Spore.request = function (req) return response end -- mock

local client = Spore.new_from_spec '../test/api.json'

local res = client:get_user_info{ user = 'john' }
is( res, response, "without middleware" )
