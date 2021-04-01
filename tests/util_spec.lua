local utils = require("spectre.utils")
local eq = assert.are.same

local fixtures_different = {
    {
        name = "case 1 ",
        search_text = "data",
        replace_text = "no\\0",
        search_line = " data1 data_2 data 3",
        replace_line = " nodata1 nodata_2 nodata 3",
        result = {input = {{1, 5}, {7, 11}, {14, 18}}, output = {{1, 7}, {9, 15}, {18, 24}}}
    },
    {
        name = "case 2 ",
        search_text = "d\\S*a",
        replace_text = "no\\0",
        search_line = " data1 data_2 data 3",
        replace_line = " nodata1 nodata_2 nodata 3",
        result = {input = {{1, 5}, {7, 11}, {14, 18}}, output = {{1, 7}, {9, 15}, {18, 24}}}
    }, {
        name = "case 3 ",
        search_text = "data(.*)",
        replace_text = "no",
        search_line = " data1 data_2 data 3",
        replace_line = " no",
        result = {input = {{1, 20}}, output = {{1, 3}}}
    }, {
        name = "case 4 ",
        search_text = [[data\(]],
        replace_text = "no",
        search_line = " data( data_2 data 3",
        replace_line = " no data_2 data 3",
        result = {input = {{1, 6}}, output = {{1, 3}}}
    },
    {
        name = "case 5 ",
        search_text = [[abcd\(]],
        replace_text = "no",
        search_line = "    test  function abcd()",
        replace_line = "    test  function no)",
        result = {input = {{19, 24}}, output = {{19, 21}}}
    },
    {
        name = "case 6 ",
        search_text = [[^local]],
        replace_text = "public",
        search_line = "local data",
        padding=5,
        replace_line = "public data",
        result = {input = {{5, 10}}, output = {{5, 11}}}
    },
    {
        name = "case 6 ",
        search_text = [[<app[^/]*>]],
        replace_text = "public",
        search_line = "<app-root></app-root>",
        padding = 0,
        replace_line = "public</app-root>",
        result = {input = {{0, 10}}, output = {{0, 6}}}
    }
}

describe('utils test different highlight', function()
    for _, value in pairs(fixtures_different) do
        it(value.name .. " " .. value.search_text, function()
            eq(value.replace_line, utils.vim_replace_text(
                value.search_text,
                value.replace_text,
                value.search_line
            ), 'replace_text not match ' .. value.replace_line)
            local result = utils.different_text_col(value)
            eq(value.result.input, result.input, 'input error :' .. value.name)
            eq(value.result.output, result.output, 'output error :' .. value.name)
        end)
    end
end)
