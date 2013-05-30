
-- run this with 
-- torch-lua random_threads.lua

local llthreads = require "llthreads"

local thread_code = [[
    -- print thread's parameter.
    print("CHILD: received params:", ...)

    require 'torch-env'
    require 'torch'
    torch.manualSeed(1)
    local mean = torch.randn(1000000):add(100):mean()
    return mean
]]

require 'torch'

torch.manualSeed(1)
local expectedMean = torch.randn(1000000):add(100):mean()

local nChildren = 10
local children = {}
for i = 1, nChildren do
    local child = llthreads.new(thread_code, "number:", 1234, "nil:", nil, "bool:", true)
    assert(child:start())
    children[i] = child
end

local results = {}
for i, child in ipairs(children) do
    local result = {child:join()}
    results[i] = result
    print("PARENT: child returned: ", unpack(result))
end

for i, result in ipairs(results) do
    assert(results[i][1] == true, "expecting success")
    assert(results[i][2] == expectedMean,
        string.format("wrong result: %s ~= %s", results[i][2], expectedMean))
end

