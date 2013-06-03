
-- run this with 
-- torch-lua random_threads.lua

local llthreads = require "llthreads"

local thread_code = [[
    -- print thread's parameter.
    print("CHILD: received params:", ...)

    --require 'torch-env'
    require 'torch'
    torch.manualSeed(1)
    local mean = torch.randn(1000000):add(100):mean()
    return mean
]]

function thread_func(...)
    -- print thread's parameter.
    print("CHILD: received params:", ...)

    -- this somehow breaks things, is it pipe or torch.PipeFile?
    -- not really, it seems fine for linux, the problem is only the 
    -- gnuplot package, without it, everything seems fine.
    --require 'torch-env'
    require 'torch'
    require 'nn'
    torch.manualSeed(1)
    local mean = torch.randn(1000000):add(100):mean()
    local m
    for i=1,1000 do
       local x= torch.rand(1000)
       local go = torch.rand(10)
       m = nn.Sequential():add(nn.Linear(1000,100)):add(nn.Tanh()):add(nn.Linear(100,10))
       m:forward(x)
       m:backward(x,go)
       collectgarbage()
    end
    return {mean,m.gradInput:abs():sum()}
end

require 'torch'
require 'nn'
torch.manualSeed(1)
local expectedMean = torch.randn(1000000):add(100):mean()
local m
for i=1,1000 do
   local x= torch.rand(1000)
   local go = torch.rand(10)
   m = nn.Sequential():add(nn.Linear(1000,100)):add(nn.Tanh()):add(nn.Linear(100,10))
   m:forward(x)
   m:backward(x,go)
end
local expectedGradInputSum = m.gradInput:abs():sum()

local nChildren = 10
local children = {}
for i = 1, nChildren do
   local child = llthreads.new(string.dump(thread_func), "number:", 1234, "nil:", nil, "bool:", true)
   assert(child:start())
   children[i] = child
end

local results = {}
for i, child in ipairs(children) do
    local result = {child:join()}
    results[i] = result
    print("PARENT: child returned: ", result[1],unpack(result[2]))
end

for i, result in ipairs(results) do
   assert(results[i][1] == true, "expecting success")
   assert(results[i][2][1] == expectedMean,
	  string.format("wrong result: %s ~= %s", results[i][2][1], expectedMean))
   assert(results[i][2][2] == expectedGradInputSum,
	  string.format("wrong result: %s ~= %s", results[i][2][2], expectedGradInputSum))
end

