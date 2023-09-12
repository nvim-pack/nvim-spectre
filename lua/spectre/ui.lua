local has_devicons, devicons = pcall(require, 'nvim-web-devicons')
local config = require('spectre.config')
local state = require('spectre.state')
local state_utils = require('spectre.state_utils')
local utils = require('spectre.utils')

local Path = require('plenary.path')

local popup = require "plenary.popup"
local api = vim.api

local M = {}


---@param regex RegexEngine
M.render_line = function(bufnr, namespace, text_opts, view_opts, regex)
    local cfg = state.user_config
    local diff = utils.get_hl_line_text({
        search_query = text_opts.search_query,
        replace_query = text_opts.replace_query,
        search_text = text_opts.search_text,
        show_search = view_opts.show_search,
        show_replace = view_opts.show_replace,
    }, regex)
    local end_lnum = text_opts.is_replace == true and text_opts.lnum + 1 or text_opts.lnum
    api.nvim_buf_set_lines(bufnr, text_opts.lnum, end_lnum, false, {
        view_opts.padding_text .. diff.text,
    })
    if not view_opts.is_disable then
        for _, value in pairs(diff.search) do
            api.nvim_buf_add_highlight(bufnr, namespace,
                cfg.highlight.search,
                text_opts.lnum, value[1] + view_opts.padding, value[2] + view_opts.padding)
        end
        for _, value in pairs(diff.replace) do
            api.nvim_buf_add_highlight(bufnr, namespace,
                cfg.highlight.replace,
                text_opts.lnum, value[1] + view_opts.padding, value[2] + view_opts.padding)
        end
        api.nvim_buf_add_highlight(state.bufnr, config.namespace,
            cfg.highlight.border, text_opts.lnum, 0, view_opts.padding)
    else
        api.nvim_buf_add_highlight(state.bufnr, config.namespace,
            cfg.highlight.border, text_opts.lnum, 0, -1)
    end
end

local get_devicons = (function()
    if has_devicons then
        if not devicons.has_loaded() then
            devicons.setup()
        end

        return function(filename, enable_icon, default)
            if not enable_icon or not filename then
                return default or '|', ''
            end
            local icon, icon_highlight = devicons.get_icon(filename, string.match(filename, '%a+$'), { default = true })
            return icon, icon_highlight
        end
    else
        return function(_, _)
            return ''
        end
    end
end)()

M.render_filename = function(bufnr, namespace, line, entry)
    local u_config = state.user_config
    local filename = vim.fn.fnamemodify(entry.filename, ":t")
    local directory = vim.fn.fnamemodify(entry.filename, ":h")
    if directory == "." then
        directory = ""
    else
        directory = directory .. Path.path.sep
    end

    local icon_length = state.user_config.color_devicons and 4 or 2
    local icon, icon_highlight = get_devicons(
        filename,
        state.user_config.color_devicons, '+')

    api.nvim_buf_set_lines(state.bufnr, line, line, false, {
        string.format("%s %s%s:%s:%s:", icon, directory, filename, entry.lnum, entry.col),
    })

    local width = vim.api.nvim_strwidth(filename)
    local hl = {
        { { 0, icon_length },                      icon_highlight },
        { { 0, vim.api.nvim_strwidth(directory) }, u_config.highlight.filedirectory },
        { { 0, width + 1 },                        u_config.highlight.filename },
    }
    if icon == "" then
        table.remove(hl, 1)
    end
    local pos = 0
    for _, value in pairs(hl) do
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

function M.render_search_ui()
    api.nvim_buf_clear_namespace(state.bufnr, config.namespace_ui, 0, config.lnum_UI)
    local details_ui = {}
    local search_message = "Search:          "
    local cfg = state_utils.get_search_engine_config()
    for key, value in pairs(state.options) do
        if value == true and cfg.options[key] then
            search_message = search_message .. cfg.options[key].icon
        end
    end

    table.insert(details_ui, { { search_message, state.user_config.highlight.ui } })
    table.insert(details_ui, { { "Replace: ", state.user_config.highlight.ui } })
    local path_message = "Path:"
    if state.cwd then
        path_message = path_message .. string.format("   cwd=%s", state.cwd)
    end
    table.insert(details_ui, { { path_message, state.user_config.highlight.ui } })

    local c_line = 1
    for _, vt_text in ipairs(details_ui) do
        utils.write_virtual_text(state.bufnr, config.namespace_ui, c_line, vt_text)
        c_line = c_line + 2
    end
    M.render_header(state.user_config)
end

function M.render_header(opts)
    api.nvim_buf_clear_namespace(state.bufnr, config.namespace_header, 0, config.lnum_UI)
    local help_text = string.format(
        "[Nvim Spectre] (Search by %s) %s (Replace by %s) (Press ? for mappings)",
        state.user_config.default.find.cmd,
        opts.live_update and '(Auto update)' or '',
        state.user_config.default.replace.cmd
    )
    utils.write_virtual_text(state.bufnr, config.namespace_header, 0,
        { { help_text, state.user_config.highlight.headers } })
end

M.show_menu_options = function(title, content)
    local win_width, win_height = vim.lsp.util._make_floating_popup_size(content, {})

    local bufnr = vim.api.nvim_create_buf(false, true)
    api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")
    api.nvim_buf_set_lines(bufnr, 0, -1, true, content)

    local help_win = vim.api.nvim_open_win(bufnr, false, {
        style = "minimal",
        title = " " .. title .. " ",
        title_pos = 'center',
        relative = 'cursor',
        width = win_width,
        height = win_height,
        col = 0,
        row = 1,
        border = "rounded"
    })
    api.nvim_win_set_option(help_win, 'winblend', 0)
    api.nvim_buf_set_keymap(bufnr, 'n', '<Esc>', '<CMD>lua vim.api.nvim_win_close(' .. help_win .. ', true)<CR>',
        { noremap = true })

    api.nvim_create_autocmd({
        'CursorMovedI',
        'CursorMoved',
        'CursorMovedI',
        'BufHidden',
        'BufLeave',
        'InsertEnter',
        'WinScrolled',
        'BufDelete',
    }, {
        callback = function()
            pcall(vim.api.nvim_win_close, help_win, true)
        end,
    })
end

M.show_help = function()
    local help_msg = {}
    local map_tbl = {};
    for _, map in pairs(state.user_config.mapping) do
        table.insert(map_tbl, map)
    end
    -- sort by length
    table.sort(map_tbl, function(a, b)
        return (#a.map or 0) < (#b.map or 0)
    end)

    for _, map in pairs(map_tbl) do
        table.insert(help_msg, string.format("%9s : %s", map.map, map.desc))
    end

    M.show_menu_options("Mappings", help_msg)
end

M.show_options = function()
    local cfg = state_utils.get_search_engine_config()
    local help_msg = { " Press number to select option." }
    local option_cmd = {}
    local i = 1

    for key, option in pairs(cfg.options) do
        table.insert(help_msg, string.format(" %s : toggle %s", i, option.desc or ' '))
        table.insert(option_cmd, key)
        i = i + 1
    end

    M.show_menu_options("Options", help_msg)
    return option_cmd
end

M.show_find_engine = function()
    local engines = state.user_config.find_engine;

    local help_msg = { " Press number to select option." }
    local option_cmd = {}
    local i = 1

    for key, option in pairs(engines) do
        table.insert(help_msg, string.format(" %s : engine %s", i, option.desc or ' '))
        table.insert(option_cmd, key)
        i = i + 1
    end
end

M.render_text_query = function(opts)
    -- set empty line for virtual text
    local lines = {}
    local length = config.lnum_UI
    for _ = 1, length, 1 do
        table.insert(lines, "")
    end
    api.nvim_buf_set_lines(state.bufnr, 0, 0, false, lines)
    api.nvim_buf_set_lines(state.bufnr, 2, 2, false, { opts.search_text })
    api.nvim_buf_set_lines(state.bufnr, 4, 4, false, { opts.replace_text })
    api.nvim_buf_set_lines(state.bufnr, 6, 6, false, { opts.path })
    api.nvim_win_set_cursor(0, { opts.begin_line_num or 3, 0 })
end

return M
