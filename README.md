# lquery.lua

# example
```lua
require "lquery"
require "base" -- this is optional for table pretty print

-- table for test
local root = {tag='a',
        {tag='c', 1,2,3},
        {tag='a',b='xxx',
                {tag='c',id='qq',age=33, class='a b c'},
                {tag='c',id='qq123',age=34, class='a b'},
        },
}

local lqroot = lquery.new(root)
assert( lqroot:get(1) == root , 'it must be equal')

--[[
        '='     :       equal
        '^='    :       startwith
        '$='    :       endWith
        '~='    :       contains



        '/a/c'          ===> '/[tag="a"]/[tag="c"]'
        'c'             ===> '*[tag="c"]'
        '#xxx'          ===> '*[id="xxx"]'
        '.xxx'          ===> '*[class~="xxx"]'

]]


local fr = lqroot:find('c')

for t in fr:each() do
        print('t1',t)
end

print( fr:get(3))  --  {age=34,name=qq123,tag=c}

fr = lqroot:find('/a/c')

for t in fr:each() do
        print('t2',t)
end

fr = lqroot:find('/[tag="a"]/[tag="c"]')

for t in fr:each() do
        print('t3',t)
end

fr = lqroot:find('/a/a c')

for t in fr:each() do
        print('t4',t)
end

fr = lqroot:find('#qq')

for t in fr:each() do
        print('t5',t)
end

for t in lqroot:find('.b'):each() do
        print('t6',t)
end

fr = lqroot:find('.c')

for t in fr:each() do
        print('t7',t)
end

```
