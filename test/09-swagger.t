#!/usr/bin/env lua

require 'Test.More'
local decode = require 'json'.decode

plan(11)

local m = require 'Spore.Swagger'
type_ok( m, 'table', "Spore.Swagger" )
is( m, package.loaded['Spore.Swagger'] )

type_ok( m.new_from_swagger, 'function' )
type_ok( m.convert, 'function' )

local doc = decode [[
{
  "swagger": "2.0",
  "info": {
    "title": "api",
    "version": "v1",
    "description": "api for unit test"
  },
  "schemes": ["http"],
  "host": "services.org:9999",
  "basePath": "/restapi",
  "paths": {
    "/show": {
      "get": {
        "operationId": "get_info",
        "summary": "blah",
        "description": "blah, blah",
        "parameters": [
          {
            "name": "user",
            "in": "query",
            "required": true
          },
          {
            "name": "border",
            "in": "query",
            "required": false
          }
        ],
        "responses": {
          "200": {
            "description": "Ok."
          }
        }
      }
    }
  }
}
]]

local spec = m.convert(doc)
is( spec.name, 'api' )
is( spec.version, 'v1' )
is( spec.description, 'api for unit test' )
is( spec.base_url, 'http://services.org:9999/restapi' )
local meth = spec.methods.get_info
type_ok( meth, 'table' )
is( meth.path, '/show' )
is( meth.method, 'GET' )
