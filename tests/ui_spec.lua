local spectre = require('spectre')
local utils = require('spectre.utils')
-- local rg = require('spectre.search.rg')
local config = require('spectre.config')
local helper = require('tests.helper')

local eq = assert.are.same
local api = vim.api

vim.cmd [[tcd tests/project]]
describe('spectre panel UI', function()
    -- before_each(function()
    --     -- vim.cmd[[:bd]]
    -- end)

    it("check buffer option ", function()
        spectre.open()
        local bufnr = api.nvim_get_current_buf()
        eq(config.filetype, api.nvim_buf_get_option(bufnr, 'filetype'), 'should have corret file type')
        eq('spectre', api.nvim_buf_get_name(bufnr):match('spectre$'), 'shoule have correct filename')
    end)
    it("open search and result not empty", function()
        spectre.open({search_text = "spectre"})
        local bufnr = api.nvim_get_current_buf()
        local test1 = helper.defer_get_line(bufnr, config.lnum_UI + 2, config.lnum_UI + 4)
        eq(true, #test1[1] > 5, "it don't have result item")

    end)
    it("replace text ", function()
        local filename = "test1.txt"
        helper.checkoutfile(filename)
        spectre.open({search_text = "spectre", replace_text = "data", path = 'test1.txt'})
        local bufnr = api.nvim_get_current_buf()
        local test1 = helper.defer_get_line(bufnr, config.lnum_UI + 2, config.lnum_UI + 4)
        eq(" test1.txt:1:1:", test1[1], "should have correct text")
        api.nvim_feedkeys(helper.t"<leader>R", 'x', true)
        vim.wait(500)
        local output_txt = utils.run_os_cmd({"cat", 'test1.txt'})
        eq(output_txt[1], "data abcde", " test should match")
        helper.checkoutfile(filename)
    end)
end)
