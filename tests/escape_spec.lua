
local utils = require("spectre.utils")
local eq = assert.are.same

local esc_test_data = {
    {[[ . ]], [[ \. ]], " dot"},
    {[[ \aaaa]], [[ \\aaaa]], " character"},
    {[[ \ ]], [[ \\ ]], " slash"},
    {[[ \\ ]], [[ \\ ]], " don't escape double slash"},
    {[[ \ a. ]], [[ \\ a\. ]], " with dot"},
    {[[ \. \ ]], [[ \\. \\ ]], " with dot slash"},
    {[[ ( \\ ]], [[ \( \\ ]], " square slahs"},
    {[[ \{ ]], [[ \{ ]], " bracket"},
    {[[ \} ]], [[ \} ]], " bracket"},
    {[[ \\\ ]], [[ \\\ ]], " don't escape tripple slash"}
}

describe('escape chars ', function()
    for _, value in pairs(esc_test_data) do
        it("should escape " .. value[3], function()
            eq(value[2], utils.escape_chars(value[1]), "ERROR:" .. value[3])
        end)
    end
end)

local esc_vim_magic = {
    {[[ > ]], [[ \> ]], " >"},
    {[[ = ]], [[ \= ]], " >"},
    {[[ < ]], [[ \< ]], " ="},
    {[[ \< ]], [[ \< ]], " <"},
}

describe('escape vim magic ', function()
    for _, value in pairs(esc_vim_magic) do
        it("should escape " .. value[3], function()
            eq(value[2], utils.escape_vim_magic(value[1]), "ERROR:" .. value[3])
        end)
    end
end)
