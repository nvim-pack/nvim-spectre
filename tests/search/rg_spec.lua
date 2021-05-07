local rg = require('spectre.search').rg
local eq = assert.are.same

vim.cmd [[tcd tests/project]]

local time_wait = 1000

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
        vim.wait(time_wait, function()
            return finish
        end)
        eq(2, total_item, "should have 2 item")

    end)

    it("should call finish function", function()
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
        vim.wait(time_wait, function()
            return finish
        end)
        eq(true, finish, "finish is not call")
    end)

    it("search with path should not empty", function()
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
        finder:search({search_text = "spectre", path = "**/rg_spec/*.txt"})
        vim.wait(time_wait, function()
            return finish
        end)
        eq(1, total_item, "should have 1 item")

    end)

    it("search with multiple paths should not be empty", function()
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
        finder:search({
            search_text = "(data|spectre)",
            path = "**/rg_spec/*.txt **/sed_spec/*.txt"
        })
        vim.wait(time_wait, function()
            return finish
        end)
        eq(4, total_item, "should have 4 items")

    end)

end)
