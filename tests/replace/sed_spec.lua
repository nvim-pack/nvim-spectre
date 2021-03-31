local sed = require('spectre.replace').sed
local helpers = require('tests.helper')
local utils = require('spectre.utils')
vim.cmd [[tcd tests/project]]

local eq = assert.are.same
local time_wait = 1000

local get_replacer = function(handler)
    return sed:new({}, handler)
end

describe("[sed] replace ", function()
    it("should not empty", function()
        local filename = 'sed_spec/sed_test.txt'
        helpers.checkoutfile(filename)
        local finish = false
        local replacer = sed:new({}, {
            on_finish = function()
                finish = true
            end
        })
        replacer:replace({lnum = 1, filename = filename, search_text = "spectre", replace_text = "zzzz"})
        helpers.wait(time_wait, function()
            return finish
        end)
        local output_txt = utils.get_os_command_output({"cat", filename})
        eq(output_txt[1], "test data zzzz ok ()")
        eq(true, finish, "should call finish")
    end)

    it("should call error when it don't have file", function()
        local finish = false
        local error = false
        local replacer = sed:new({}, {
            on_error = function()
                error = true
                finish = true
            end,
            on_finish = function()
                finish = true
            end
        })
        replacer:replace({lnum = 1, filename = "sed_spec/sed_test1.txt", search_text = "test", replace_text = "stupid"})
        helpers.wait(time_wait, function()
            return finish
        end)
        eq(true, error, "should call finish")
    end)

    local test_sed = {
        {
            filename = 'sed_spec/sed_group_check.txt',
            search_text = [[function (new.*)]],
            replace_text = [[function abcde\1]],
            expected = "test  function abcdenew()",
            lnum = 2
        }, {
            filename = 'sed_spec/sed_group_check.txt',
            lnum = 2,
            search_text = [[new\(]],
            replace_text = "abcde(",
            expected = "test  function abcde()"
        }, {
            filename = 'sed_spec/sed_single_quote.txt',
            lnum = 1,
            search_text = [['abce]],
            replace_text = [[def]],
            expected = "test 'abce' eff"
        }, {
            filename = 'sed_spec/sed_slash.txt',
            lnum = 1,
            search_text = [[/home/winner]],
            replace_text = [[def]],
            expected = "test def visual"
        }
    }
    for _, test in pairs(test_sed) do
        it("should match result text in " .. test.filename, function()
            helpers.test_replace(test, get_replacer)
        end)
    end

    for _,test in pairs(test_sed) do
        helpers.checkoutfile(test.filename)
    end

end)
