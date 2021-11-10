local pairs = pairs
local checktype = require 'Spore'.checktype
local new_from_lua = require 'Spore'.new_from_lua
local slurp = require 'Spore.Protocols'.slurp
local lyaml = require 'lyaml'

local m = { }

m.spore = '1.0'

local ops = {
    get = true,
    put = true,
    post = true,
    delete = true,
    options = true,
    head = true,
    patch = true,
}

local process_path
process_path = function(spore, path, data)
    path = path:gsub('{(%w+)}', ':%1')

    for key, item in pairs(data) do
        if key:sub(1, 1) == '/' then
            process_path(spore, path .. key, item)
        elseif ops[key] then
            local op = key
            local method = item

            local expected_status = { }
            for status in pairs(method.responses) do
                expected_status[#expected_status + 1] = status
            end

            local required_params = { }
            for param_name in path:gmatch(':(%w+)') do
                required_params[#required_params + 1] = param_name
            end

            spore.methods[path .. (path == '/' and '' or '/') .. op] = {
                method = op:upper(),
                path = path,
                required_params = required_params,
                required_payload = not not method.body,
                expected_status = expected_status,
                description = method.description,
                responses = method.responses,
            }
        end
    end
end

local convert = function(doc, tag)
    local spore = {
        name = doc.title;
        version = doc.version,
        methods = { }
    }

    local description = ''
    if doc.documentation then
        for i, doc_item in ipairs(doc.documentation) do
            description = description
              .. (i > 1 and '\n' or '')
              .. doc_item.title .. '\n'
              .. doc_item.content
        end
    end
    spore.description = description

    for path, data in pairs(doc) do
        if path:sub(1, 1) == '/' then
            process_path(spore, path, data)
        end
    end

    return spore
end
m.convert = convert

function m.new_from_raml (api, opts, tag)
    opts = opts or {}
    checktype('new_from_open_api', 1, api, 'string')
    checktype('new_from_open_api', 2, opts, 'table')
    checktype('new_from_open_api', 3, tag or '', 'string')
    local content = slurp(api)

    content = lyaml.load(content)

    local converted_content = convert(content, tag)
    return new_from_lua(converted_content, opts), converted_content, content
end

return m
