local spectre = require('spectre')
local config=require('spectre.config')
local state = require('spectre.state')
local helper=require('tests.helper')

local eq = assert.are.same
local api = vim.api

vim.cmd[[tcd tests/project]]
describe('spectre panel ui', function()
  before_each(function()
      -- vim.cmd[[:bd]]
  end)

 it("check buffer option ",function()
     spectre.open()
     local bufnr = api.nvim_get_current_buf()
     eq(config.filetype, api.nvim_buf_get_option(bufnr, 'filetype'), 'should have corret file type')
     eq('spectre', api.nvim_buf_get_name(bufnr):match('spectre$'),'shoule have correct filename')
  end)
  it("should open search and result not empty",function ()
     spectre.open({
         search_text = "spectre"
     })

     local bufnr = api.nvim_get_current_buf()
     local test1 = helper.defer_get_line(bufnr, config.lnum_UI + 2, config.lnum_UI + 4)
     eq("test1.txt:1:1:", test1[1], "should have correct text")

  end)
end)
