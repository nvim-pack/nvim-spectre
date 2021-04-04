local utils = require('spectre.utils')
local Path=require('plenary.path')
local M = {}
local api = vim.api
_G._pwd = ''

M.init = function ()
    _G._pwd = vim.fn.system('pwd'):gsub("\n", "")
    vim.cmd ("set rtp +=".._G._pwd)
end

M.get_cwd = function(path)
    local root = Path:new (_G._pwd)
    local cwd = root:joinpath(path)
    return cwd.filename
end
M.defer_get_line = function(bufnr, start_col, end_col, time)
    assert(bufnr ~= nil, 'buffer not nil')
    time = time or 600
    local done = false
    local text=''
    vim.defer_fn(function()
        done = true
        text = api.nvim_buf_get_lines(bufnr, start_col, end_col, false)
    end, time)
    while not done do
        vim.cmd [[ sleep 20ms]]
    end
    return text
end


M.checkoutfile = function(filename)
    utils.run_os_cmd({'git', 'checkout', 'HEAD', filename})
    return
end

M.t=function(cmd)
  return vim.api.nvim_replace_termcodes(cmd, true, false, true)
end

M.test_replace = function(opts, f_replace)
    local eq = assert.are.same
    M.checkoutfile(opts.filename)
    local finish = false
    local handler= {
        on_finish = function()
            finish = true
        end
    }
    local replacer = f_replace(handler)
    replacer:replace({
        lnum = opts.lnum,
        filename = opts.filename,
        search_text = opts.search_text,
        replace_text = opts.replace_text
    })
    vim.wait(1000, function() return finish end)
    local output_txt = utils.run_os_cmd({"cat", opts.filename})
    eq(output_txt[opts.lnum], opts.expected, "test " .. opts.filename)
end
return M

