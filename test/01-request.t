#!/usr/bin/env lua

local Request = require 'Spore.Request'

require 'Test.More'

plan(44)

local env = {
    HTTP_USER_AGENT = 'MyAgent',
    PATH_INFO       = '/restapi',
    REQUEST_METHOD  = 'PET',
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
local req = Request.new(env)
type_ok( req, 'table', "Spore.Request.new" )
is( req.env, env )
is( req.redirect, false )
type_ok( req.headers, 'table' )
is( req.headers['user-agent'], 'MyAgent' )
type_ok( req.finalize, 'function' )
is( req.url, nil )
is( req.method, nil )

env.PATH_INFO = '/restapi/usr:prm1/show/:prm2'
env.QUERY_STRING = nil
req:finalize()
is( req.method, 'PET', "method" )
is( req.url, 'prot://services.org:9999/restapi/usr1/show/value2?prm3=Value%20Z', "url" )
is( env.PATH_INFO, '/restapi/usr1/show/value2' )
is( env.QUERY_STRING, 'prm3=Value%20Z' )

env.PATH_INFO = '/restapi/:prm3/show'
env.QUERY_STRING = nil
env.REQUEST_METHOD = 'TEP'
req:finalize()
is( req.method, 'TEP', "method" )
is( req.url, 'prot://services.org:9999/restapi/Value%20Z/show?prm1=1&prm2=value2', "url" )
is( env.PATH_INFO, '/restapi/Value%20Z/show' )
is( env.QUERY_STRING, 'prm1=1&prm2=value2' )

env.PATH_INFO = '/restapi/usr:prm1/show/:prm2'
env.QUERY_STRING = nil
env.spore.params.prm3 = nil
req:finalize()
is( req.url, 'prot://services.org:9999/restapi/usr1/show/value2', "url" )
is( env.PATH_INFO, '/restapi/usr1/show/value2' )
is( env.QUERY_STRING, nil )

env.PATH_INFO = '/restapi/doit'
env.QUERY_STRING = 'action=action1'
req:finalize()
is( req.url, 'prot://services.org:9999/restapi/doit?action=action1&prm1=1&prm2=value2', "url" )
is( env.PATH_INFO, '/restapi/doit' )
is( env.QUERY_STRING, 'action=action1&prm1=1&prm2=value2' )

env.PATH_INFO = '/restapi/path'
env.QUERY_STRING = nil
env.spore.params.prm3 = "Value Z"
env.spore.form_data = {
    form1 = 'f(:prm1)',
    form2 = 'g(:prm2)',
    form3 = 'h(:prm3)',
    form7 = 'r(:prm7)',
}
req:finalize()
is( req.url, 'prot://services.org:9999/restapi/path', "url" )
is( env.PATH_INFO, '/restapi/path' )
is( env.QUERY_STRING, nil )
is( env.spore.form_data.form1, "f(1)", "form-data" )
is( env.spore.form_data.form2, "g(value2)" )
is( env.spore.form_data.form3, "h(Value Z)" )
is( env.spore.form_data.form7, nil )

env.QUERY_STRING = nil
env.spore.form_data = nil
env.spore.headers = {
    head1 = 'f(:prm1)',
    head2 = 'g(:prm2); :prm1',
    head3 = 'h(:prm3)',
    head7 = 'r(:prm7)',
}
req:finalize()
is( req.url, 'prot://services.org:9999/restapi/path', "url" )
is( env.PATH_INFO, '/restapi/path' )
is( env.QUERY_STRING, nil )
is( env.spore.form_data, nil )
is( req.headers.head1, "f(1)", "headers" )
is( req.headers.head2, "g(value2); 1" )
is( req.headers.head3, "h(Value Z)" )
is( req.headers.head7, nil )

env.QUERY_STRING = nil
env.spore.params.prm1 = 2
env.spore.params.prm2 = 'VALUE2'
req:finalize()
is( req.headers.head1, "f(2)", "headers" )
is( req.headers.head2, "g(VALUE2); 2" )
is( req.headers.head3, "h(Value Z)" )

env.SERVER_NAME = ':prm2.cloud.com'
env.PATH_INFO = '/restapi/path:prm1'
env.QUERY_STRING = nil
env.spore.params.prm3 = nil
env.spore.headers = nil
req:finalize()
is( env.SERVER_NAME, 'VALUE2.cloud.com' )
is( env.PATH_INFO, '/restapi/path2' )
is( env.QUERY_STRING, nil )
is( req.url, 'prot://VALUE2.cloud.com:9999/restapi/path2', "url" )
