--
-- lua-Spore : <http://fperrad.github.com/lua-Spore/>
--

require 'yaml'
local yaml = yaml


module 'Spore.Middleware.Format.YAML'

function call (self, req)
    local spore = req.env.spore
    if spore.payload then
        spore.payload = yaml.dump(spore.payload)
        req.headers['content-type'] = 'text/x-yaml' 
    end
    req.headers['accept'] = 'text/x-yaml'
    return  function (res)
                if res.body then
                    res.body = yaml.load(res.body)
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
