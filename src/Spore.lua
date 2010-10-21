
--
-- lua-Spore : <http://fperrad.github.com/lua-Spore>
--

local assert = assert
local error = error
local pairs = pairs
local pcall = pcall
local require = require
local setmetatable = setmetatable
local tostring = tostring
local type = type
local io = require 'io'
local json = require 'json.decode'
local ltn12 = require 'ltn12'
local url = require 'socket.url'
local core = require 'Spore.Core'
local tconcat = require 'table'.concat


module 'Spore'

local version = '0.0.1'

strict = true

local r, m = pcall(require, 'ssl.https')
if not r then
    m = nil
end
local protocol = {
    http    = require 'socket.http',
    https   = m,
}

function request (req)
    local spore = req.env.spore
    local t = {}
    req.sink = ltn12.sink.table(t)
    local prot = protocol[spore.url_scheme]
    assert(prot, "not protocol " .. spore.url_scheme)
    if spore.debug then
        spore.debug:write(req.method, " ", req.url, "\n")
    end
    local r, status, headers, line = prot.request(req)
    if spore.debug then
        spore.debug:write(line or status, "\n")
    end
    return {
        status = status,
        headers = headers,
        body = tconcat(t),
    }
end

function raises (response, reason)
    error(setmetatable({ response = response, reason = reason },
        { __tostring = function (self) return self.reason end }))
end

function checktype (caller, narg, arg, tname)
    assert(type(arg) == tname, "bad argument #" .. tostring(narg) .. " to "
          .. caller .. " (" .. tname .. " expected, got " .. type(arg) .. ")")
end

local function wrap (self, name, method, args)
    args = args or {}
    checktype(name, 2, args, 'table')
    local params = {}
    for k, v in pairs(args) do
        v = tostring(v)
        if type(k) == 'number' then
            params[v] = v
        else
            params[tostring(k)] = v
        end
    end
    local payload = params.spore_payload or params.payload
    params.spore_payload = nil
    params.payload = nil
    local required_params = method.required_params or {}
    for i = 1, #required_params do
        local v = required_params[i]
        assert(params[v], v .. " is required for method " .. name)
    end

    if strict then
        local optional_params = method.optional_params or {}
        for param in pairs(params) do
            local found = false
            for i = 1, #required_params do
                if param == required_params[i] then
                    found = true
                    break
                end
            end
            if not found then
                for i = 1, #optional_params do
                    if param == optional_params[i] then
                        found = true
                        break
                    end
                end
            end
            assert(found, param .. " is not expected for method " .. name)
        end
    end

    local authentication = method.authentication or self.authentication
    local format = method.formats or self.formats
    local base_url = url.parse(method.base_url or self.base_url)
    local script = base_url.path
    if script == '/' then
        script = nil
    end

    local env = {
        REQUEST_METHOD  = method.method,
        SERVER_NAME     = base_url.host,
        SERVER_PORT     = base_url.port,
        SCRIPT_NAME     = script,
        PATH_INFO       = method.path,
        REQUEST_URI     = '',
        QUERY_STRING    = '',
        HTTP_USER_AGENT = 'lua-Spore v' .. version,
        spore = {
            expected        = method.expected_status,
            authentication  = authentication,
            params          = params,
            payload         = payload,
            errors          = io.stderr,
            debug           = debug,
            url_scheme      = base_url.scheme,
            format          = format,
        },
        sporex = {},
    }
    return self:http_request(env)
end

local function new (args)
    local obj = {
        middlewares = {}
    }
    for k, v in pairs(args) do
        obj[k] = v
    end
    return setmetatable(obj, {
        __index = core,
    })
end

function new_from_string (str, args)
    checktype('new_from_string', 1, str, 'string')
    args = args or {}
    checktype('new_from_string', 2, args, 'table')
    local spec = json.decode(str)

    args.base_url = args.base_url or spec.base_url
    assert(args.base_url, "base_url is missing!")
    local uri = url.parse(args.base_url)
    assert(uri.host, "base_url without host")
    assert(uri.scheme, "base_url without scheme")
    if spec.formats then
        args.formats = spec.formats
    end
    if spec.authentication then
        args.authentication = spec.authentication
    end

    local obj = new(args)
    local valid = {
        DELETE = true, HEAD = true, GET = true, POST = true, PUT = true
    }
    assert(spec.methods, "no method in spec")
    for k, v in pairs(spec.methods) do
        assert(v.method, k .. " without field method")
        assert(valid[v.method], k .. " with invalid method " .. v.method)
        assert(v.path, k .. " without field path")
        assert(type(v.expected_status or {}) == 'table', "expected_status of " .. k .. " is not an array")
        assert(type(v.required_params or {}) == 'table', "required_params of " .. k .. " is not an array")
        assert(type(v.optional_params or {}) == 'table', "optional_params of " .. k .. " is not an array")
        obj[k] =  function (self, args)
                      return wrap(self, k, v, args)
                  end
    end
    return obj
end

local function slurp (name)
    local uri = url.parse(name)
    if not uri.scheme or uri.scheme == 'file' then
        local f, msg = io.open(uri.path)
        assert(f, msg)
        local content = f:read '*a'
        f:close()
        return content
    else
        local res = request{
            env = {
                spore = {
                    url_scheme = uri.scheme,
                    debug = debug,
                },
            },
            method = 'GET',
            url = name,
        }
        assert(res.status == 200, res.status .. " not expected")
        return res.body
    end
end

function new_from_spec (name, args)
    checktype('new_from_spec', 1, name, 'string')
    args = args or {}
    checktype('new_from_spec', 2, args, 'table')
    return new_from_string(slurp(name), args)
end

_VERSION = version
_DESCRIPTION = "lua-Spore : a generic ReST client"
_COPYRIGHT = "Copyright (c) 2010 Francois Perrad"
--
-- This library is licensed under the terms of the MIT/X11 license,
-- like Lua itself.
--
