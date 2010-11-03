--
-- lua-Spore : <http://fperrad.github.com/lua-Spore/>
--

local url = require 'socket.url'
local request = require 'Spore.Protocols'.request


module 'Spore.Middleware.Redirection'

max_redirect = 5

function call (self, req)
    local nredirect = 0

    return  function (res)
                while nredirect < max_redirect do
                    local location = res.headers['location']
                    local status = res.status
                    if location and (status == 301 or status == 302
                                  or status == 303 or status == 307) then
                        req.headers['host'] = nil
                        req.headers['cookie'] = nil
                        req.url = url.absolute(req.url, location)
                        req.env.spore.url_scheme = url.parse(location).scheme
                        res = request(req)
                        nredirect = nredirect + 1
                    else
                        break
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
