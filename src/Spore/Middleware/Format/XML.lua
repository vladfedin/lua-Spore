--
-- lua-Spore : <http://fperrad.github.com/lua-Spore/>
--

local error = error
local pcall = pcall
local require = require
local type = type
local raises = require 'Spore'.raises
local xml = require 'lxp.lom'

module 'Spore.Middleware.Format.XML'

function call (self, req)
    local spore = req.env.spore
    if spore.payload and type(spore.payload) == 'table' then
        spore.payload = error "TODO"
        req.headers['content-type'] = 'text/xml'
    end
    req.headers['accept'] = 'text/xml'
    return  function (res)
                if res.body then
                    local r, msg = xml.parse(res.body)
                    if r then
                        res.body = r
                    else
                        if spore.errors then
                            spore.errors:write(msg, "\n")
                            spore.errors:write(res.body, "\n")
                        end
                        raises(res, msg)
                    end
                end
                return res
            end
end

--
-- Copyright (c) 2010 Francois Perrad
--
-- This library is licensed under the terms of the MIT/X11 license,
-- like Lua itself.
--
