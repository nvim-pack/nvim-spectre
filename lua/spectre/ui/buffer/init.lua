local has_devicons, devicons = pcall(require, 'nvim-web-devicons')
local has_mini_icons, mini_icons = pcall(require, 'mini.icons')
local config = require('spectre.config')
local state = require('spectre.state')
local state_utils = require('spectre.state_utils')
local utils = require('spectre.utils')

local Path = require('plenary.path')
local popup = require('plenary.popup')
local api = vim.api

local M = {}

-- Buffer and UI state
M.bufnr = nil
M.namespace = vim.api.nvim_create_namespace('spectre_ui')
M.namespace_result = vim.api.nvim_create_namespace('spectre_result')
M.namespace_header = vim.api.nvim_create_namespace('spectre_header')
M.namespace_status = vim.api.nvim_create_namespace('spectre_status')
M.namespace_ui = vim.api.nvim_create_namespace('spectre_ui_components')

-- Setup foldexpr function
local foldexpr = function(lnum)
    if lnum < config.lnum_UI then
        return '0'
    end
    local line = vim.fn.getline(lnum)
    local padding = line:sub(0, #state.user_config.result_padding)
    if padding ~= state.user_config.result_padding then
        return '>1'
    end

    local nextline = vim.fn.getline(lnum + 1)
    padding = nextline:sub(0, #state.user_config.result_padding)
    if padding ~= state.user_config.result_padding then
        return '<1'
    end
    local item = state.total_item[lnum]
    if item ~= nil then
        return '1'
    end
    return '0'
end

-- Setup folding using Vim script approach
M.setup_folding = function()
    -- We'll use the autoload/spectre.vim function, which is already defined
    -- Just set up folding parameters
    vim.opt_local.foldexpr = 'spectre#foldexpr()'
    vim.opt_local.foldmethod = 'expr'
end

---@param regex RegexEngine
M.render_line = function(bufnr, namespace, text_opts, view_opts, regex)
    local cfg = state.user_config
    local diff = utils.get_hl_line_text({
        search_query = text_opts.search_query,
        replace_query = text_opts.replace_query,
        search_text = text_opts.search_text,
        show_search = view_opts.show_search,
    }, regex)
    local end_lnum = text_opts.is_replace == true and text_opts.lnum + 1 or text_opts.lnum

    local item_line_len = 0
    if cfg.lnum_for_results == true then
        item_line_len = string.len(text_opts.item_line) + 1
        api.nvim_buf_set_lines(bufnr, text_opts.lnum, end_lnum, false, {
            view_opts.padding_text .. text_opts.item_line .. ' ' .. diff.text,
        })
    else
        api.nvim_buf_set_lines(bufnr, text_opts.lnum, end_lnum, false, {
            view_opts.padding_text .. diff.text,
        })
    end

    if not view_opts.is_disable then
        for _, value in pairs(diff.search) do
            api.nvim_buf_add_highlight(
                bufnr,
                namespace,
                cfg.highlight.search,
                text_opts.lnum,
                value[1] + view_opts.padding + item_line_len,
                value[2] + view_opts.padding + item_line_len
            )
        end
        for _, value in pairs(diff.replace) do
            api.nvim_buf_add_highlight(
                bufnr,
                namespace,
                cfg.highlight.replace,
                text_opts.lnum,
                value[1] + view_opts.padding + item_line_len,
                value[2] + view_opts.padding + item_line_len
            )
        end
        api.nvim_buf_add_highlight(
            M.bufnr,
            config.namespace,
            cfg.highlight.border,
            text_opts.lnum,
            0,
            view_opts.padding
        )
    else
        api.nvim_buf_add_highlight(M.bufnr, config.namespace, cfg.highlight.border, text_opts.lnum, 0, -1)
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
    elseif has_mini_icons then
        if not _G.MiniIcons then
            mini_icons.setup()
        end

        return function(filename, enable_icon, default)
            if not enable_icon or not filename then
                return default or '|', ''
            end
            local icon, icon_highlight = mini_icons.get('file', filename)
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
    local filename = vim.fn.fnamemodify(entry.filename, ':t')
    local directory = vim.fn.fnamemodify(entry.filename, ':h')
    if directory == '.' then
        directory = ''
    else
        directory = directory .. Path.path.sep
    end

    local icon_length = state.user_config.color_devicons and 4 or 2
    local icon, icon_highlight = get_devicons(filename, state.user_config.color_devicons, '+')

    api.nvim_buf_set_lines(M.bufnr, line, line, false, {
        string.format('%s %s%s:', icon, directory, filename),
    })

    local width = vim.api.nvim_strwidth(filename)
    local hl = {
        { { 0, icon_length }, icon_highlight },
        { { 0, vim.api.nvim_strwidth(directory) }, u_config.highlight.filedirectory },
        { { 0, width + 1 }, u_config.highlight.filename },
    }
    if icon == '' then
        table.remove(hl, 1)
    end
    local pos = 0
    for _, value in pairs(hl) do
        pcall(function()
            api.nvim_buf_add_highlight(bufnr, namespace, value[2], line, pos + value[1][1], pos + value[1][2])
            pos = value[1][2] + pos
        end)
    end
end

function M.render_search_ui()
    api.nvim_buf_clear_namespace(M.bufnr, M.namespace_ui, 0, config.lnum_UI)
    local details_ui = {}
    local search_message = 'Search:          '
    local cfg = state_utils.get_search_engine_config()
    for key, value in pairs(state.options) do
        if value == true and cfg.options[key] then
            search_message = search_message .. cfg.options[key].icon
        end
    end

    table.insert(details_ui, { { search_message, state.user_config.highlight.ui } })
    table.insert(details_ui, { { 'Replace: ', state.user_config.highlight.ui } })
    local path_message = 'Path:'
    if state.cwd then
        path_message = path_message .. string.format('   cwd=%s', state.cwd)
    end
    table.insert(details_ui, { { path_message, state.user_config.highlight.ui } })

    local c_line = 1
    for _, vt_text in ipairs(details_ui) do
        utils.write_virtual_text(M.bufnr, M.namespace_ui, c_line, vt_text)
        c_line = c_line + 2
    end
    M.render_header(state.user_config)
end

function M.render_header(opts)
    api.nvim_buf_clear_namespace(M.bufnr, M.namespace_header, 0, config.lnum_UI)
    local help_text = string.format(
        '[Nvim Spectre] (Search by %s) %s (Replace by %s) (Press ? for mappings)',
        state.user_config.default.find.cmd,
        opts.live_update and '(Auto update)' or '',
        state.user_config.default.replace.cmd
    )
    utils.write_virtual_text(M.bufnr, M.namespace_header, 0, { { help_text, state.user_config.highlight.headers } })
end

M.show_menu_options = function(title, content)
    local win_width, win_height = vim.lsp.util._make_floating_popup_size(content, {})

    local bufnr = vim.api.nvim_create_buf(false, true)
    api.nvim_buf_set_option(bufnr, 'bufhidden', 'wipe')
    api.nvim_buf_set_lines(bufnr, 0, -1, true, content)

    local help_win = vim.api.nvim_open_win(bufnr, false, {
        style = 'minimal',
        title = ' ' .. title .. ' ',
        title_pos = 'center',
        relative = 'cursor',
        width = win_width,
        height = win_height,
        col = 0,
        row = 1,
        border = 'rounded',
    })
    api.nvim_win_set_option(help_win, 'winblend', 0)
    api.nvim_buf_set_keymap(
        bufnr,
        'n',
        '<Esc>',
        '<CMD>lua vim.api.nvim_win_close(' .. help_win .. ', true)<CR>',
        { noremap = true }
    )

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
    local map_tbl = {}
    for _, map in pairs(state.user_config.mapping) do
        table.insert(map_tbl, map)
    end
    -- sort by length
    table.sort(map_tbl, function(a, b)
        return (#a.map or 0) < (#b.map or 0)
    end)

    for _, map in pairs(map_tbl) do
        table.insert(help_msg, string.format('%9s : %s', map.map, map.desc))
    end

    M.show_menu_options('Mappings', help_msg)
end

M.show_options = function()
    local cfg = state_utils.get_search_engine_config()
    local help_msg = { ' Press number to select option.' }
    local option_cmd = {}
    local i = 1

    for key, option in pairs(cfg.options) do
        table.insert(help_msg, string.format(' %s : toggle %s', i, option.desc or ' '))
        table.insert(option_cmd, key)
        i = i + 1
    end

    M.show_menu_options('Options', help_msg)
    return option_cmd
end

M.show_find_engine = function()
    local engines = state.user_config.find_engine

    local help_msg = { ' Press number to select option.' }
    local option_cmd = {}
    local i = 1

    for key, option in pairs(engines) do
        table.insert(help_msg, string.format(' %s : engine %s', i, option.desc or ' '))
        table.insert(option_cmd, key)
        i = i + 1
    end
end

M.render_text_query = function(opts)
    -- set empty line for virtual text
    local lines = {}
    local length = config.lnum_UI
    for _ = 1, length, 1 do
        table.insert(lines, '')
    end
    api.nvim_buf_set_lines(M.bufnr, 0, 0, false, lines)
    api.nvim_buf_set_lines(M.bufnr, 2, 2, false, { opts.search_text })
    api.nvim_buf_set_lines(M.bufnr, 4, 4, false, { opts.replace_text })
    api.nvim_buf_set_lines(M.bufnr, 6, 6, false, { opts.path })
    api.nvim_win_set_cursor(0, { opts.begin_line_num or 3, 0 })
end

-- Open the Spectre UI
M.open = function()
    -- If already open, return
    if M.bufnr and vim.api.nvim_buf_is_valid(M.bufnr) then
        local wins = vim.fn.win_findbuf(M.bufnr)
        if #wins >= 1 then
            for _, win_id in pairs(wins) do
                if vim.fn.win_gotoid(win_id) == 1 then
                    return
                end
            end
        end
    end

    -- Open a new window and buffer
    if type(state.user_config.open_cmd) == 'function' then
        state.user_config.open_cmd()
    else
        vim.cmd(state.user_config.open_cmd)
    end

    vim.wo.foldenable = false
    vim.bo.buftype = 'nofile'
    vim.bo.buflisted = false
    M.bufnr = api.nvim_get_current_buf()
    state.bufnr = M.bufnr
    vim.cmd(string.format('file %s/spectre', M.bufnr))
    vim.bo.filetype = config.filetype

    api.nvim_buf_clear_namespace(M.bufnr, M.namespace_status, 0, -1)
    api.nvim_buf_clear_namespace(M.bufnr, M.namespace_result, 0, -1)
    api.nvim_buf_set_lines(M.bufnr, 0, -1, false, {})

    -- Setup folding
    M.setup_folding()

    -- Setup the UI
    M.render_text_query({
        search_text = state.query.search_query or '',
        replace_text = state.query.replace_query or '',
        path = state.query.path or '',
        begin_line_num = 3,
    })

    M.render_search_ui()

    -- Create mappings
    M.mapping_buffer()

    -- Focus on search line
    if state.user_config.is_insert_mode == true then
        vim.api.nvim_feedkeys('A', 'n', true)
    end
end

-- Close the Spectre UI
M.close = function()
    if M.bufnr and vim.api.nvim_buf_is_valid(M.bufnr) then
        local wins = vim.fn.win_findbuf(M.bufnr)
        if #wins >= 1 then
            for _, win_id in pairs(wins) do
                vim.api.nvim_win_close(win_id, true)
            end
        end
    end
    M.bufnr = nil
    state.bufnr = nil
end

-- Function to handle search changes
M.on_search_change = function()
    local lines = api.nvim_buf_get_lines(M.bufnr, 0, config.lnum_UI, false)

    local query = {
        replace_query = '',
        search_query = '',
        path = '',
    }

    for index, line in pairs(lines) do
        if index <= 3 and #line > 0 then
            query.search_query = query.search_query .. line
        end
        if index >= 5 and index < 7 and #line > 0 then
            query.replace_query = query.replace_query .. line
        end
        if index >= 7 and index <= 9 and #line > 0 then
            query.path = query.path .. line
        end
    end

    local line = vim.fn.getpos('.')
    -- Update state
    state.query = query

    -- Trigger appropriate action
    if line[2] >= 5 and line[2] < 7 then
        require('spectre').run_replace()
    else
        require('spectre').search(query)
    end
end

-- Setup buffer mappings
M.mapping_buffer = function()
    -- Set up autocmds
    vim.cmd([[augroup spectre_panel
                au!
                au InsertEnter <buffer> lua require"spectre.ui.buffer".on_insert_enter()
                au InsertLeave <buffer> lua require"spectre.ui.buffer".on_search_change()
                au BufLeave <buffer> lua require("spectre").on_write()
                au BufUnload <buffer> lua require("spectre").close()
            augroup END ]])

    vim.opt_local.wrap = false

    -- Folding is already set up in setup_folding()

    local map_opt = { noremap = true, silent = _G.__is_dev == nil }
    api.nvim_buf_set_keymap(
        M.bufnr,
        'n',
        'x',
        'x<cmd>lua require("spectre.ui.buffer").on_search_change()<CR>',
        map_opt
    )
    api.nvim_buf_set_keymap(
        M.bufnr,
        'n',
        'p',
        "p<cmd>lua require('spectre.ui.buffer').on_search_change()<cr>",
        map_opt
    )
    api.nvim_buf_set_keymap(
        M.bufnr,
        'v',
        'p',
        "p<cmd>lua require('spectre.ui.buffer').on_search_change()<cr>",
        map_opt
    )
    api.nvim_buf_set_keymap(
        M.bufnr,
        'v',
        'P',
        "P<cmd>lua require('spectre.ui.buffer').on_search_change()<cr>",
        map_opt
    )
    api.nvim_buf_set_keymap(M.bufnr, 'n', 'd', '<nop>', map_opt)
    api.nvim_buf_set_keymap(M.bufnr, 'i', '<c-c>', '<esc>', map_opt)
    api.nvim_buf_set_keymap(M.bufnr, 'v', 'd', '<esc><cmd>lua require("spectre").toggle_checked()<cr>', map_opt)
    api.nvim_buf_set_keymap(M.bufnr, 'n', 'o', 'ji', map_opt) -- don't append line on can make the UI wrong
    api.nvim_buf_set_keymap(M.bufnr, 'n', 'O', 'ki', map_opt)
    api.nvim_buf_set_keymap(M.bufnr, 'n', 'u', '', map_opt) -- disable undo, It breaks the UI.
    api.nvim_buf_set_keymap(M.bufnr, 'n', 'yy', "<cmd>lua require('spectre.actions').copy_current_line()<cr>", map_opt)
    api.nvim_buf_set_keymap(M.bufnr, 'n', '?', "<cmd>lua require('spectre.ui.buffer').show_help()<cr>", map_opt)

    for _, map in pairs(state.user_config.mapping) do
        if map.cmd then
            api.nvim_buf_set_keymap(
                M.bufnr,
                'n',
                map.map,
                map.cmd,
                vim.tbl_deep_extend('force', map_opt, { desc = map.desc })
            )
        end
    end

    vim.api.nvim_create_autocmd('BufWritePost', {
        group = vim.api.nvim_create_augroup('SpectrePanelWrite', { clear = true }),
        pattern = '*',
        callback = require('spectre').on_write,
        desc = 'spectre write autocmd',
    })

    vim.api.nvim_create_autocmd('WinClosed', {
        group = vim.api.nvim_create_augroup('SpectreStateOpened', { clear = true }),
        buffer = M.bufnr,
        callback = function()
            if vim.api.nvim_buf_get_option(vim.api.nvim_get_current_buf(), 'filetype') == 'spectre_panel' then
                state.is_open = false
            end
        end,
        desc = 'Ensure spectre state when its window is closed by any mean',
    })

    if state.user_config.is_block_ui_break then
        -- Anti UI breakage
        -- * If the user enters insert mode on a forbidden line: leave insert mode.
        -- * If the user passes over a forbidden line on insert mode: leave insert mode.
        -- * Disable backspace jumping lines.
        local backspace = vim.api.nvim_get_option('backspace')
        local anti_insert_breakage_group = vim.api.nvim_create_augroup('SpectreAntiInsertBreakage', { clear = true })
        vim.api.nvim_create_autocmd({ 'InsertEnter', 'CursorMovedI' }, {
            group = anti_insert_breakage_group,
            buffer = M.bufnr,
            callback = function()
                local current_filetype = vim.bo.filetype
                if current_filetype == 'spectre_panel' then
                    vim.cmd('set backspace=indent,start')
                    local line = vim.api.nvim_win_get_cursor(0)[1]
                    if line == 1 or line == 2 or line == 4 or line == 6 or line >= 8 then
                        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', true)
                    end
                end
            end,
            desc = 'spectre anti-insert-breakage → protect the user from breaking the UI while on insert mode.',
        })
        vim.api.nvim_create_autocmd({ 'WinLeave' }, {
            group = anti_insert_breakage_group,
            buffer = M.bufnr,
            callback = function()
                local current_filetype = vim.bo.filetype
                if current_filetype == 'spectre_panel' then
                    vim.cmd('set backspace=' .. backspace)
                end
            end,
            desc = "spectre anti-insert-breakage → restore the 'backspace' option.",
        })
        api.nvim_buf_set_keymap(M.bufnr, 'i', '<CR>', '', map_opt) -- disable ENTER on insert mode, it breaks the UI.
    end
end

M.on_insert_enter = function()
    local line = vim.fn.getpos('.')
    if line[2] > config.lnum_UI then
        local key = api.nvim_replace_termcodes('<esc>', true, false, true)
        api.nvim_feedkeys(key, 'm', true)
        print("You can't make changes in results.")
    end
end

M.tab = function()
    local line = vim.api.nvim_win_get_cursor(0)[1]
    if line == 3 then
        vim.api.nvim_win_set_cursor(vim.api.nvim_get_current_win(), { 5, 1 })
    end
    if line == 5 then
        vim.api.nvim_win_set_cursor(vim.api.nvim_get_current_win(), { 7, 1 })
    end
end

M.tab_shift = function()
    local line = vim.api.nvim_win_get_cursor(0)[1]
    if line == 5 then
        vim.api.nvim_win_set_cursor(vim.api.nvim_get_current_win(), { 3, 1 })
    end
    if line == 7 then
        vim.api.nvim_win_set_cursor(vim.api.nvim_get_current_win(), { 5, 1 })
    end
end

-- Placeholder for toggle_preview - not implemented in the plenary UI
M.toggle_preview = function()
    -- Not implemented in plenary UI
    vim.notify('Preview not available in plenary UI mode', vim.log.levels.WARN)
end

-- Get fold level
M.get_fold = function(lnum)
    return foldexpr(lnum)
end

-- Function to render search results
M.render_results = function()
    if #state.total_item == 0 then
        return
    end

    -- Clear old search results
    api.nvim_buf_clear_namespace(M.bufnr, M.namespace_result, config.lnum_UI, -1)
    api.nvim_buf_set_lines(M.bufnr, config.lnum_UI, -1, false, {})

    -- Add separator
    api.nvim_buf_set_lines(M.bufnr, config.lnum_UI, config.lnum_UI, false, { state.user_config.line_sep_start })
    api.nvim_buf_add_highlight(M.bufnr, M.namespace, state.user_config.highlight.border, config.lnum_UI, 0, -1)

    local c_line = config.lnum_UI + 1
    local total = 0
    local padding = #state.user_config.result_padding
    local cfg = state.user_config
    local last_filename = ''

    -- Add status line for total count
    state.status_line = string.format('Total: %s matches', #state.total_item)
    utils.write_virtual_text(M.bufnr, M.namespace_status, config.lnum_UI - 1, { { state.status_line, 'Question' } })

    -- Render each item
    for _, item in ipairs(state.total_item) do
        if last_filename ~= item.filename then
            M.render_filename(M.bufnr, M.namespace, c_line, item)
            c_line = c_line + 1
            last_filename = item.filename
        end

        item.display_lnum = c_line
        M.render_line(M.bufnr, M.namespace, {
            search_query = state.query.search_query,
            replace_query = state.query.replace_query,
            search_text = item.search_text,
            lnum = item.display_lnum,
            item_line = item.lnum,
            is_replace = false,
        }, {
            is_disable = item.disable,
            padding_text = cfg.result_padding,
            padding = padding,
            show_search = state.view.show_search,
        }, state_utils.get_regex())

        c_line = c_line + 1
        total = total + 1
    end

    -- Add final separator
    api.nvim_buf_set_lines(M.bufnr, c_line, c_line, false, { cfg.line_sep })
    api.nvim_buf_add_highlight(M.bufnr, M.namespace, cfg.highlight.border, c_line, 0, -1)
end

return M
