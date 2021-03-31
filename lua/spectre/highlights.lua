local M = {}
local utils = import('spectre.utils')
local config = import('spectre.config')
local api = vim.api

M.hl_different_line = function(bufnr, namespace, search_query, replace_query, search, replace, lnum, padding)
    local diff = utils.different_text_col({
        search_text = search_query,
        replace_text = replace_query,
        search_line = search,
        replace_line = replace,
        padding = padding or 0
    })
    if diff then
        for _, value in pairs(diff.input) do
            api.nvim_buf_add_highlight(bufnr, namespace,config.highlight.search , lnum, value[1], value[2])
        end
        for _, value in pairs(diff.output) do
            api.nvim_buf_add_highlight(bufnr, namespace, config.highlight.replace, lnum + 1, value[1], value[2])
        end
    end

end

return M
