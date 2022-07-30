local rust_regex = require("spectre.regex.rust")
local vim_regex = require("spectre.regex.vim")

local bench = require('plenary.profile').benchmark
local num = 10000
local result_replace = "testtest testtest test"
local time = bench(num, function()
    vim_regex.replace_all([[\w*]], "test", "data visual daaa")
end)

print("vim  replace :" .. time)
time = bench(num, function()
    vim_regex.replace_all([[\w*]], "test", "data visual daaa")
end)

print("rust replace :" .. time)
