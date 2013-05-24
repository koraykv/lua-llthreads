
-- run this with 
-- torch-lua random_threads.lua

local llthreads = require "llthreads"

local thread_code = [[
    -- print thread's parameter.
    print("CHILD: received params:", ...)

    require 'torch-env'
    require 'torch'
    local mean = torch.randn(1000):add(100):mean()
    return mean
]]

local nChildren = 10
local children = {}
for i = 1, nChildren do
    local child = llthreads.new(thread_code, "number:", 1234, "nil:", nil, "bool:", true)
    assert(child:start())
    children[i] = child
end

for _, child in ipairs(children) do
    print("PARENT: child returned: ", child:join())
end

