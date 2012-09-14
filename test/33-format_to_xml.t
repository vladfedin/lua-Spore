#!/usr/bin/env lua

require 'Test.More'
require 'Test.LongString'

if not pcall(require, 'lxp.lom') then
    skip_all 'no xml'
end

plan(24)

if not require_ok 'Spore.Middleware.Format.XML' then
    skip_rest "no Spore.Middleware.Format.XML"
    os.exit()
end
local m = require 'Spore.Middleware.Format.XML'
local options = { indent = '  ' }


is_string( m.to_xml({ root = 42 }, options), [[
<root>42</root>
]] )

is_string( m.to_xml({ root = 'text & <escape>' }, options), [[
<root>text &amp; &lt;escape&gt;</root>
]] )

is_string( m.to_xml({ root = { attr = 42 } }, options), [[
<root attr="42"></root>
]] )

is_string( m.to_xml({ root = { attr = 42, 'va', 'lue' } }, options), [[
<root attr="42">value</root>
]] )

is_string( m.to_xml({ root = { elt = { 'text' } } }, options), [[
<root>
  <elt>text</elt>
</root>
]] )

is_string( m.to_xml({ root = { attr1 = 1, elt = { attr2 = 2, 'text' } } }, options), [[
<root attr1="1">
  <elt attr2="2">text</elt>
</root>
]] )

is_string( m.to_xml({ root = { elt = { 'A', 'b', 'C' } } }, options), [[
<root>
  <elt>A</elt>
  <elt>b</elt>
  <elt>C</elt>
</root>
]] )

is_string( m.to_xml({ root = { attr1 = 1, elt = { 'A', 'b', 'C' } } }, options), [[
<root attr1="1">
  <elt>A</elt>
  <elt>b</elt>
  <elt>C</elt>
</root>
]] )

is_string( m.to_xml({ root = { outer = { inner = { 'text' } } } }, options), [[
<root>
  <outer>
    <inner>text</inner>
  </outer>
</root>
]] )

is_string( m.to_xml({ root = { attr1= 1, outer = { attr2 = 2, inner = { attr3 = 3, 'text' } } } }, options), [[
<root attr1="1">
  <outer attr2="2">
    <inner attr3="3">text</inner>
  </outer>
</root>
]] )

is_string( m.to_xml({ root = { outer = { inner = { 'A', 'b', 'C' } } } }, options), [[
<root>
  <outer>
    <inner>A</inner>
    <inner>b</inner>
    <inner>C</inner>
  </outer>
</root>
]] )

is_string( m.to_xml({ root = { attr1= 1, outer = { attr2 = 2, inner = { 'A', 'b', 'C' } } } }, options), [[
<root attr1="1">
  <outer attr2="2">
    <inner>A</inner>
    <inner>b</inner>
    <inner>C</inner>
  </outer>
</root>
]] )

is_string( m.to_xml({ root = { attr1= 1, outer = { attr2 = 2, inner = { attr3 = 3, 'A', 'b', 'C' } } } }, options), [[
<root attr1="1">
  <outer attr2="2">
    <inner attr3="3">AbC</inner>
  </outer>
</root>
]] )


local options = { indent = '  ', key_attr = { elt = 'id' } }

local res = m.to_xml({
    root = {
        attr1= 1,
        elt = {
            name1 = { 'A' },
            name2 = { 'b' },
            name3 = { 'C' },
        },
    }
}, options)
like_string( res, [[^<root attr1="1">
  <elt ]] )
contains_string( res, [[
  <elt id="name1">A</elt>
]] )
contains_string( res, [[
  <elt id="name3">C</elt>
]] )
contains_string( res, [[
  <elt id="name2">b</elt>
]] )
like_string( res, "</elt>\n</root>\n$" )

local res = m.to_xml({
    root = {
        attr1= 1,
        elt = {
            name1 = {
                inner = { attr = 'A', 'text' },
            },
            name2 = {
                inner = { attr = 'b', 'text' },
            },
            name3 = {
                inner = { attr = 'C', 'text' },
            },
        },
    }
}, options)
like_string( res, [[^<root attr1="1">
  <elt ]] )
contains_string( res, [[
  <elt id="name1">
    <inner attr="A">text</inner>
  </elt>
]] )
contains_string( res, [[
  <elt id="name2">
    <inner attr="b">text</inner>
  </elt>
]] )
contains_string( res, [[
  <elt id="name3">
    <inner attr="C">text</inner>
  </elt>
]] )
like_string( res, "</elt>\n</root>\n$" )
