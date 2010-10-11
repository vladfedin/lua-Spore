#!/usr/bin/env lua

require 'Spore'

require 'Test.More'

plan(16)

error_like( [[Spore.new_from_string(true)]],
            "bad argument #1 to new_from_string %(string expected, got boolean%)" )

error_like( [[Spore.new_from_string('', true)]],
            "bad argument #2 to new_from_string %(table expected, got boolean%)" )

error_like( [[Spore.new_from_string('{ BAD }')]],
            "Invalid JSON data" )

error_like( [[Spore.new_from_string('{ }')]],
            "api_base_url is missing" )

error_like( [[Spore.new_from_string('{ }', { api_base_url = 'services.org' })]],
            "api_base_url without host" )

error_like( [[Spore.new_from_string('{ }', { api_base_url = '//services.org/restapi/' })]],
            "api_base_url without scheme" )

error_like( [[Spore.new_from_string('{ }', { api_base_url = 'http://services.org/restapi/' })]],
            "no method in spec" )

error_like( [=[Spore.new_from_string([[
{
    api_base_url : "http://services.org/restapi/",
    methods : {
        get_info : {
            path : "/show",
        }
    }
}
]])]=],
            "get_info without field method" )

error_like( [=[Spore.new_from_string([[
{
    api_base_url : "http://services.org/restapi/",
    methods : {
        get_info : {
            path : "/show",
            method : "PET",
        }
    }
}
]])]=],
            "get_info with invalid method PET" )

error_like( [=[Spore.new_from_string([[
{
    api_base_url : "http://services.org/restapi/",
    methods : {
        get_info : {
            method : "GET",
        }
    }
}
]])]=],
            "get_info without field path" )

error_like( [=[Spore.new_from_string([[
{
    api_base_url : "http://services.org/restapi/",
    methods : {
        get_info : {
            path : "/show",
            method : "GET",
            required : true,
        }
    }
}
]])]=],
            "required of get_info is not an array" )

error_like( [=[Spore.new_from_string([[
{
    api_base_url : "http://services.org/restapi/",
    methods : {
        get_info : {
            path : "/show",
            method : "GET",
            params : true,
        }
    }
}
]])]=],
            "params of get_info is not an array" )

local client = Spore.new_from_string([[
{
    api_base_url : "http://services.org/restapi/",
    methods : {
        get_info : {
            path : "/show",
            method : "GET",
        }
    }
}
]])
type_ok( client, 'table' )
type_ok( client.enable, 'function' )
type_ok( client.reset_middlewares, 'function' )
type_ok( client.get_info, 'function' )

