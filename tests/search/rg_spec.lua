local rg = require('spectre.search.rg')
local helpers = require('tests.helper')
local eq = assert.are.same

vim.cmd [[tcd tests/project]]

describe("[rg] search ", function()
    it("should not empty", function()
        local finish = false
        local total = {}
        local total_item = 0
        local finder = rg:new({}, {
            on_result = function(item)
                table.insert(total, item)
                total_item = total_item + 1
            end,
            on_finish = function()
                finish = true
            end
        })
        finder:search({search_text = "spectre"})
        helpers.wait(1000, function()
            return finish
        end)
        eq(2, total_item, "should have 2 item")

    end)
end)
