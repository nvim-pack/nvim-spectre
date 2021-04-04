
local has_devicons, devicons = pcall(require, 'nvim-web-devicons')
local state = require('spectre.state')
local utils = require('spectre.utils')
local Path = require('plenary.path')
local api = vim.api

local M={}


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
            api.nvim_buf_add_highlight(bufnr, namespace,state.user_config.highlight.search , lnum, value[1], value[2])
        end
        for _, value in pairs(diff.output) do
            api.nvim_buf_add_highlight(bufnr, namespace, state.user_config.highlight.replace, lnum + 1, value[1], value[2])
        end
    end

end

local get_devicons = (function()
    if has_devicons then
        if not devicons.has_loaded() then
            devicons.setup()
        end

        return function(filename, disable_devicons)
            if disable_devicons or not filename then
                return ''
            end
            local icon, icon_highlight = devicons.get_icon(filename, string.match(filename, '%a+$'), { default = true })
            if state.user_config.color_devicons then
                return icon, icon_highlight
            else
                return icon, ''
            end
        end
    else
        return function(_, _)
            return ''
        end
    end
end)()

M.render_filename = function (bufnr, namespace, line, entry)
    local config = state.user_config
    local filename = vim.fn.fnamemodify(entry.filename, ":t")
    local directory = vim.fn.fnamemodify(entry.filename, ":h")
    if directory=="." then
        directory = ""
    else
        directory = directory .. Path.path.sep
    end
    local icon, icon_highlight = get_devicons(filename, false)

    api.nvim_buf_set_lines(state.bufnr, line, line , false,{
        string.format("%s %s%s:%s:%s:", icon, directory, filename,entry.lnum,entry.col),
    })
    local width = utils.strdisplaywidth(filename)
    local hl = {
        {{1, 3}, icon_highlight},
        {{1, utils.strdisplaywidth(directory) + 1   }, config.highlight.filedirectory},
        {{0, width + 1 }, config.highlight.filename},
    }
    if icon=="" then
        table.remove(hl, 1)
    end
    local pos = 0
    for _,value in pairs(hl) do
        api.nvim_buf_add_highlight(bufnr,
            namespace,
            value[2],
            line,
            pos + value[1][1],
            pos + value[1][2]
        )
        pos = value[1][2] + pos
    end
end

return M
