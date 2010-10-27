--
-- lua-Spore : <http://fperrad.github.com/lua-Spore/>
--

local pcall = pcall
local require = require
local type = type
local raises = require 'Spore'.raises


module 'Spore.Middleware.Format.JSON'

function call (self, req)
    local spore = req.env.spore
    if spore.payload and type(spore.payload) == 'table' then
        local encode = require 'json.encode'.encode
        spore.payload = encode(spore.payload)
        req.headers['content-type'] = 'application/json'
    end
    req.headers['accept'] = 'application/json'
    return  function (res)
                if res.body then
                    local r, msg = pcall(function ()
                        local decode = require 'json.decode'.decode
                        res.body = decode(res.body)
                    end)
                    if not r then
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
