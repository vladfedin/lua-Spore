--
-- lua-Spore : <http://fperrad.github.com/lua-Spore/>
--
-- see http://search.cpan.org/~grantm/XML-Simple/

local ipairs = ipairs
local pairs = pairs
local tostring = tostring
local type = type
local raises = require 'Spore'.raises
local xml = require 'lxp.lom'

_ENV = nil
local m = {}

local function escape (val, attr)
    local str = tostring(val)
    str = str:gsub('&', '&amp;')
    str = str:gsub('<', '&lt;')
    str = str:gsub('>', '&gt;')
    if attr then
        str = str:gsub('"', '&quot;')
        str = str:gsub("'", '&apos;')
    end
    return str
end

local function element (name, t, options, level)
    local indent = options.indent
    local r = ''
    if indent then
        r = r .. indent:rep(level)
    end
    r = r .. '<' .. name
    local h = {}
    if type(t) == 'table' then
        for i in ipairs(t) do
            h[i] = true
        end
        for k, v in pairs(t) do
            if not h[k] and type(v) ~= 'table' then
                r = r .. ' ' .. k .. '="' .. escape(v, true) .. '"'
            end
        end
    end
    r = r .. '>'
    if type(t) == 'table' then
        local first = true
        for k, v in pairs(t) do
            if type(v) == 'table' then
                if indent and first then
                    r = r .. '\n'
                    first = false
                end
                local n = 0
                for _ in pairs(v) do
                    n = n + 1
                end
                if #v == n then
                    for i = 1, #v do
                        r = r .. element(k, v[i], options, level+1)
                    end
                else
                    local key_attr = options.key_attr or {}
                    local key = key_attr[k]
                    if key then
                        for kk, vv in pairs(v) do
                            if key then
                                vv[key] = kk
                            end
                            r = r .. element(k, vv, options, level+1)
                        end
                    else
                        r = r .. element(k, v, options, level+1)
                    end
                end
            elseif h[k] then
                r = r .. escape(v)
            end
        end
        if indent and not first then
            r = r .. indent:rep(level)
        end
    else
        r = r .. escape(t)
    end
    r = r .. '</' .. name .. '>'
    if indent then
        r = r .. '\n'
    end
    return r
end

local function to_xml (t, options)
    for k, v in pairs(t) do
        return element(k, v, options or {}, 0)
    end
end
m.to_xml = to_xml

local function collapse (doc, options)
    local string_leaf = true
    local t = {}
    for k, v in pairs(doc.attr) do
        if type(k) == 'string' then
            t[k] = v
            string_leaf = false
        end
    end
    for i = 1, #doc do
        local v = doc[i]
        if type(v) == 'string' then
            if not v:match '^%s+' then
                t[#t+1] = v
            end
        else
            local name = v.tag
            t[name] = t[name] or {}
            local tt = t[name]
            local key_attr = options.key_attr or {}
            local key = v.attr[key_attr[name]]
            if key then
                tt[key] = collapse(v, options)
            else
                tt[#tt+1] = collapse(v, options)
            end
            string_leaf = false
        end
    end
    if string_leaf and #t <= 1 then
        return t[1]
    else
        return t
    end
end

function m:call (req)
    local spore = req.env.spore
    if spore.payload and type(spore.payload) == 'table' then
        spore.payload = to_xml(spore.payload, self)
        req.headers['content-type'] = 'text/xml'
    end
    req.headers['accept'] = 'text/xml'
    return  function (res)
                if type(res.body) == 'string' and res.body:match'%S' then
                    local r, msg = xml.parse(res.body)
                    if r then
                        res.body = { [r.tag] = collapse(r, self) }
                    else
                        if spore.errors then
                            spore.errors:write(msg, "\n")
                            spore.errors:write(res.body, "\n")
                        end
                        if res.status == 200 then
                            raises(res, msg)
                        end
                    end
                end
                return res
            end
end

return m
--
-- Copyright (c) 2010-2011 Francois Perrad
--
-- This library is licensed under the terms of the MIT/X11 license,
-- like Lua itself.
--
