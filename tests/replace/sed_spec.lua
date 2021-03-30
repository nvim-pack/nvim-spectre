local sed = require('spectre.replace').sed
local helpers = require('tests.helper')
local utils = require('spectre.utils')
vim.cmd [[tcd tests/project]]

local eq = assert.are.same
local time_wait = 1000

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
        replacer:replace({
            lnum = 1,
            filename = filename,
            search_text = "spectre",
            replace_text = "zzzz"
        })
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
            on_error=function()
                error=true
                finish = true
            end,
            on_finish = function()
                finish = true
            end
        })
        replacer:replace({
            lnum = 1,
            filename = "sed_spec/sed_test1.txt",
            search_text = "test",
            replace_text = "stupid"
        })
        helpers.wait(time_wait, function()
            return finish
        end)
        eq(true, error, "should call finish")
    end)


end)
