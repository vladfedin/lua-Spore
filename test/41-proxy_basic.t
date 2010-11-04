#!/usr/bin/env lua

require 'Spore'

require 'Test.More'

plan(7)

if not require_ok 'Spore.Middleware.Proxy.Basic' then
    skip_rest "no Spore.Middleware.Proxy.Basic"
    os.exit()
end

local response = { status = 200, headers = {}, body = 'dummy' }
Spore.Protocols.request = function (req)
    like(req.url, "^http://proxy.myorg:8080/restapi/show", "proxy")
    local host = req.headers['host']
    is( host, 'services.org', "host" )
    local auth = req.headers['proxy-authorization']
    type_ok( auth, 'string', "proxy-authorization is set" )
    is( auth:sub(1, 6), "Basic ", "starts by 'Basic '" )
    local unenc = require 'mime'.unb64(auth:sub(7))
    is( unenc, "john:s3kr3t", "john:s3kr3t" )
    return response
end -- mock

local client = Spore.new_from_spec './test/api.json'
client:enable('Proxy.Basic', {
    proxy    = 'http://proxy.myorg:8080',
    username = 'john',
    password = 's3kr3t',
})

local r = client:get_info()
is( r.body, 'dummy' )

