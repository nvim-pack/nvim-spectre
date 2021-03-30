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
return M

