local utils = require("spectre.utils")
local eq = assert.are.same

local fixtures_different = {
    {
        name = "case 1 ",
        search_query = "data",
        replace_query = "no\\0",
        search_text = " data1 data_2 data 3",
        replace_text = " datanodata1 datanodata_2 datanodata 3",
        result = { search = { { 1, 5 }, { 13, 17 }, { 26, 30 } }, replace = { { 5, 11 }, { 17, 23 }, { 30, 36 } } }
    },
    {
        name = "case 2 ",
        search_query = "d\\S*a",
        replace_query = "no\\0",
        search_text = " data1 data_2 data 3",
        replace_text = " datanodata1 datanodata_2 datanodata 3",
        result = { search = { { 1, 5 }, { 13, 17 }, { 26, 30 } }, replace = { { 5, 11 }, { 17, 23 }, { 30, 36 } } }
    },
    {
        name = "case 3 ",
        search_query = "data(.*)",
        replace_query = "no",
        search_text = " data1 data_2 data 3",
        replace_text = " data1 data_2 data 3no",
        result = { search = { { 1, 20 } }, replace = { { 20, 22 } } }
    },
    {
        name = "case 4 ",
        search_query = [[data\(]],
        replace_query = "no",
        search_text = " data( data_2 data 3",
        replace_text = " data(no data_2 data 3",
        result = { search = { { 1, 6 } }, replace = { { 6, 8 } } }
    },
    {
        name = "case 5 ",
        search_query = [[abcd\(]],
        replace_query = "no",
        search_text = "    test  function abcd(no)",
        replace_text = "    test  function abcd(nono)",
        result = { search = { { 19, 24 } }, replace = { { 24, 26 } } }
    },

    {
        name = "case 6 ",
        search_query = [[^local]],
        replace_query = "public",
        search_text = "local data",
        replace_text = "localpublic data",
        result = { search = { { 0, 5 } }, replace = { { 5, 11 } } }
    },
    {
        name = "case 7 ",
        search_query = [[<app[^/]*>]],
        replace_query = "public",
        search_text = "<app-root></app-root>",
        replace_text = "<app-root>public</app-root>",
        result = { search = { { 0, 10 } }, replace = { { 10, 16 } } }
    },
    {
        name = "case 8 ",
        search_query = [[^local]],
        replace_query = "public",
        search_text = "local data",
        show_search = false,
        replace_text = "public data",
        result = { search = {}, replace = { { 0, 6 } } }
    },

}


local rust_fixtures_different = {
    {
        name = "case 1 ",
        search_query = "data",
        replace_query = "no${0}",
        search_text = " data1 data_2 data 3",
        replace_text = " datanodata1 datanodata_2 datanodata 3",
        result = { search = { { 1, 5 }, { 13, 17 }, { 26, 30 } }, replace = { { 5, 11 }, { 17, 23 }, { 30, 36 } } }
    },
    {
        name = "case 2 ",
        search_query = "d\\S*a",
        replace_query = "no$0",
        search_text = " data1 data_2 data 3",
        replace_text = " datanodata1 datanodata_2 datanodata 3",
        result = { search = { { 1, 5 }, { 13, 17 }, { 26, 30 } }, replace = { { 5, 11 }, { 17, 23 }, { 30, 36 } } }
    },
    {
        name = "case 3 ",
        search_query = "data(.*)",
        replace_query = "no",
        search_text = " data1 data_2 data 3",
        replace_text = " data1 data_2 data 3no",
        result = { search = { { 1, 20 } }, replace = { { 20, 22 } } }
    },
    {
        name = "case 4 ",
        search_query = [[data\(]],
        replace_query = "no",
        search_text = " data( data_2 data 3",
        replace_text = " data(no data_2 data 3",
        result = { search = { { 1, 6 } }, replace = { { 6, 8 } } }
    },
    {
        name = "case 5 ",
        search_query = [[abcd\(]],
        replace_query = "no",
        search_text = "    test  function abcd(no)",
        replace_text = "    test  function abcd(nono)",
        result = { search = { { 19, 24 } }, replace = { { 24, 26 } } }
    },

    {
        name = "case 6 ",
        search_query = [[^local]],
        replace_query = "public",
        search_text = "local data",
        replace_text = "localpublic data",
        result = { search = { { 0, 5 } }, replace = { { 5, 11 } } }
    },
    {
        name = "case 7 ",
        search_query = [[<app[^/]*>]],
        replace_query = "public",
        search_text = "<app-root></app-root>",
        replace_text = "<app-root>public</app-root>",
        result = { search = { { 0, 10 } }, replace = { { 10, 16 } } }
    },
    {
        name = "case 8 ",
        search_query = [[^local]],
        replace_query = "public",
        search_text = "local data",
        show_search = false,
        replace_text = "public data",
        result = { search = {}, replace = { { 0, 6 } } }
    },

}
describe('utils test different highlight', function()
    local regex = require('spectre.regex.vim')
    for _, value in pairs(fixtures_different) do
        it(value.name .. " " .. value.search_query, function()
            local result = utils.get_hl_line_text(value, regex)
            eq(value.replace_text, result.text, 'text error :' .. value.name)
            eq(value.result.search, result.search, 'search error :' .. value.name)
            eq(value.result.replace, result.replace, 'replace error :' .. value.name)
        end)
    end

    regex = require('spectre.regex.rust')
    regex.change_options({ "i" })
    for _, value in pairs(rust_fixtures_different) do
        it(value.name .. " " .. value.search_query, function()
            local result = utils.get_hl_line_text(value, regex)
            eq(value.replace_text, result.text, 'text error :' .. value.name)
            eq(value.result.search, result.search, 'search error :' .. value.name)
            eq(value.result.replace, result.replace, 'replace error :' .. value.name)
        end)
    end
end)
