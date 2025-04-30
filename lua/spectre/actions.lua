local api = vim.api
local config = require('spectre.config')
local state = require('spectre.state')
local Path = require('plenary.path')
local state_utils = require('spectre.state_utils')
local utils = require('spectre.utils')

local M = {}

local open_file = function(filename, lnum, col, winid)
    if winid ~= nil then
        vim.fn.win_gotoid(winid)
    end
    vim.api.nvim_command([[execute "normal! m` "]])
    local escaped_filename = vim.fn.fnameescape(filename)
    vim.cmd('e ' .. escaped_filename)
    pcall(api.nvim_win_set_cursor, 0, { lnum, col })
end

local is_absolute = function(filename)
    if vim.loop.os_uname().sysname == 'Windows_NT' then
        return string.find(filename, '%a:\\') == 1
    end
    return string.sub(filename, 1, 1) == '/'
end

local get_file_path = function(filename)
    -- if the path is absolute, return as is
    if is_absolute(filename) then
        return filename
    end
    -- use default current working directory if state.cwd is nil or empty string
    --
    if state.cwd == nil or state.cwd == '' then
        state.cwd = vim.fn.getcwd()
    end

    return vim.fn.expand(state.cwd) .. Path.path.sep .. filename
end

M.select_entry = function()
    local entry = M.get_current_entry()
    if not entry then return end

    local full_path = vim.fn.fnamemodify(entry.filename, ":p")
    if not vim.fn.filereadable(full_path) then return end

    vim.cmd("edit " .. full_path)
    api.nvim_win_set_cursor(0, { entry.lnum, entry.col - 1 })
end

M.get_state = function()
    local result = {
        query = state.query,
        cwd = state.cwd,
        options = state.options,
    }
    return vim.deepcopy(result)
end

M.set_entry_finish = function(display_lnum)
    -- Safety check: ensure display_lnum is valid and state.total_item exists
    if not display_lnum or not state.total_item then return end
    
    -- In Lua, arrays are 1-indexed but display_lnum might be 0-indexed
    local index = display_lnum + 1
    
    -- Check if the item exists in total_item
    local item = state.total_item[index]
    if item then
        item.is_replace_finish = true
    end
end

function M.get_current_entry()
    local bufnr = api.nvim_get_current_buf()
    local cursor_pos = api.nvim_win_get_cursor(0)
    local line = api.nvim_buf_get_lines(bufnr, cursor_pos[1] - 1, cursor_pos[1], false)[1]

    if not line then return nil end

    local filename, lnum, col = line:match("([^:]+):(%d+):(%d+):")
    if not filename or not lnum or not col then return nil end

    return {
        filename = filename,
        lnum = tonumber(lnum),
        col = tonumber(col),
        text = line:match(":[^:]+$"):sub(2),
    }
end

function M.get_all_entries()
    local entries = {}
    for display_lnum, item in ipairs(state.total_item) do
        if item and item.filename then
            table.insert(entries, {
                filename = item.filename,
                lnum = item.lnum,
                col = item.col,
                text = item.text,
                display_lnum = display_lnum - 1,
                is_replace_finish = item.is_replace_finish or false
            })
        end
    end
    return entries
end

M.send_to_qf = function()
    local entries = M.get_all_entries()
    if #entries == 0 then
        vim.notify("No entries to send to quickfix")
        return
    end

    local qf_list = {}
    for _, entry in ipairs(entries) do
        table.insert(qf_list, {
            filename = entry.filename,
            lnum = entry.lnum,
            col = entry.col,
            text = entry.text,
        })
    end

    vim.fn.setqflist(qf_list)
    vim.cmd("copen")
end

-- input that comand to run on vim
M.replace_cmd = function()
    M.send_to_qf()
    local replace_cmd = ''
    if #state.query.search_query > 2 then
        local ignore_case = ''
        local search_regex = utils.escape_vim_magic(state.query.search_query)
        if state_utils.has_options('ignore-case') == true then
            ignore_case = 'i'
        end
        if state.query.is_file == true then
            vim.fn.win_gotoid(state.target_winid)
            replace_cmd = string.format(':%%s/\\v%s/%s/g%s', search_regex, state.query.replace_query, ignore_case)
        else
            replace_cmd = string.format(
                ':%s %%s/\\v%s/%s/g%s | update',
                config.replace_vim_cmd,
                search_regex,
                state.query.replace_query,
                ignore_case
            )
        end
    end
    if #replace_cmd > 1 then
        vim.api.nvim_feedkeys(replace_cmd, 'n', true)
    end
end

function M.run_current_replace()
    local entry = M.get_current_entry()
    if entry then
        M.run_replace({ entry })
    else
        vim.notify("Not found any entry to replace.")
    end
end

local is_running = false

function M.run_replace(entries)
    entries = entries or M.get_all_entries()
    if #entries == 0 then
        vim.notify("No entries to replace")
        return
    end

    vim.schedule(function()
        local replacer_creator = state_utils.get_replace_creator()
        local replacer = replacer_creator:new(state_utils.get_replace_engine_config(), {
            on_done = function(result)
                if result.ref and result.ref.display_lnum ~= nil then
                    -- Set the entry as finished and mark it as replaced
                    M.set_entry_finish(result.ref.display_lnum)
                    
                    -- Add a safety check before accessing state.total_item
                    if state.total_item and state.total_item[result.ref.display_lnum] then
                        state.total_item[result.ref.display_lnum].is_replace = true
                    end
                    
                    -- Update UI by adding a checkmark to the line
                    local bufnr = api.nvim_get_current_buf()
                    local line = result.ref.display_lnum
                    api.nvim_buf_set_extmark(
                        bufnr,
                        config.namespace,
                        line,
                        0,
                        { virt_text = { { '✓', 'String' } }, virt_text_pos = 'eol' }
                    )
                    
                    -- If we have a renderer, trigger a full redraw
                    if state.renderer then
                        -- Update the node in the UI
                        local tree = state.renderer:get_component_by_id("results-tree")
                        -- Check if tree exists and has the get_nodes method
                        if tree and type(tree) == "table" and type(tree.get_nodes) == "function" then
                            local success, nodes = pcall(function() 
                                return tree:get_nodes() 
                            end)
                            
                            if success and nodes then
                                for _, node in ipairs(nodes) do
                                    -- Add safety check for node.display_lnum
                                    if node.display_lnum and node.display_lnum == result.ref.display_lnum then
                                        node.is_done = true
                                        -- This triggers the prepare_node function
                                        pcall(function() state.renderer:redraw() end)
                                        break
                                    end
                                end
                            else
                                -- If we can't get nodes, just redraw
                                pcall(function() state.renderer:redraw() end)
                            end
                        else
                            -- If tree doesn't exist or doesn't have get_nodes, just redraw
                            pcall(function() state.renderer:redraw() end)
                        end
                    end
                end
            end,
            on_error = function(result)
                if result.ref and result.ref.display_lnum ~= nil then
                    vim.notify("Error replacing: " .. (result.value or "unknown error"), vim.log.levels.ERROR)
                    -- Add error mark to the line
                    local bufnr = api.nvim_get_current_buf()
                    local line = result.ref.display_lnum
                    api.nvim_buf_set_extmark(
                        bufnr,
                        config.namespace,
                        line,
                        0,
                        { virt_text = { { '✗', 'Error' } }, virt_text_pos = 'eol' }
                    )
                    -- Trigger renderer redraw
                    if state.renderer then
                        -- Make sure renderer has redraw method
                        if type(state.renderer) == "table" and type(state.renderer.redraw) == "function" then
                            pcall(function() state.renderer:redraw() end)
                        end
                    end
                end
            end,
        })

        for _, entry in ipairs(entries) do
            if not entry.is_replace_finish then
                replacer:replace({
                    lnum = entry.lnum,
                    col = entry.col,
                    cwd = state.cwd,
                    display_lnum = entry.display_lnum,
                    filename = entry.filename,
                    search_text = state.query.search_query,
                    replace_text = state.query.replace_query,
                })
            end
        end
    end)
end

M.delete_line_file_current = function()
    local entry = M.get_current_entry()
    if entry then
        M.run_delete_line({ entry })
    else
        vim.notify('Not found any entry to delete.')
    end
end

M.run_delete_line = function(entries)
    entries = entries or M.get_all_entries()
    local done_item = 0
    local error_item = 0
    state.status_line = 'Run Replace.'
    local replacer_creator = state_utils.get_replace_creator()
    local replacer = replacer_creator:new(state_utils.get_replace_engine_config(), {
        on_done = function(result)
            if result.ref and result.ref.display_lnums then
                done_item = done_item + 1
                local value = result.ref
                state.status_line = 'Delete line: ' .. done_item .. ' Error:' .. error_item
                for _, display_lnum in ipairs(value.display_lnums) do
                    if display_lnum ~= nil then
                        M.set_entry_finish(display_lnum)
                        api.nvim_buf_set_extmark(
                            state.bufnr,
                            config.namespace,
                            display_lnum,
                            0,
                            { virt_text = { { '󰄲 DONE', 'String' } }, virt_text_pos = 'eol' }
                        )
                    end
                end
                -- Trigger renderer redraw
                if state.renderer then
                    -- Make sure renderer has redraw method
                    if type(state.renderer) == "table" and type(state.renderer.redraw) == "function" then
                        pcall(function() state.renderer:redraw() end)
                    end
                end
            end
        end,
        on_error = function(result)
            if result.ref and result.ref.display_lnums then
                error_item = error_item + 1
                local value = result.ref
                state.status_line = 'Delete line: ' .. done_item .. ' Error:' .. error_item
                for _, display_lnum in ipairs(value.display_lnums) do
                    if display_lnum ~= nil then
                        M.set_entry_finish(display_lnum)
                        api.nvim_buf_set_extmark(
                            state.bufnr,
                            config.namespace,
                            display_lnum,
                            0,
                            { virt_text = { { '󰄱 ERROR', 'Error' } }, virt_text_pos = 'eol' }
                        )
                    end
                end
                -- Trigger renderer redraw
                if state.renderer then
                    -- Make sure renderer has redraw method
                    if type(state.renderer) == "table" and type(state.renderer.redraw) == "function" then
                        pcall(function() state.renderer:redraw() end)
                    end
                end
            end
        end,
    })
    local groupby_filename = {}
    for _, value in pairs(entries) do
        if not groupby_filename[value.filename] then
            groupby_filename[value.filename] = {
                filename = value.filename,
                lnums = { value.lnum },
                display_lnums = { value.display_lnum },
            }
        else
            table.insert(groupby_filename[value.filename].lnums, value.lnum)
            table.insert(groupby_filename[value.filename].display_lnums, value.display_lnum)
        end
    end

    for _, value in pairs(groupby_filename) do
        replacer:delete_line({
            lnums = value.lnums,
            cwd = state.cwd,
            display_lnums = value.display_lnums,
            filename = value.filename,
        })
    end
end

M.select_template = function()
    if not state.user_config.open_template or #state.user_config.open_template == 0 then
        vim.notify('You need to set open_template on setup function.')
        return
    end
    local target_bufnr = state.target_bufnr
    local target_winid = state.target_winid
    local is_spectre = vim.api.nvim_buf_get_option(0, 'filetype') == 'spectre_panel'
    vim.ui.select(state.user_config.open_template, {
        prompt = 'Select template',
        format_item = function(item)
            return item.search_text
        end,
    }, function(item)
        require('spectre').open(vim.tbl_extend('force', state.query, item))
        if is_spectre and target_bufnr and target_winid then
            state.target_bufnr = target_bufnr
            state.target_winid = target_winid
        end
    end)
end

M.copy_current_line = function()
    local line_text = vim.api.nvim_get_current_line()
    local row = unpack(vim.api.nvim_win_get_cursor(0))
    if row > state.user_config.lnum_UI then
        line_text = line_text:sub(#state.user_config.result_padding, #line_text)
    end
    vim.fn.setreg(vim.v.register, line_text)
end

return M
