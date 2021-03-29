local plenary=require('plenary.reload')

-- @CMD lua _G.__is_dev=true
if _G.import == nil then
    if _G.__is_dev then
        _G.import = function(path)
            return plenary.reload_module(path)
        end
    else
        _G.import = require
    end
end

local popup = require('popup')
local api = vim.api
local config = import('spectre.config')
local state = import('spectre.state')
local utils = import('spectre.utils')
local search_engine = import('spectre.search')
local highlights = import('spectre.highlights')

local M = {}

M.setup = function(user_config)
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
    state.finder = search_engine.rg:new({}, M.search_handler())
    opts = vim.tbl_extend('force',{
        search_text = '',
        replace_text = '',
        path = '',
        is_file = false
    }, opts or {})

    state.target_winid = api.nvim_get_current_win()
    local is_new = true
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
    api.nvim_buf_clear_namespace(state.bufnr, config.namespace, 0, -1)
    api.nvim_buf_clear_namespace(state.bufnr, config.namespace_status, 0, -1)
    api.nvim_buf_clear_namespace(state.bufnr, config.namespace_result, 0, -1)
    api.nvim_buf_set_lines(state.bufnr, 0, -1, 0, {})
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
    if #opts.search_text > 0 then
        M.search({
            search_query = opts.search_text,
            replace_query = "",
            path = opts.path,
        })
    end
    local details_ui = {}
    table.insert(details_ui , {{"Search: "  , config.highlight.ui}})
    table.insert(details_ui , {{"Replace: " , config.highlight.ui}})
    table.insert(details_ui , {{"Path: "    , config.highlight.ui}})


    local help_text = "[Nvim Spectre]        Show mapping (?)"
    utils.write_virtual_text(state.bufnr, config.namespace, 0, {{ help_text, 'Comment' } })

    local c_line = 1
    for _, vt_text in ipairs(details_ui) do
        utils.write_virtual_text(state.bufnr, config.namespace, c_line, vt_text)
        c_line = c_line + 2
    end

    M.setup_mapping_buffer(state.bufnr)
end

function M.setup_mapping_buffer(bufnr)
    vim.cmd [[ augroup search_panel_autocmds ]]
    vim.cmd [[ au! * <buffer> ]]
    vim.cmd [[ au InsertEnter <buffer> lua import"spectre".on_insert_enter() ]]
    vim.cmd [[ au InsertLeave <buffer> lua import"spectre".on_insert_leave() ]]
    vim.cmd [[ augroup END ]]
    vim.cmd [[ syn match Comment /.*:\d\+:\d\+:/]]
    vim.cmd [[setlocal nowrap]]

    api.nvim_buf_set_keymap(bufnr, 'n', 'x', 'x:lua import("spectre").on_insert_leave()<CR>',{noremap = true})
    api.nvim_buf_set_keymap(bufnr, 'n', 'd', '<nop>',{noremap = true})
    api.nvim_buf_set_keymap(bufnr, 'n', '?', "<cmd>lua import('spectre').show_help()<cr>",{noremap = true})
    for _,map in pairs(config.mapping) do
        api.nvim_buf_set_keymap(bufnr, 'n', map.map, map.cmd,{noremap = true})
    end
end



local function hl_match(opts)
    vim.cmd("syn clear " .. config.highlight.search)
    vim.cmd("syn clear " .. config.highlight.replace)
    if #opts.search_query > 0 then
        api.nvim_buf_add_highlight(state.bufnr, config.namespace,config.highlight.search, 2, 0,-1)
    end
    if #opts.replace_query>0 then
        api.nvim_buf_add_highlight(state.bufnr, config.namespace,config.highlight.replace, 4, 0,-1)
    end
end


local function check_is_edit ()
    local line = vim.fn.getpos('.')
    if line[2] > config.lnum_UI then
        return false
    end
    return true
end

M.on_insert_enter = function ()
    if check_is_edit() then return end
    local key = api.nvim_replace_termcodes("<esc>", true, false, true)
    api.nvim_feedkeys(key, "m", true)
    print("You can't make changes in results.")
end


M.on_insert_leave = function ()
    if not check_is_edit() then return end
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
    -- if change path and if different to the open lnum_UIwind ow id
    -- then we don't need to search in local file
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

    local lines = api.nvim_buf_get_lines(state.bufnr, config.line_result -1, -1, false)
    local lnum = config.line_result -1
    local lnum_replace = 1
    for _, search_line in pairs(lines) do
        lnum = lnum + 1
        if search_line == config.line_sep then
            lnum_replace = 0
        end
        if lnum_replace == 2 then
            local replace_line = utils. vim_replace_text(
            state.query.search_query,
            state.query.replace_query,
            search_line)
            api.nvim_buf_set_lines(
                state.bufnr,
                lnum,
                lnum + 1,
                false,
                {replace_line}
            )
            highlights.hl_different_line(
                state.bufnr,
                config.namespace,
                state.query.search_query,
                state.query.replace_query,
                search_line, replace_line,
                lnum-1
            )
        end
        if lnum_replace >= 0 then
            lnum_replace = lnum_replace + 1
        end
    end
end


M.delete = function ()
    if check_is_edit() then
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
        check = line == config.line_sep
        if not check then start = start -1 end
    until check or lnum - start > 3

    repeat
        line = vim.fn.getline(finish)
        check = line == config.line_sep
        if not check then finish = finish + 1 end
    until check or finish - lnum > 3

    if start < finish then
        vim.api.nvim_buf_set_lines(state.bufnr, start, finish, false,{})
    end
end

M.search_handler = function()
    local padding_txt="    "
    local c_line = 0
    local total = 0
    local start_time=0
    return {
        on_start=function()
            c_line =config.line_result
            total = 0
            start_time = vim.loop.hrtime()
        end,
        on_result = function (item)
            item.replace_text = ''
            if #state.query.replace_query > 1 then
                item.replace_text = utils.
                vim_replace_text(state.query.search_query, state.query.replace_query, item.text);
            end
            api.nvim_buf_set_lines(state.bufnr, c_line, c_line , false,{
                string.format("%s:%s:%s:", item.filename, item.lnum, item.col),
                padding_txt .. item.text,
                padding_txt  .. item.replace_text,
                config.line_sep,
            })
            highlights.hl_different_line(
                state.bufnr,
                config.namespace,
                state.query.search_query,
                state.query.replace_query,
                padding_txt .. item.text,
                padding_txt .. item.replace_text,
                c_line + 1
                )
            c_line = c_line + 4
            total = total + 1
        end,
        on_error = function (error_msg)
            api.nvim_buf_set_lines(state.bufnr, c_line, c_line + 1, false,{'--   ' .. error_msg })
            c_line = c_line + 1
        end,
        on_finish = function()
            local end_time = ( vim.loop.hrtime() - start_time) / 1E9
            local help_text = string.format("Total: %s match, time: %ss", total, end_time)
            state.vt.status_id = utils.write_virtual_text(state.bufnr, config.namespace_status, config.line_result -2, {{ help_text, 'Question' } })
        end
    }
end
M.search = function(opts)
    if #opts.search_query < 2 then return end
    state.query = opts
    -- clear old search result
    api.nvim_buf_clear_namespace(state.bufnr, config.namespace_result, 0, -1)
    api.nvim_buf_set_lines(state.bufnr, config.line_result -1, -1, false,{})
    hl_match(opts)
    local c_line = config.line_result
    api.nvim_buf_set_lines( state.bufnr, c_line -1, c_line -1, false, { config.line_sep})

    state.finder:search({
        search_text = state.query.search_query,
        replace_text = state.query.replace_text,
        path=state.query.path
    })
end

M.show_help = function()
    local help_msg = {}
    for _, map in pairs(config.mapping) do
        table.insert(help_msg, string.format("%4s : %s", map.map, map.desc))
    end

    local win_width, win_height = vim.lsp.util._make_floating_popup_size(help_msg,{})
    local help_win, preview = popup.create(help_msg,{
        title = "Mapping",
        border = true,
        padding = {1, 1, 1, 1},
        enter = false,
        width = win_width + 2,
        height = win_height + 2,
        col = "cursor+2",
        line = "cursor+2",
    })

    vim.api.nvim_win_set_option(help_win, 'winblend', 0)
    vim.lsp.util.close_preview_autocmd({"CursorMoved", "CursorMovedI", "BufHidden", "BufLeave"},
    preview.border.win_id)
    vim.lsp.util.close_preview_autocmd({"CursorMoved", "CursorMovedI", "BufHidden", "BufLeave"},
    help_win)
end


return M

