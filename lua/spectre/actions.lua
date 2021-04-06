local api = vim.api
local utils = require('spectre.utils')
local config = require('spectre.config')
local state = require('spectre.state')
local Path = require('plenary.path')
local state_utils=require('spectre.state_utils')

local M = {}

local open_file = function(filename, lnum, col, winid)
    if winid ~= nil then
        vim.fn.win_gotoid(winid)
    end
    vim.api.nvim_command[[execute "normal! m` "]]
    vim.cmd("e " .. filename)
    api.nvim_win_set_cursor(0,{lnum, col})
end

local get_file_path=function(filename)
    if state.cwd ~= nil and state.cwd ~= "" then
        return  vim.fn.expand(state.cwd) .. Path.path.sep .. filename
    end
    return filename
end
M.select_entry = function()
    local t = M.get_current_entry()
    if t == nil then return nil end
    if config.is_open_target_win and state.target_winid ~= nil then
        open_file(t.filename, t.lnum, t.col, state.target_winid)
    else
        open_file(t.filename, t.lnum, t.col)
    end
end

M.get_state = function()
    local result = {
        query = state.query,
        cwd = state.cwd,
        options = state.options
    }
    return vim.deepcopy(result)
end

M.get_current_entry = function ()
    local lnum = unpack(vim.api.nvim_win_get_cursor(0))
    local item = state.total_item[lnum]
    if item ~=nil and item.display_lnum == lnum - 1 then
        local t = vim.deepcopy(item)
        t.filename = get_file_path(item.filename)
        return t
    end
end

M.get_all_entries = function()
    local lines = api.nvim_buf_get_lines(state.bufnr, config.line_result -1, -1, false)
    local entries   = {}
    for _, item in pairs(state.total_item) do
        local t = vim.deepcopy(item)
        t.filename = get_file_path(item.filename)
        table.insert(entries, t)
    end
    return entries
end

M.send_to_qf = function ()
    local entries = M.get_all_entries()
    vim.cmd[[copen]]
    vim.fn.setqflist(entries,"r")
    return entries
end


M.replace_cmd = function()
    M.send_to_qf()
    local replace_cmd = ''
    if #state.query.search_query > 2 then
        local ignore_case = ''
        if state_utils.has_options('ignore-case') == true then
            ignore_case='i'
        end
        if state.query.is_file == true then
            vim.fn.win_gotoid(state.target_winid)
            replace_cmd = string.format(
                ':%%s/\\v%s/%s/g%s',
                state.query.search_query,
                state.query.replace_query,
                ignore_case
            )
        else
            replace_cmd = string.format(
                ':%s %%s/\\v%s/%s/g%s | update',
                config.replace_vim_cmd,
                state.query.search_query,
                state.query.replace_query,
                ignore_case
            )
        end
    end
    if #replace_cmd > 1 then
        vim.api.nvim_feedkeys( replace_cmd, 'n', true)
    end
end

local is_running=false

M.run_replace = function()
    if is_running == true then
        print("it is already running")
        return
    end
    local entries = M.get_all_entries()
    local replacer_creator = state_utils.get_replace_creator()
    local replacer = replacer_creator:new(
        state_utils.get_replace_engine_config(), {
            on_finish = function(result)
                if(result.ref) then
                    local value = result.ref
                    value.text = " DONE"
                    vim.fn.setqflist(entries, 'r')
                    api.nvim_buf_set_extmark(M.bufnr, config.namespace, value.display_lnum, 0,
                            { virt_text = {{" DONE", "String"}}, virt_text_pos = 'eol'})
                end
            end,
            on_error = function(result)
                if(result.ref) then
                    local value = result.ref
                    value.text = "ERROR"
                    vim.fn.setqflist(entries, 'r')
                    api.nvim_buf_set_extmark(M.bufnr, config.namespace, value.display_lnum, 0,
                            { virt_text = {{" ERROR", "Error"}}, virt_text_pos = 'eol'})
                end
            end
        }
    )
    for _, value in pairs(entries) do
        replacer:replace({
            lnum = value.lnum,
            col = value.col,
            cwd = state.cwd,
            display_lnum= value.display_lnum,
            filename = value.filename,
            search_text = state.query.search_query,
            replace_text = state.query.replace_query,
        })
    end
    -- is that correct i am not sure :)
    is_running = false
end


return M
