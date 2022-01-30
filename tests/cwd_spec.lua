local spectre = require('spectre')
local utils = require('spectre.utils')
-- local rg = require('spectre.search.rg')
local config = require('spectre.config')
local helper = require('tests.helper')

local eq = assert.are.same
local api = vim.api

helper.init()
vim.cmd([[tcd tests/project]])
describe('check search on another directory', function()
    -- before_each(function()
    --     -- vim.cmd[[:bd]]
    -- end)

    it('open search and result not empty', function()
        local cwd = helper.get_cwd('tests/project_2/')
        spectre.open({
            search_text = 'spectre',
            cwd = cwd,
        })

        local bufnr = api.nvim_get_current_buf()
        local test1 = helper.defer_get_line(
            bufnr,
            config.lnum_UI + 2,
            config.lnum_UI + 4
        )
        eq(' test2.txt:1:1:', test1[1], 'should have correct text')
        vim.api.nvim_win_set_cursor(0, { 12, 0 })
        vim.api.nvim_feedkeys(helper.t('<cr>'), 'x', true)
        local filename = vim.api.nvim_buf_get_name(0)
        eq(cwd .. 'test2.txt', filename, 'should has a correct path')
    end)
    it('replace text ', function()
        local filename = '../project_2/test2.txt'
        helper.checkoutfile(filename)
        local cwd = helper.get_cwd('tests/project_2/')
        spectre.open({
            search_text = 'spectre',
            cwd = cwd,
            replace_text = 'data',
            path = 'test2.txt',
        })
        local bufnr = api.nvim_get_current_buf()
        local test1 = helper.defer_get_line(
            bufnr,
            config.lnum_UI + 2,
            config.lnum_UI + 4
        )
        eq(' test2.txt:1:1:', test1[1], 'should have correct text')
        api.nvim_feedkeys(helper.t('<leader>R'), 'x', true)
        vim.wait(1000)
        local output_txt = utils.run_os_cmd({ 'cat', '../project_2/test2.txt' })
        eq(output_txt[1], 'data visual', ' test should match')
        helper.checkoutfile(filename)
    end)
end)
