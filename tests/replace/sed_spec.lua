local sed = import('spectre.replace').sed
local helpers = require('tests.helper')
vim.cmd [[tcd tests/project]]

local eq = assert.are.same
local time_wait = 1000

describe("[rg] search ", function()

    it("should not empty", function()
        local finish = false
        local total = {}
        local total_item = 0
        local replacer = sed:new({}, {
            on_result = function(item)
                table.insert(total, item)
                total_item = total_item + 1
            end,
            on_finish = function()
                finish = true
            end
        })
        replacer:replace({
            lnum = 1,
            filename="sed_spec/sed_test.txt",
            search_text = "spectre",
            replace_text = "stupid"
        })
        helpers.wait(time_wait, function()
            return finish
        end)
        eq(2, total_item, "should have 2 item")
    end)


end)
