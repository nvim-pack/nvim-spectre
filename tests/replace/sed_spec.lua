local sed = require('spectre.replace').sed
local helpers = require('tests.helper')
local utils = require('spectre.utils')
vim.cmd([[tcd tests/project]])

local eq = assert.are.same
local time_wait = 1000

local get_replacer = function(handler)
    return sed:new({}, handler)
end

local get_replacer_case = function(handler)
    return sed:new({
        options_value = { '--ignore-case' },
    }, handler)
end
describe('[sed] replace ', function()
    it('search result not empty', function()
        local filename = 'sed_spec/sed_test.txt'
        helpers.checkoutfile(filename)
        local finish = false
        local replacer = sed:new({}, {
            on_done = function()
                finish = true
            end,
        })
        replacer:replace({
            lnum = 1,
            filename = filename,
            search_text = 'spectre',
            replace_text = 'zzzz',
        })
        vim.wait(time_wait, function()
            return finish
        end)
        local output_txt = utils.run_os_cmd({ 'cat', filename })
        eq(output_txt[1], 'test data zzzz ok ()')
        eq(true, finish, 'should call finish')
    end)

    it("call error if it don't have file", function()
        local finish = false
        local error = false
        local replacer = sed:new({}, {
            on_error = function()
                error = true
                finish = true
            end,
            on_finish = function()
                finish = true
            end,
        })
        replacer:replace({
            lnum = 1,
            filename = 'sed_spec/sed_test1.txt',
            search_text = 'test',
            replace_text = 'stupid',
        })
        vim.wait(time_wait, function()
            return finish
        end)
        eq(true, error, 'should call finish')
    end)

    local test_sed = {
        {
            filename = 'sed_spec/sed_group_check.txt',
            search_text = [[function (new.*)]],
            replace_text = [[function abcde\1]],
            expected = 'test  function abcdenew()',
            lnum = 2,
        },
        {
            filename = 'sed_spec/sed_group_check.txt',
            lnum = 2,
            search_text = [[new\(]],
            replace_text = 'abcde(',
            expected = 'test  function abcde()',
        },
        {
            filename = 'sed_spec/sed_single_quote.txt',
            lnum = 1,
            search_text = [['abce]],
            replace_text = [[def]],
            expected = "test def' eff",
        },
        {
            filename = 'sed_spec/sed_slash.txt',
            lnum = 1,
            search_text = [[/home/winner]],
            replace_text = [[def]],
            expected = 'test def visual',
        },
        {
            ignore_case = true,
            filename = 'sed_spec/sed_ignore_case.txt',
            lnum = 1,
            search_text = [[spectre]],
            replace_text = [[data]],
            expected = 'data abcdef',
        },
        {
            ignore_case = true,
            filename = 'sed_spec/sed_multiple_quote.txt',
            lnum = 1,
            search_text = [[import \{ Box \} from "./box.abc"]],
            replace_text = [[window]],
            expected = 'window',
        },
    }
    for _, test in pairs(test_sed) do
        it('match result text in ' .. test.filename, function()
            if test.ignore_case == true then
                helpers.test_replace(test, get_replacer_case)
            else
                helpers.test_replace(test, get_replacer)
            end
        end)
    end

    for _, test in pairs(test_sed) do
        helpers.checkoutfile(test.filename)
    end
end)
