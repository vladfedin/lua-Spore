
--
-- lua-Spore : <http://fperrad.github.com/lua-Spore>
--

local assert = assert
local error = error
local pairs = pairs
local require = require
local setmetatable = setmetatable
local tonumber = tonumber
local tostring = tostring
local type = type
local unpack = require 'table'.unpack or unpack
local io = require 'io'
local url = require 'socket.url'
local core = require 'Spore.Core'
local slurp = require 'Spore.Protocols'.slurp


_ENV = nil
local m = {}

m.early_validate = true

local version = '0.1.0'

local parse = function(url, default) -- lua-socket url parse function copy
local base = _G
    -- initialize default parameters
    local parsed = {}
    for i,v in base.pairs(default or parsed) do parsed[i] = v end
    -- empty url is parsed to nil
    if not url or url == "" then return nil, "invalid url" end
    -- remove whitespace
    -- url = string.gsub(url, "%s", "")
    -- get fragment
    url = string.gsub(url, "#(.*)$", function(f)
        parsed.fragment = f
        return ""
    end)
    -- get scheme
    url = string.gsub(url, "^([%w][%w%+%-%.]*)%:",
        function(s) parsed.scheme = s; return "" end)
    -- get authority
    url = string.gsub(url, "^//([^/]*)", function(n)
        parsed.authority = n
        return ""
    end)
    -- get query stringing
    url = string.gsub(url, "%?(.*)", function(q)
        parsed.query = q
        return ""
    end)
    -- get params
    url = string.gsub(url, "%;(.*)", function(p)
        parsed.params = p
        return ""
    end)
    -- path is whatever was left
    if url ~= "" then parsed.path = url end
    local authority = parsed.authority
    if not authority then return parsed end
    authority = string.gsub(authority,"^([^@]*)@",
        function(u) parsed.userinfo = u; return "" end)
--    authority = string.gsub(authority, ":([^:]*)$",
--        function(p) parsed.port = p; return "" end)
    if authority ~= "" then parsed.host = authority end
    local userinfo = parsed.userinfo
    if not userinfo then return parsed end
    userinfo = string.gsub(userinfo, ":([^:]*)$",
        function(p) parsed.password = p; return "" end)
    parsed.user = userinfo
    return parsed
end

local function raises (response, reason)
    local ex = { response = response, reason = reason }
    local mt = { __tostring = function (self) return self.reason end }
    error(setmetatable(ex, mt))
end
m.raises = raises

local function checktype (caller, narg, arg, tname)
    assert(type(arg) == tname, "bad argument #" .. tostring(narg) .. " to "
          .. caller .. " (" .. tname .. " expected, got " .. type(arg) .. ")")
end
m.checktype = checktype

local function validate (caller, method, params, payload)
    if method.required_payload then
        assert(payload, "payload is required for method " .. caller)
    end
    if payload then
        assert(method.required_payload or method.optional_payload, "payload is not expected for method " .. caller)
    end

    local required_params = method.required_params or {}
    for i = 1, #required_params do
        local v = required_params[i]
        assert(params[v], v .. " is required for method " .. caller)
    end

    if not method.unattended_params then
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
            assert(found, param .. " is not expected for method " .. caller)
        end
    end
end
m.validate = validate

local function wrap (self, name, method, args)
    args = args or {}
    checktype(name, 2, args, 'table')
    local params = {}
    for k, v in pairs(args) do
        if type(k) == 'number' then
            v = tostring(v)
            params[v] = v
        else
            params[tostring(k)] = v
        end
    end
    local payload = params.spore_payload or params.payload
    params.spore_payload = nil
    params.payload = nil
    if m.early_validate then
        validate(name, method, params, payload)
    end

    local base_url = parse(method.base_url)
    local path_url = parse(method.path)
    local path_info = (base_url.path or '') .. (path_url.path or '')
    path_info = path_info:gsub('//', '/')
    local env = {
        REQUEST_METHOD  = method.method,
        SERVER_NAME     = base_url.host,
        SERVER_PORT     = base_url.port,
        PATH_INFO       = path_info,
        REQUEST_URI     = '',
        QUERY_STRING    = path_url.query,
        HTTP_USER_AGENT = 'lua-Spore v' .. version,
        spore = {
            caller          = name,
            method          = method,
            expected        = method.expected_status,
            authentication  = method.authentication,
            params          = params,
            form_data       = method['form-data'],
            headers         = method.headers,
            payload         = payload,
            errors          = m.errors or io.stderr,
            debug           = m.debug,
            url_scheme      = base_url.scheme,
            format          = method.formats,
        },
        sporex = {},
    }
    if method.deprecated and debug then
        debug:write(name, " is deprecated\n")
    end
    local response = self:http_request(env)

    local expected_status = method.expected_status
    if expected_status then
        local status = response.status
        local found = false
        for i = 1, #expected_status do
            if status == tonumber(expected_status[i]) then
                found = true
                break
            end
        end
        if not found then
            local spore = env.spore
            if spore.errors then
                local req = response.request
                spore.errors:write(req.method, " ", req.url, "\n")
                spore.errors:write(status, "\n")
            end
            raises(response, status .. ' not expected')
        end
    end
    return response
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

local function populate (obj, spec, opts)
    assert(spec.methods, "no method in spec")
    for k, v in pairs(spec.methods) do
        local methname_modifier = m.methname_modifier
        if type(methname_modifier) == 'function' then
            k = methname_modifier(k)
        end
        v.authentication = opts.authentication or v.authentication or spec.authentication
        v.base_url = opts.base_url or v.base_url or spec.base_url
        v.expected_status = opts.expected_status or v.expected_status or spec.expected_status
        v.formats = opts.formats or v.formats or spec.formats
        v.unattended_params = opts.unattended_params or v.unattended_params or spec.unattended_params
        assert(obj[k] == nil, k .. " duplicated")
        assert(v.method, k .. " without field method")
        assert(v.path, k .. " without field path")
        assert(type(v.expected_status or {}) == 'table', "expected_status of " .. k .. " is not an array")
        assert(type(v.required_params or {}) == 'table', "required_params of " .. k .. " is not an array")
        assert(type(v.optional_params or {}) == 'table', "optional_params of " .. k .. " is not an array")
        assert(type(v['form-data'] or {}) == 'table', "form-data of " .. k .. " is not an hash")
        assert(type(v.headers or {}) == 'table', "headers of " .. k .. " is not an hash")
        assert(v.base_url, k .. ": base_url is missing")
        local uri = parse(v.base_url)
        assert(uri.host, k .. ": base_url without host")
        assert(uri.scheme, k .. ": base_url without scheme")
        if v.required_payload or v.optional_payload then
            assert(not v['form-data'], "payload and form-data are exclusive")
        end
        obj[k] =  function (self, args)
                      return wrap(self, k, v, args)
                  end
    end
end

local function new_from_lua (spec)
    checktype('new_from_lua', 1, spec, 'table')
    local obj = new()
    populate(obj, spec, {})
    return obj
end
m.new_from_lua = new_from_lua

local function new_from_string (...)
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
    local json = require 'json.decode'
    for i = 1, nb do
        local spec = json.decode(args[i])
        populate(obj, spec, opts)
    end
    return obj
end
m.new_from_string = new_from_string

local function new_from_spec (...)
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
m.new_from_spec = new_from_spec

m._VERSION = version
m._DESCRIPTION = "lua-Spore : a generic ReST client"
m._COPYRIGHT = "Copyright (c) 2010 Francois Perrad"
return m
--
-- This library is licensed under the terms of the MIT/X11 license,
-- like Lua itself.
--
