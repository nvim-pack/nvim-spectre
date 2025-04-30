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
-- Dynamically choose UI based on configuration
local ui = nil
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
    
    -- Initialize UI based on configuration
    M.init_ui()
end

-- Initialize UI based on user config
M.init_ui = function()
    if state.user_config.use_legacy_ui then
        ui = require('spectre.ui.legacy')
    else
        ui = require('spectre.ui.nui_components')
    end
end

M.check_replace_cmd_bins = function()
    local replace_cmd = state.user_config.default.replace.cmd
    if replace_cmd == 'oxi' then
        local job = require('plenary.job')
        job:new({
            command = 'which',
            args = { 'oxi' },
            on_exit = function(j, return_val)
                if return_val ~= 0 then
                    vim.notify(
                        'oxi not found. Please install it with: cargo install oxi',
                        vim.log.levels.WARN
                    )
                end
            end,
        }):sync()
    end
end

M.open = function(opts)
    opts = opts or {}
    state.is_open = true
    state.cwd = opts.cwd or state.cwd or vim.fn.getcwd()
    state.target_winid = api.nvim_get_current_win()
    state.target_bufnr = api.nvim_get_current_buf()
    state.query = vim.tbl_extend('force', state.query, opts)
    state.query_backup = vim.deepcopy(state.query)
    state.is_running = false
    state.total_item = {}
    state.status_line = ''
    state.async_id = nil
    state.view = {
        mode = "both",
        show_search = true,
        show_replace = true,
    }
    state.regex = nil

    -- Ensure UI is initialized
    if ui == nil then
        M.init_ui()
    end
    
    ui.open()
end

M.close = function()
    state.is_open = false
    -- Ensure UI is initialized
    if ui == nil then
        M.init_ui()
    end
    ui.close()
end

M.on_write = function()
    if not state.is_open then return end
    if state.user_config.live_update then
        M.search(state.query)
    end
end

M.search = function(query)
    query = query or state.query
    if not query.search_query or #query.search_query == 0 then return end

    state.is_running = true
    state.query = query
    state.total_item = {}
    state.status_line = 'Searching...'

    local finder_creator = state_utils.get_finder_creator()
    state.finder_instance = finder_creator:new(state_utils.get_search_engine_config(), {
        on_result = function(result)
            if not state.is_running then return end
            table.insert(state.total_item, result)
        end,
        on_error = function(error_msg)
            if not state.is_running then return end
            state.status_line = 'Error: ' .. error_msg
            state.finder_instance = nil
        end,
        on_finish = function()
            if not state.is_running then return end
            state.status_line = 'Search completed'
            state.finder_instance = nil
            state.is_running = false
        end,
    })

    state.finder_instance:search({
        cwd = state.cwd,
        search_text = query.search_query,
        path = query.path,
    })
end

M.run_replace = function()
    if not state.is_running then
        require('spectre.actions').run_replace()
    end
end

M.run_current_replace = function()
    if not state.is_running then
        require('spectre.actions').run_current_replace()
    end
end

M.delete_line_file_current = function()
    if not state.is_running then
        require('spectre.actions').delete_line_file_current()
    end
end

M.send_to_qf = function()
    if not state.is_running then
        require('spectre.actions').send_to_qf()
    end
end

M.select_entry = function()
    if not state.is_running then
        require('spectre.actions').select_entry()
    end
end

M.select_template = function()
    if not state.is_running then
        require('spectre.actions').select_template()
    end
end

M.copy_current_line = function()
    if not state.is_running then
        require('spectre.actions').copy_current_line()
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
        -- Ensure UI is initialized
        if ui == nil then
            M.init_ui()
        end
        
        if ui and ui.render_search_ui then
            ui.render_search_ui()
        end
        M.search()
    end
end

M.show_options = function()
    if not ui then 
        M.init_ui()
    end
    
    if ui and ui.show_options then
        ui.show_options() 
    end
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
    if not ui then 
        M.init_ui()
    end
    
    if ui and ui.tab then
        ui.tab()
    end
end

M.tab_shift = function()
    if not ui then 
        M.init_ui()
    end
    
    if ui and ui.tab_shift then
        ui.tab_shift()
    end
end

M.toggle_preview = function()
    if not ui then 
        M.init_ui()
    end
    
    if ui and ui.toggle_preview then
        ui.toggle_preview()
    end
end

-- Function to toggle between different view modes
M.change_view = function()
    if not ui then 
        M.init_ui()
    end
    
    -- Toggle view mode
    if state.view.mode == "both" then
        state.view.mode = "replace"
        state.view.show_search = false
        state.view.show_replace = true
    elseif state.view.mode == "replace" then
        state.view.mode = "search"
        state.view.show_search = true
        state.view.show_replace = false
    else
        state.view.mode = "both"
        state.view.show_search = true
        state.view.show_replace = true
    end
    
    -- Trigger UI update if available
    if ui and ui.render_search_ui then
        ui.render_search_ui()
    end
end

-- Function to toggle between UI types
M.toggle_ui = function()
    state.user_config.use_legacy_ui = not state.user_config.use_legacy_ui
    
    -- Re-initialize the UI
    M.init_ui()
    
    -- Notify the user
    local ui_type = state.user_config.use_legacy_ui and "legacy" or "modern"
    vim.notify("Switched to " .. ui_type .. " UI. Reopen spectre panel to apply changes.", vim.log.levels.INFO)
    
    -- If spectre is open, close and reopen it to apply changes
    if state.is_open then
        local query_backup = vim.deepcopy(state.query)
        M.close()
        M.open(query_backup)
    end
end

-- Function to set the UI type
M.set_ui_type = function(use_legacy)
    state.user_config.use_legacy_ui = use_legacy
    
    -- Re-initialize the UI
    M.init_ui()
    
    -- Notify the user
    local ui_type = state.user_config.use_legacy_ui and "legacy" or "modern"
    vim.notify("Set to " .. ui_type .. " UI. Reopen spectre panel to apply changes.", vim.log.levels.INFO)
    
    -- If spectre is open, close and reopen it to apply changes
    if state.is_open then
        local query_backup = vim.deepcopy(state.query)
        M.close()
        M.open(query_backup)
    end
end

return M
