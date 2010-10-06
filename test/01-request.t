#!/usr/bin/env lua

require 'Spore.Request'

require 'Test.More'

plan(16)

local env = {
    HTTP_USER_AGENT = 'MyAgent',
    PATH_INFO       = '',
    REQUEST_METHOD  = 'PET',
    SCRIPT_NAME     = '/restapi',
    SERVER_NAME     = 'services.org',
    SERVER_PORT     = 9999,
    spore = {
        url_scheme = 'prot',
        params = {
            prm1 = 1,
            prm2 = "value2",
            prm3 = "Value Z",
        },
    },
}
local req = Spore.Request.new(env)
type_ok( req, 'table', "Spore.Request.new" )
is( req.env, env )
is( req.redirect, false )
type_ok( req.headers, 'table' )
is( req.headers['user-agent'], 'MyAgent' )
type_ok( req.finalize, 'function' )
is( req.url, nil )
is( req.method, nil )

env.PATH_INFO = '/usr:prm1/show/:prm2'
req:finalize()
is( req.method, 'PET', "method" )
is( req.url, 'prot://services.org:9999/restapi/usr1/show/value2?prm3=Value%20Z', "url" )
is( env.PATH_INFO, '/usr1/show/value2' )
is( env.QUERY_STRING, 'prm3=Value%20Z' )

env.PATH_INFO = '/:prm3/show'
env.REQUEST_METHOD = 'TEP'
req:finalize()
is( req.method, 'TEP', "method" )
is( req.url, 'prot://services.org:9999/restapi/Value%20Z/show?prm1=1&prm2=value2', "url" )
is( env.PATH_INFO, '/Value%20Z/show' )
is( env.QUERY_STRING, 'prm1=1&prm2=value2' )

