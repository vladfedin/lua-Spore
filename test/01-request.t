#!/usr/bin/env lua

require 'Spore.Request'

require 'Test.More'

plan(34)

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

env.PATH_INFO = '/usr:prm1/show/:prm2'
env.spore.params.prm3 = nil
req:finalize()
is( req.url, 'prot://services.org:9999/restapi/usr1/show/value2', "url" )
is( env.PATH_INFO, '/usr1/show/value2' )
is( env.QUERY_STRING, '' )

env.PATH_INFO = '/path'
env.spore.params.prm3 = "Value Z"
env.spore.form_data = {
    form1 = 'f(:prm1)',
    form2 = 'g(:prm2)',
    form3 = 'h(:prm3)',
    form7 = 'r(:prm7)',
}
req:finalize()
is( req.url, 'prot://services.org:9999/restapi/path', "url" )
is( env.PATH_INFO, '/path' )
is( env.QUERY_STRING, '' )
is( env.spore.form_data.form1, "f(1)", "form-data" )
is( env.spore.form_data.form2, "g(value2)" )
is( env.spore.form_data.form3, "h(Value Z)" )
is( env.spore.form_data.form7, nil )

env.spore.form_data = nil
env.spore.headers = {
    head1 = 'f(:prm1)',
    head2 = 'g(:prm2)',
    head3 = 'h(:prm3)',
    head7 = 'r(:prm7)',
}
req:finalize()
is( req.url, 'prot://services.org:9999/restapi/path', "url" )
is( env.PATH_INFO, '/path' )
is( env.QUERY_STRING, '' )
is( env.spore.form_data, nil )
is( req.headers.head1, "f(1)", "headers" )
is( req.headers.head2, "g(value2)" )
is( req.headers.head3, "h(Value Z)" )
is( req.headers.head7, nil )

