#!/usr/bin/env lua

require 'Test.More'

if not pcall(require, 'crypto') then
    skip_all 'no crypto'
end

plan(7)

require 'Spore.Protocols'.request = function (req)
    return { request = req, status = 200, headers = {} }
end -- mock

if not require_ok 'Spore.Middleware.Auth.DataPublica' then
    skip_rest "no Spore.Middleware.Auth.DataPublica"
    os.exit()
end
local mw = require 'Spore.Middleware.Auth.DataPublica'

local req = require 'Spore.Request'.new({
    SERVER_NAME = 'services.org',
    PATH_INFO = '/path',
    spore = {
        caller = 'fake',
        url_scheme = 'http',
        method = {
            unattended_params = true,
        },
        params = {},
    }
})
type_ok( req, 'table', "Spore.Request.new" )
type_ok( req.headers, 'table' )

local r = mw.call({}, req)
is( r, nil )

local data = {
    key      = '356a192c7813b04c54574d18c28d46e6395428ab',
    password = '30d87add92e7b27ce4',
}
r = mw.call(data, req)
is( r, nil )

req.env.spore.authentication = true
r = mw.call(data, req)
is( r.status, 200 )
is( r.request.url, "http://services.org/path?offset=0&format=json&limit=50&key=356a192c7813b04c54574d18c28d46e6395428ab&signature=a358aa918f36156b215531e287f6d836415be582" )

