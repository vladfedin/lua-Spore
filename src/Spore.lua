
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
local unpack = require 'table'.unpack or unpack
local io = require 'io'
local math = require 'math'
local string = require 'string'
local json = require 'json.decode'
local ltn12 = require 'ltn12'
local mime = require 'mime'
local url = require 'socket.url'
local core = require 'Spore.Core'
local tconcat = require 'table'.concat
math.randomseed(os.time())


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

local function boundary (size)
    local t = {}
    for i = 1, 3 * size do
        t[#t+1] = math.random(256) - 1
    end
    local b = mime.b64(string.char(unpack(t))):gsub('%W', 'X')
    return b
end

local function _form_data (data)
    local p = {}
    for k, v in pairs(data) do
        if v:sub(1, 1) == '@' then
            local fname = v:sub(2)
            local content = slurp(fname)
            p[#p+1] = 'content-disposition: form-data; name="' .. k .. '"; filename="' .. fname ..'"\r\n'
                   .. 'content-type: application/octet-stream\r\n\r\n'
                   .. content
        else
            p[#p+1] = 'content-disposition: form-data; name="' .. k .. '"\r\n\r\n' .. v
        end
    end

    local b = boundary(10)
    local t = {}
    for i = 1, #p do
        t[#t+1] = '--'
        t[#t+1] = b
        t[#t+1] = '\r\n'
        t[#t+1] = p[i]
        t[#t+1] = '\r\n'
    end
    t[#t+1] = '--'
    t[#t+1] = b
    t[#t+1] = '--'
    t[#t+1] = '\r\n'
    return tconcat(t), b
end

function request (req)
    local spore = req.env.spore
    local prot = protocol[spore.url_scheme]
    assert(prot, "not protocol " .. spore.url_scheme)

    local form_data = spore.form_data
    if form_data then
        local content, boundary = _form_data(form_data)
        req.source = ltn12.source.string(content)
        req.headers['content-length'] = content:len()
        req.headers['content-type'] = 'multipart/form-data; boundary=' .. boundary
    end

    local payload = spore.payload
    if payload then
        req.source = ltn12.source.string(payload)
        req.headers['content-length'] = payload:len()
        req.headers['content-type'] = 'application/x-www-form-urlencoded'
    end

    local t = {}
    req.sink = ltn12.sink.table(t)

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
    local ex = { response = response, reason = reason }
    local mt = { __tostring = function (self) return self.reason end }
    error(setmetatable(ex, mt))
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
        if type(k) == 'number' then
            params[v] = v
        else
            params[tostring(k)] = v
        end
    end
    local payload = params.spore_payload or params.payload
    params.spore_payload = nil
    params.payload = nil
    if method.required_payload then
        assert(payload, "payload required")
    end
    if payload then
        assert(method.method == 'PUT' or method.method == 'POST', "payload requires a PUT or POST method")
    end

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

    local base_url = url.parse(method.base_url)
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
            authentication  = method.authentication,
            params          = params,
            form_data       = method['form-data'],
            payload         = payload,
            errors          = io.stderr,
            debug           = debug,
            url_scheme      = base_url.scheme,
            format          = method.formats,
        },
        sporex = {},
    }
    return self:http_request(env)
end

local function new ()
    local obj = {
        middlewares = {}
    }
    local mt = {
        __index = core,
    }
    return setmetatable(obj, mt)
end

function new_from_string (...)
    local args = {...}
    local opts = {}
    local nb
    for i = 1, #args do
        local arg = args[i]
        if i > 1 and type(arg) == 'table' then
            opts = arg
            break
        end
        checktype('new_from_string', i, arg, 'string')
        nb = i
    end

    local obj = new()
    local valid_method = {
        DELETE = true, HEAD = true, GET = true, POST = true, PUT = true
    }
    for i = 1, nb do
        local spec = json.decode(args[i])

        assert(spec.methods, "no method in spec")
        for k, v in pairs(spec.methods) do
            v.authentication = opts.authentication or v.authentication or spec.authentication
            v.base_url = opts.base_url or v.base_url or spec.base_url
            v.expected_status = opts.expected_status or v.expected_status or spec.expected_status
            v.formats = opts.formats or v.formats or spec.formats
            assert(obj[k] == nil, k .. " duplicated")
            assert(v.method, k .. " without field method")
            assert(valid_method[v.method], k .. " with invalid method " .. v.method)
            if v.required_payload then
                assert(v.method == 'PUT' or v.method == 'POST', k .. ": payload requires a PUT or POST method")
            end
            if v['form-data'] then
                assert(v.method == 'PUT' or v.method == 'POST', k .. ": form-data requires a PUT or POST method")
            end
            assert(v.path, k .. " without field path")
            assert(type(v.expected_status or {}) == 'table', "expected_status of " .. k .. " is not an array")
            assert(type(v.required_params or {}) == 'table', "required_params of " .. k .. " is not an array")
            assert(type(v.optional_params or {}) == 'table', "optional_params of " .. k .. " is not an array")
            assert(type(v['form-data'] or {}) == 'table', "form-data of " .. k .. " is not an hash")
            assert(v.base_url, k .. ": base_url is missing")
            local uri = url.parse(v.base_url)
            assert(uri.host, k .. ": base_url without host")
            assert(uri.scheme, k .. ": base_url without scheme")
            obj[k] =  function (self, args)
                          return wrap(self, k, v, args)
                      end
        end
    end

    return obj
end

function new_from_spec (...)
    local args = {...}
    local opts = {}
    local t = {}
    for i = 1, #args do
        local arg = args[i]
        if i > 1 and type(arg) == 'table' then
            opts = arg
            break
        end
        checktype('new_from_spec', i, arg, 'string')
        t[#t+1] = slurp(arg)
    end
    t[#t+1] = opts
    return new_from_string(unpack(t))
end

_VERSION = version
_DESCRIPTION = "lua-Spore : a generic ReST client"
_COPYRIGHT = "Copyright (c) 2010 Francois Perrad"
--
-- This library is licensed under the terms of the MIT/X11 license,
-- like Lua itself.
--
