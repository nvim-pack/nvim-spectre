local utils = require('spectre.utils')
local M = {}
local api = vim.api

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

M.wait = function (time, check)
    time = time or 1000
    local done = false
    vim.defer_fn(function()
        done = true
    end, time)
    while not done do
        vim.cmd [[ sleep 20ms]]
        if check ~= nil and check() then
            done = true
        end
    end
end

M.checkoutfile = function(filename)
    utils.get_os_command_output({'git', 'checkout', 'HEAD', filename})
    return
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
    M.wait(1000, function()
        return finish
    end)
    local output_txt = utils.get_os_command_output({"cat", opts.filename})
    eq(output_txt[opts.lnum], opts.expected, "test " .. opts.filename)
end
return M

