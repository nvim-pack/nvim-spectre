-- try to do hot reload with lua
-- sometime it break your neovim:)
-- run that command and feel
-- @CMD lua _G.__is_dev=true
-- @CMD luafile %
--
-- reset state if you change default config
-- @CMD lua _G.__spectre_state = nil

if _G._require == nil then
    if _G.__is_dev then
        _G._require = require
        _G.require = function(path)
            if string.find(path, '^spectre[^_]*$') ~= nil then
                package.loaded[path] = nil
            end
            return _G._require(path)
        end
    end
end

local api = vim.api
local config = require('spectre.config')
local state = require('spectre.state')
local state_utils = require('spectre.state_utils')
local utils = require('spectre.utils')
local ui = require('spectre.ui.nui_components')
local log = require('spectre._log')
local async = require('plenary.async')

local scheduler = async.util.scheduler

local M = {}

M.setup = function(opts)
    opts = opts or {}
    state.user_config = vim.tbl_deep_extend("force", state.user_config, opts)
    for _, opt in pairs(state.user_config.default.find.options) do
        state.options[opt] = true
    end
    require('spectre.highlight').set_hl()
    M.check_replace_cmd_bins()
end

M.check_replace_cmd_bins = function()
    if state.user_config.default.replace.cmd == 'sed' then
        if vim.loop.os_uname().sysname == 'Darwin' and vim.fn.executable('sed') == 0 then
            config.replace_engine.sed.cmd = 'gsed'
            if vim.fn.executable('gsed') == 0 and state.user_config.replace_engine.sed.warn then
                print("You need to install gnu sed 'brew install gnu-sed'")
            end
        end

        if vim.loop.os_uname().sysname == 'Windows_NT' then
            if vim.fn.executable('sed') == 0 and state.user_config.replace_engine.sed.warn then
                print("You need to install gnu sed with 'scoop install sed' or 'choco install sed'")
            end
        end
    end

    if state.user_config.default.replace.cmd == 'sd' then
        if vim.fn.executable('sd') == 0 and state.user_config.replace_engine.sd.warn then
            print("You need to install or build 'sd' from: https://github.com/chmln/sd")
        end
    end
end

M.open_visual = function(opts)
    opts = opts or {}
    if opts.select_word then
        opts.search_text = vim.fn.expand('<cword>')
    else
        opts.search_text = utils.get_visual_selection()
    end
    M.open(opts)
end

M.open_file_search = function(opts)
    opts = opts or {}
    if opts.select_word then
        opts.search_text = vim.fn.expand('<cword>')
    else
        opts.search_text = utils.get_visual_selection()
    end

    opts.path = vim.fn.fnameescape(vim.fn.expand('%:p:.'))

    if vim.loop.os_uname().sysname == 'Windows_NT' then
        opts.path = vim.fn.substitute(opts.path, '\\', '/', 'g')
    end

    M.open(opts)
end

M.toggle_file_search = function(opts)
    opts = opts or {}
    if state.is_open then
        M.close()
    else
        M.open_file_search(opts)
    end
end

M.close = function()
    ui.close()
end

function M.open(opts)
    opts = opts or {}
    state.cwd = opts.cwd or vim.fn.getcwd()
    state.query = opts or {}
    state.options = opts.options or {}
    state.search_paths = opts.search_paths or {}
    state.target_winid = api.nvim_get_current_win()
    state.target_bufnr = api.nvim_get_current_buf()

    ui.open()
end

M.toggle = function(opts)
    if state.is_open then
        M.close()
    else
        M.open(opts)
    end
end

function M.mapping_buffer(bufnr)
    _G.__spectre_fold = M.get_fold
    vim.cmd([[augroup spectre_panel
                au!
                au InsertEnter <buffer> lua require"spectre".on_insert_enter()
                au InsertLeave <buffer> lua require"spectre".on_search_change()
                au BufLeave <buffer> lua require("spectre").on_leave()
                au BufUnload <buffer> lua require("spectre").on_close()
            augroup END ]])
    vim.opt_local.wrap = false
    vim.opt_local.foldexpr = 'spectre#foldexpr()'
    vim.opt_local.foldmethod = 'expr'
    local map_opt = { noremap = true, silent = _G.__is_dev == nil }
    api.nvim_buf_set_keymap(bufnr, 'n', 'x', 'x<cmd>lua require("spectre").on_search_change()<CR>', map_opt)
    api.nvim_buf_set_keymap(bufnr, 'n', 'p', "p<cmd>lua require('spectre').on_search_change()<cr>", map_opt)
    api.nvim_buf_set_keymap(bufnr, 'v', 'p', "p<cmd>lua require('spectre').on_search_change()<cr>", map_opt)
    api.nvim_buf_set_keymap(bufnr, 'v', 'P', "P<cmd>lua require('spectre').on_search_change()<cr>", map_opt)
    api.nvim_buf_set_keymap(bufnr, 'n', 'd', '<nop>', map_opt)
    api.nvim_buf_set_keymap(bufnr, 'i', '<c-c>', '<esc>', map_opt)
    api.nvim_buf_set_keymap(bufnr, 'v', 'd', '<esc><cmd>lua require("spectre").toggle_checked()<cr>', map_opt)
    api.nvim_buf_set_keymap(bufnr, 'n', 'o', 'ji', map_opt) -- don't append line on can make the UI wrong
    api.nvim_buf_set_keymap(bufnr, 'n', 'O', 'ki', map_opt)
    api.nvim_buf_set_keymap(bufnr, 'n', 'u', '', map_opt) -- disable undo, It breaks the UI.
    api.nvim_buf_set_keymap(bufnr, 'n', 'yy', "<cmd>lua require('spectre.actions').copy_current_line()<cr>", map_opt)
    api.nvim_buf_set_keymap(bufnr, 'n', '?', "<cmd>lua require('spectre').show_help()<cr>", map_opt)

    for _, map in pairs(state.user_config.mapping) do
        if map.cmd then
            api.nvim_buf_set_keymap(
                bufnr,
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
        buffer = 0,
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
            buffer = 0,
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
            buffer = 0,
            callback = function()
                local current_filetype = vim.bo.filetype
                if current_filetype == 'spectre_panel' then
                    vim.cmd('set backspace=' .. backspace)
                end
            end,
            desc = "spectre anti-insert-breakage → restore the 'backspace' option.",
        })
        api.nvim_buf_set_keymap(bufnr, 'i', '<CR>', '', map_opt) -- disable ENTER on insert mode, it breaks the UI.
    end
end

local function hl_match(opts)
    if #opts.search_query > 0 then
        api.nvim_buf_add_highlight(state.bufnr, config.namespace, state.user_config.highlight.search, 2, 0, -1)
    end
    if #opts.replace_query > 0 then
        api.nvim_buf_add_highlight(state.bufnr, config.namespace, state.user_config.highlight.replace, 4, 0, -1)
    end
end

local function can_edit_line()
    local line = vim.fn.getpos('.')
    if line[2] > config.lnum_UI then
        return false
    end
    return true
end

M.on_insert_enter = function()
    if can_edit_line() then
        return
    end
    local key = api.nvim_replace_termcodes('<esc>', true, false, true)
    api.nvim_feedkeys(key, 'm', true)
    print("You can't make changes in results.")
end

M.on_search_change = function()
    if not can_edit_line() then
        return
    end
    local lines = api.nvim_buf_get_lines(state.bufnr, 0, config.lnum_UI, false)

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
    -- check path to verify search in current file
    if state.target_winid ~= nil then
        local ok, bufnr = pcall(api.nvim_win_get_buf, state.target_winid)
        if ok then
            -- can't use api.nvim_buf_get_name it get a full path
            local bufname = vim.fn.bufname(bufnr)
            query.is_file = query.path == bufname
        else
            state.target_winid = nil
        end
    end

    if line[2] >= 5 and line[2] < 7 then
        M.async_replace(query)
    else
        M.search(query)
    end
end

M.on_write = function()
    if state.user_config.live_update == true then
        M.search()
    end
end

M.toggle_live_update = function()
    ui.toggle_live_update()
end

M.on_close = function()
    M.stop()
    vim.api.nvim_create_augroup('SpectrePanelWrite', { clear = true })
    state.query_backup = vim.tbl_extend('force', state.query, {})
end

M.on_leave = function()
    state.query_backup = vim.tbl_extend('force', state.query, {})
end

M.resume_last_search = function()
    if not state.query_backup then
        print('No previous search!')
        return
    end
    ui.render_text_query({
        replace_text = state.query_backup.replace_query,
        search_text = state.query_backup.search_query,
        path = state.query_backup.path,
    })
    ui.render_search_ui()
    M.search(state.query_backup)
end

M.async_replace = function(query)
    -- clear old search result
    api.nvim_buf_clear_namespace(state.bufnr, config.namespace_result, 0, -1)
    state.async_id = vim.loop.hrtime()
    async.void(function()
        M.do_replace_text(query, state.async_id)
    end)()
end

M.do_replace_text = function(opts, async_id)
    state.query = opts or state.query
    hl_match(state.query)
    local count = 1
    for _, item in pairs(state.total_item) do
        if state.async_id ~= async_id then
            return
        end
        ui.render_line(state.bufnr, config.namespace, {
            search_query = state.query.search_query,
            replace_query = state.query.replace_query,
            search_text = item.search_text,
            lnum = item.display_lnum,
            item_line = item.lnum,
            is_replace = true,
        }, {
            is_disable = item.disable,
            padding_text = state.user_config.result_padding,
            padding = #state.user_config.result_padding,
            show_search = state.view.show_search,
            show_replace = state.view.show_replace,
        }, state.regex)
        count = count + 1
        -- delay to next scheduler after 100 time
        if count > 100 then
            scheduler()
            count = 0
        end
    end
end

M.change_view = function(reset)
    if not ui then return end
    ui.change_view(reset)
end

M.toggle_checked = function()
    local startline = unpack(vim.api.nvim_buf_get_mark(0, '<'))
    local endline = unpack(vim.api.nvim_buf_get_mark(0, '>'))
    for i = startline, endline, 1 do
        M.toggle_line(i)
    end
end

M.toggle_line = function(line_visual)
    if not ui then return end
    ui.toggle_line()
end

M.search_handler = function()
    local c_line = 0
    local total = 0
    local start_time = 0
    local padding = #state.user_config.result_padding
    local cfg = state.user_config or {}
    local last_filename = ''
    return {
        on_start = function()
            state.total_item = {}
            state.is_running = true
            state.status_line = 'Start search'
            c_line = config.line_result
            total = 0
            start_time = vim.loop.hrtime()
        end,
        on_result = function(item)
            if not state.is_running then
                return
            end
            item.replace_text = ''
            if string.match(item.filename, '^%.%/') then
                item.filename = item.filename:sub(3, #item.filename)
            end
            item.search_text = utils.truncate(utils.trim(item.text), 255)
            if #state.query.replace_query > 1 then
                item.replace_text =
                    state.regex.replace_all(state.query.search_query, state.query.replace_query, item.search_text)
            end
            if last_filename ~= item.filename then
                ui.render_filename(state.bufnr, config.namespace, c_line, item)
                c_line = c_line + 1
                last_filename = item.filename
            end

            item.display_lnum = c_line
            ui.render_line(state.bufnr, config.namespace, {
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
                show_replace = state.view.show_replace,
            }, state.regex)
            c_line = c_line + 1
            total = total + 1
            state.status_line = 'Item  ' .. total
            state.total_item[c_line] = item
        end,
        on_error = function(error_msg)
            api.nvim_buf_set_lines(state.bufnr, c_line, c_line + 1, false, { cfg.result_padding .. error_msg })
            api.nvim_buf_add_highlight(state.bufnr, config.namespace, cfg.highlight.border, c_line, 0, padding)
            c_line = c_line + 1
            state.finder_instance = nil
        end,
        on_finish = function()
            if not state.is_running then
                return
            end
            local end_time = (vim.loop.hrtime() - start_time) / 1E9
            state.status_line = string.format('Total: %s match, time: %ss', total, end_time)

            api.nvim_buf_set_lines(state.bufnr, c_line, c_line, false, {
                cfg.line_sep,
            })
            api.nvim_buf_add_highlight(state.bufnr, config.namespace, cfg.highlight.border, c_line, 0, -1)

            state.vt.status_id = utils.write_virtual_text(
                state.bufnr,
                config.namespace_status,
                config.line_result - 2,
                { { state.status_line, 'Question' } }
            )
            state.finder_instance = nil
            state.is_running = false
        end,
    }
end

M.stop = function()
    state.is_running = false
    log.debug('spectre stop')
    if state.finder_instance ~= nil then
        state.finder_instance:stop()
        state.finder_instance = nil
    end
end

M.search = function(opts)
    M.stop()
    opts = opts or state.query
    local finder_creator = state_utils.get_finder_creator()
    state.finder_instance = finder_creator:new(state_utils.get_search_engine_config(), M.search_handler())
    if not opts.search_query or #opts.search_query < 2 then
        return
    end
    state.query = opts
    -- clear old search result
    api.nvim_buf_clear_namespace(state.bufnr, config.namespace_result, 0, -1)
    api.nvim_buf_set_lines(state.bufnr, config.line_result - 1, -1, false, {})
    hl_match(opts)
    local c_line = config.line_result
    api.nvim_buf_set_lines(state.bufnr, c_line - 1, c_line - 1, false, { state.user_config.line_sep_start })
    api.nvim_buf_add_highlight(state.bufnr, config.namespace, state.user_config.highlight.border, c_line - 1, 0, -1)
    state.total_item = {}
    state.finder_instance:search({
        cwd = state.cwd,
        search_text = state.query.search_query,
        path = state.query.path,
        search_paths = state.search_paths,
    })
    M.init_regex()
end

M.init_regex = function()
    local replace_config = state_utils.get_replace_engine_config()
    if replace_config.cmd == 'oxi' then
        state.regex = require('spectre.regex.rust')
    else
        state.regex = require('spectre.regex.vim')
    end
    state.regex.change_options(replace_config.options_value)
end

M.show_help = function()
    ui.show_help()
end

M.change_engine_replace = function(engine_name)
    if state.user_config.replace_engine[engine_name] then
        state.user_config.default.replace.cmd = engine_name
        M.init_regex()
        vim.notify('change replace engine to: ' .. engine_name)
        ui.render_header(state.user_config)
        M.search()
        return
    else
        vim.notify(string.format('engine %s not found ' .. engine_name))
    end
end

M.change_options = function(key)
    if state.options[key] == nil then
        state.options[key] = false
    end
    state.options[key] = not state.options[key]
    if state.regex == nil then
        return
    end
    state.regex.change_options(state_utils.get_replace_engine_config().options_value)
    if state.query.search_query ~= nil then
        ui.render_search_ui()
        M.search()
    end
end

M.show_options = function()
    if not ui then return end
    ui.show_options()
end

M.get_fold = function(lnum)
    if lnum < config.lnum_UI then
        return '0'
    end
    local line = vim.fn.getline(lnum)
    local padding = line:sub(0, #config.result_padding)
    if padding ~= config.result_padding then
        return '>1'
    end

    local nextline = vim.fn.getline(lnum + 1)
    padding = nextline:sub(0, #config.result_padding)
    if padding ~= config.result_padding then
        return '<1'
    end
    local item = state.total_item[lnum]
    if item ~= nil then
        return '1'
    end
    return '0'
end

M.tab = function()
    if not ui then return end
    ui.tab()
end

M.tab_shift = function()
    if not ui then return end
    ui.tab_shift()
end

M.toggle_preview = function()
    if not ui then return end
    ui.toggle_preview()
end

return M
