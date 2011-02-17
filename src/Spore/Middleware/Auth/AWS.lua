--
-- lua-Spore : <http://fperrad.github.com/lua-Spore/>
--
require 'lua-nucleo.module'

local tpretty = import 'lua-nucleo/tpretty.lua' { 'tpretty' }

local mime = require 'mime'
local crypto = require 'crypto'.hmac
local url = require 'socket.url'

_ENV = nil
local m = {}

local escape_string = function(str)
    local outputStr = ""
    for i = 1, (str:len()) do
     -- outputStr = outputStr .. (" %02x"):format(str:byte(i))
        outputStr = outputStr .. string.char(str:byte(i))
    end
    return outputStr
end

local function slurp (name) -- this function is exported by Spore/Protocols.lua
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

function m:call (req)
    local bucket_name = ""
    local objectname = "/"

    -- we got input aws_parameters table
    if req.env.spore.params.aws_parameters then
        req.env.spore.aws_parameters = req.env.spore.params.aws_parameters
        req.env.spore.params.aws_parameters = nil

        -- bucket name redefined, set new
        if req.env.spore.aws_parameters.bucket_name then
            bucket_name = req.env.spore.aws_parameters.bucket_name:lower()
        end
        -- put aws-specific headers to generic spore headers table
        if req.env.spore.aws_parameters.headers then
            for i = 1, #req.env.spore.aws_parameters.headers do
              req.headers[req.env.spore.aws_parameters.headers[i][1]:lower()] =
                req.env.spore.aws_parameters.headers[i][2]
            end
        end
    end

    -- put GMT date-time to headers
    if req.env.spore.method.date_header == true then
        local now
        req.headers['Date'] = os.date("%a, %d %b %Y %H:%M:%S GMT", os.time(os.date("!*t", now)))
    end

    local get_canonical_headers = function()
        if req.env.spore.aws_parameters and req.env.spore.aws_parameters.headers then
            -- get aws-specific headers defined in request
            local headers_table = req.env.spore.aws_parameters.headers

            -- if we got few aws-specific headers
            if #headers_table > 1 then
                -- sort headers alphabetically
                table.sort(headers_table, function(a, b) return a[1]:lower() < b[1]:lower() end)
                local prev_header_name = ""
                local string_concat = ""

                -- if we got any x-amz headers - add them to authentication string
                for i = 1, #headers_table do
                    local header_name = headers_table[i][1]:lower()
                    if header_name:match('^x%-amz') then
                        if i == 1 then
                            string_concat = string_concat .. headers_table[i][1]:lower() .. ":" .. headers_table[i][2]
                        elseif headers_table[i][1] ~= prev_header_name then
                            string_concat = string_concat ..
                              "\n" .. headers_table[i][1]:lower() ..
                              ":" .. headers_table[i][2]
                        -- if we got several headers with same name - group em up
                        else
                            string_concat = string_concat .. "," .. headers_table[i][2]
                        end
                        prev_header_name = headers_table[i][1]
                    end
                end
                if string_concat == "" then return string_concat end
                return string_concat .. "\n"

            -- if we got single aws-specific header
            elseif #headers_table == 1 then
                local header_name = headers_table[1][1]:lower()
                if header_name:match('^x%-amz') then
                    return "" .. headers_table[1][1]:lower() .. ":" .. headers_table[1][2] .. "\n"
                else return "" end

            -- if we got no aws-specific header
            else return "" end
        end
        return ""
    end

    -- check if bucket name defined, otherwise use default
    if req.env.spore.method.bucket_name == true then
        if bucket_name == "" then
            assert(self.bucket_name)
            bucket_name = self.bucket_name:lower()
        end
        assert(bucket_name)
        req.env.bucket_name = bucket_name
        req.env.SERVER_NAME = bucket_name .. "." .. req.env.SERVER_NAME
    end

    -- check if object name defined
    if req.env.spore.params and req.env.spore.params.object_name then
        objectname = objectname .. req.env.spore.params.object_name:lower()
    end

    local get_content_MD5 = function()
        -- if we need to implement MD5 calculation here, see get_content_type
        return req.headers['Content-MD5'] or ""
    end

    local get_content_type = function()
        local payload = req.env.spore.payload
        if payload then
            if payload:sub(1, 1) == '@' then
                local fname = payload:sub(2)
                payload = slurp(fname)
            end
            req.headers['content-length'] = payload:len()
            req.headers['content-type'] = req.headers['content-type'] or 'application/x-www-form-urlencoded'
        end
        return req.headers['content-type'] or ""
    end

--[[
How AWS Signature is made:
(http://docs.amazonwebservices.com/AmazonS3/latest/dev/index.html?RESTAuthentication.html)

Signature = Base64( HMAC-SHA1( UTF-8-Encoding-Of( YourSecretAccessKeyID, string_to_sign ) ) );

string_to_sign = HTTP-Verb + "\n" +
  Content-MD5 + "\n" +
  Content-Type + "\n" +
  Date + "\n" +
  CanonicalizedAmzHeaders +
  CanonicalizedResource;

CanonicalizedResource = [ "/" + Bucket ] +
  <HTTP-Request-URI, from the protocol name up to the query string> +
  [ sub-resource, if present. For example "?acl", "?location", "?logging", or "?torrent"];

CanonicalizedAmzHeaders = sorted x-amz headers
]]

    local get_string_to_sign = function(req, var)
        local bucket = ""
        if bucket_name and bucket_name ~= "" then
            bucket = "/" .. bucket_name
        end
        local question_pos = req.env.spore.method.path
        local string_to_sign = req.env.spore.method.method .. "\n"
            .. get_content_MD5() .. "\n"
            .. get_content_type() .. "\n"
            .. req.headers['Date'] .. "\n"
            .. get_canonical_headers()
            .. bucket .. objectname
        -- works only with one last parameter, subject to careful test and refactoring
        if string.find(req.env.spore.method.path, "%?(.-)$") then
            string_to_sign = string_to_sign
              .. string.sub(req.env.spore.method.path, string.find(req.env.spore.method.path, "%?(.-)$") )
        end
        return string_to_sign
    end

    local count_signature = function(req, var)
        return mime.b64(crypto.digest('sha1', escape_string(get_string_to_sign(req, var)), var, true))
    end

    -- add authentication header
    if req.env.spore.authentication and self.username and self.password then
        req.headers['authorization'] = 'AWS '
          .. self.username .. ":"
          .. count_signature(req, self.password)
    end
end

return m

--
-- Copyright (c) 2010 Francois Perrad
-- Copyright (c) 2011 LogicEditor.com: Alexander Gladysh, Vladimir Fedin
--
-- This library is licensed under the terms of the MIT/X11 license,
-- like Lua itself.
--
