local plenary=require('plenary.reload')

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
                plenary.reload_module(path)
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
local ui = require('spectre.ui')

local M = {}


---@ need to improve it
M.setup = function(usr_cfg)
    state.user_config = vim.tbl_deep_extend('force', config, usr_cfg or {})
    for _, opt in pairs(state.user_config.default.find.options) do
        state.options[opt] = true
    end
end


M.open_visual = function(opts)
    opts = opts or {}
    opts.search_text = utils.get_visual_selection()
    M.open(opts)
end

M.open_file_search = function()
    M.open({
        path = vim.fn.expand("%")
    })
end

M.open = function (opts)
    if state.user_config == nil then
        M.setup()
    end

    opts = vim.tbl_extend('force',{
        cwd = nil,
        is_insert_mode = state.user_config.is_insert_mode,
        search_text = '',
        replace_text = '',
        path = '',
        is_file = false
    }, opts or {})

    state.target_winid = api.nvim_get_current_win()
    state.target_bufnr = api.nvim_get_current_buf()
    local is_new = true
    --check reopen panel by reuse bufnr
    if state.bufnr ~= nil then
        local wins = vim.fn.win_findbuf(state.bufnr)
        if #wins >= 1 then
            for _, win_id in pairs(wins) do
                if vim.fn.win_gotoid(win_id) == 1 then
                    is_new = false
                end
            end
        end
    end
    if state.bufnr == nil or is_new then
        vim.cmd[[vnew]]
    else
        if state.query.path ~= nil
           and #state.query.path > 1
           and opts.path == ''
           then
            opts.path = state.query.path
        end
    end

    vim.cmd [[setlocal buftype=nofile]]
    vim.cmd [[setlocal nobuflisted ]]
    state.bufnr = api.nvim_get_current_buf();
    vim.cmd(string.format("file %s/spectre", state.bufnr))
    vim.bo.filetype = config.filetype
    api.nvim_buf_clear_namespace(state.bufnr, config.namespace_status, 0, -1)
    api.nvim_buf_clear_namespace(state.bufnr, config.namespace_result, 0, -1)
    api.nvim_buf_set_lines(state.bufnr, 0, -1, 0, {})

    -- set empty line for virtual text
    local lines = {}
    local length = config.lnum_UI
    for _ = 1, length, 1 do
        table.insert(lines, "")
    end
    api.nvim_buf_set_lines(state.bufnr, 0, 0, 0, lines)
    api.nvim_buf_set_lines(state.bufnr, 2, 2, 0, {opts.search_text})
    api.nvim_buf_set_lines(state.bufnr, 4, 4, 0, {opts.replace_text})
    api.nvim_buf_set_lines(state.bufnr, 6, 6, 0, {opts.path})
    api.nvim_win_set_cursor(0,{3, 0})


    state.cwd = opts.cwd
    ui.render_search_ui()
    ui.render_header()

    if opts.is_insert_mode == true then
        vim.api.nvim_feedkeys('A', 'n', true)
    end

    M.mapping_buffer(state.bufnr)

    if #opts.search_text > 0 then
        M.search({
            cwd = opts.cwd,
            search_query = opts.search_text,
            replace_query = opts.replace_text,
            path = opts.path,
        })
    end
end


function M.mapping_buffer(bufnr)
    vim.cmd [[ augroup search_panel_autocmds ]]
    vim.cmd [[ au! * <buffer> ]]
    vim.cmd [[ au InsertEnter <buffer> lua require"spectre".on_insert_enter() ]]
    vim.cmd [[ au InsertLeave <buffer> lua require"spectre".on_insert_leave() ]]
    vim.cmd [[ augroup END ]]
    vim.cmd [[ syn match Comment /.*:\d\+:\d\+:/]]
    vim.cmd [[setlocal nowrap]]
    local map_opt = {noremap = true, silent = _G.__is_dev == nil  }
    api.nvim_buf_set_keymap(bufnr, 'n', 'x', 'x:lua require("spectre").on_insert_leave()<CR>',map_opt)
    api.nvim_buf_set_keymap(bufnr, 'n', 'd', '<nop>',map_opt)
    api.nvim_buf_set_keymap(bufnr, 'n', '?', "<cmd>lua require('spectre').show_help()<cr>",map_opt)
    for _,map in pairs(state.user_config.mapping) do
        api.nvim_buf_set_keymap(bufnr, 'n', map.map, map.cmd, map_opt)
    end
end



local function hl_match(opts)
    if #opts.search_query > 0 then
        api.nvim_buf_add_highlight(state.bufnr, config.namespace,
            state.user_config.highlight.search, 2, 0,-1)
    end
    if #opts.replace_query>0 then
        api.nvim_buf_add_highlight(state.bufnr, config.namespace,
            state.user_config.highlight.replace, 4, 0,-1)
    end
end


local function can_edit_line ()
    local line = vim.fn.getpos('.')
    if line[2] > config.lnum_UI then
        return false
    end
    return true
end

M.on_insert_enter = function ()
    if can_edit_line() then return end
    local key = api.nvim_replace_termcodes("<esc>", true, false, true)
    api.nvim_feedkeys(key, "m", true)
    print("You can't make changes in results.")
end


M.on_insert_leave = function ()
    if not can_edit_line() then return end
    local lines = api.nvim_buf_get_lines(state.bufnr, 0, config.lnum_UI, false)

    local query = {
        replace_query = "",
        search_query  = "",
        path          = "",
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
    -- check path to verify search in 1  current file
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
        M.do_replace_text(query)
    else
        M.search(query)
    end
end


M.do_replace_text = function(opts)
    state.query = opts
    hl_match(opts)

    local lines        = api.nvim_buf_get_lines(state.bufnr, config.line_result -1, -1, false)
    local lnum         = config.line_result -1
    local lnum_replace = 1
    local padding      = #state.user_config.result_padding
    for _, search_line in pairs(lines) do
        lnum = lnum + 1
        -- 4 character display  corner on line
        if search_line:sub(4,14) == state.user_config.line_sep:sub(4,14) then
            lnum_replace = 0
        end
        if lnum_replace == 2 then
            search_line = search_line:sub(padding + 1)
            local replace_line = utils. vim_replace_text(
                state.query.search_query,
                state.query.replace_query,
                search_line
            )
            api.nvim_buf_set_lines(
                state.bufnr,
                lnum,
                lnum + 1,
                false,
                {state.user_config.result_padding .. replace_line}
            )
            ui.hl_different_line(
                state.bufnr,
                config.namespace,
                state.query.search_query,
                state.query.replace_query,
                search_line, replace_line,
                lnum -1,
                padding
            )
        end
        if lnum_replace >= 0 then
            lnum_replace = lnum_replace + 1
        end
    end
end


M.delete = function ()
    if can_edit_line() then
        -- delete line content
        vim.cmd[[:normal! ^d$]]
        return false
    end
    local lnum = vim.fn.getpos('.')[2]
    if(lnum <= config.line_result ) then return false end
    local line = ""
    local check = false
    local start, finish = lnum, lnum

    repeat
        line = vim.fn.getline(start)
        check = line == state.user_config.line_sep
        if not check then start = start -1 end
    until check or lnum - start > 3

    repeat
        line = vim.fn.getline(finish)
        check = line == state.user_config.line_sep
        if not check then finish = finish + 1 end
    until check or finish - lnum > 3

    if start < finish then
        vim.api.nvim_buf_set_lines(state.bufnr, start, finish, false,{})
    end
end

M.search_handler = function()
    local c_line = 0
    local total = 0
    local start_time=0
    local padding=#state.user_config.result_padding
    -- local last_filename = ''
    return {
        on_start = function()
            state.total_item = {}
            c_line =config.line_result
            total = 0
            start_time = vim.loop.hrtime()
        end,
        on_result = function (item)
            item.replace_text = ''
            item.search_text = utils.truncate(utils.trim(item.text), 255)
            if #state.query.replace_query > 1 then
                item.replace_text = utils.vim_replace_text(
                    state.query.search_query,
                    state.query.replace_query,
                    item.search_text
                );
            end
            -- if last_filename ~= item.filename then
                ui.render_filename(
                    state.bufnr,
                    config.namespace,
                    c_line,
                    item
                )
                c_line = c_line + 1
                -- last_filename = item.filename
            -- end
            api.nvim_buf_set_lines(state.bufnr, c_line, c_line , false,{
                state.user_config.result_padding .. item.search_text,
                state.user_config.result_padding  .. item.replace_text,
                state.user_config.line_sep,
            })
            ui.hl_different_line(
                state.bufnr,
                config.namespace,
                state.query.search_query,
                state.query.replace_query,
                item.search_text,
                item.replace_text,
                c_line ,
                padding
            )
            c_line = c_line + 3
            total = total + 1
        end,
        on_error = function (error_msg)
            api.nvim_buf_set_lines(state.bufnr, c_line, c_line + 1, false,{'--   ' .. error_msg })
            c_line = c_line + 1
        end,
        on_finish = function()
            local end_time = ( vim.loop.hrtime() - start_time) / 1E9
            local help_text = string.format("Total: %s match, time: %ss", total, end_time)

            state.vt.status_id = utils.write_virtual_text(
                state.bufnr,
                config.namespace_status,
                config.line_result -2,
                {{ help_text, 'Question' } }
            )
        end
    }
end

M.search = function(opts)
    opts = opts or state.query
    local finder_creator = state_utils.get_finder_creator()
    local finder = finder_creator:new(
        state_utils.get_search_engine_config(),
        M.search_handler()
    )
    if #opts.search_query < 2 then return end
    state.query = opts
    -- clear old search result
    api.nvim_buf_clear_namespace(state.bufnr, config.namespace_result, 0, -1)
    api.nvim_buf_set_lines(state.bufnr, config.line_result -1, -1, false,{})
    hl_match(opts)
    local c_line = config.line_result
    api.nvim_buf_set_lines( state.bufnr,
        c_line -1, c_line -1,
        false,
        { state.user_config.line_sep_start}
    )

    finder:search({
        cwd = state.cwd,
        search_text = state.query.search_query,
        path = state.query.path
    })
end



M.show_help = function()
    ui.show_help()
end

M.change_options = function(key)
    if state.options[key] == nil then
        state.options[key] = false
    end
    state.options[key] = not state.options[key]
    if #state.query.search_query > 0 then
        ui.render_search_ui()
        M.search()
    end
end

M.show_options = function()
    local option_cmd = ui.show_options()
    vim.defer_fn(function ()
        local char = vim.fn.getchar() - 48
        if option_cmd[char] then
            M.change_options(option_cmd[char])
        end
    end,200)
end


return M

