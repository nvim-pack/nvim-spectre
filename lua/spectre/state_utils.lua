---@module 'spectre.state_utils'
local state = require('spectre.state')
local search_engine = require('spectre.search')
local replace_engine = require('spectre.replace')
local M = {}

---Get the search engine creator for the configured find command.
---@return table
M.get_finder_creator = function()
    return search_engine[state.user_config.default.find.cmd]
end

---Get the replace engine creator for the configured replace command.
---@return table
M.get_replace_creator = function()
    return replace_engine[state.user_config.default.replace.cmd]
end

---Get enabled option values for a given engine configuration.
---@param cfg SpectreEngineConfig Engine configuration with options
---@return string[] options_value List of active option values
local get_options = function(cfg)
    local options_value = {}
    for key, value in pairs(state.options) do
        if value and cfg.options[key] ~= nil then
            table.insert(options_value, cfg.options[key].value)
        end
    end
    return options_value
end

---Get the replace engine configuration with active options applied.
---@return SpectreEngineConfig
M.get_replace_engine_config = function()
    local cfg = state.user_config.replace_engine[state.user_config.default.replace.cmd] or {}
    cfg = vim.deepcopy(cfg)
    cfg.options_value = get_options(cfg)
    return cfg
end

---Get the search engine configuration with active options applied.
---@return SpectreEngineConfig
M.get_search_engine_config = function()
    local cfg = state.user_config.find_engine[state.user_config.default.find.cmd] or {}
    cfg = vim.deepcopy(cfg)
    cfg.options_value = get_options(cfg)
    return cfg
end

---Get the current user configuration.
---@return SpectreConfig
M.config = function()
    return state.user_config
end

---Check if a search option is enabled.
---@param key string
---@return boolean
M.has_options = function(key)
    return state.options[key] == true
end

---@class SpectreStatusLineOptions
---@field separator string?
---@field seprator string? Typo-compatible alias for separator
---@field main_color string?

---Generate a status line configuration for integration with status line plugins.
---@param opt SpectreStatusLineOptions|nil Options with separator, main_color fields
---@return table spectre Status line configuration table
M.status_line = function(opt)
    opt = opt or {}
    local slant_right = opt.separator or opt.seprator or ''
    local main_color = opt.main_color or 'black'
    local spectre = {
        filetypes = { 'spectre_panel' },
        active = {
            { ' ಠ_ಠ ', { 'white', main_color } },
            {
                hl_colors = {
                    empty = { main_color, 'NormalBg' },
                    text = { 'black', 'white' },
                    sep_left = { main_color, 'white' },
                    sep_right = { 'white', 'NormalBg' },
                },
                text = function()
                    if state.status_line == '' or state.status_line == nil then
                        return { { slant_right, 'empty' } }
                    else
                        return {
                            { slant_right, 'sep_left' },
                            { state.status_line, 'text' },
                            { slant_right, 'sep_right' },
                        }
                    end
                end,
            },
            { '%=', '' },
            { slant_right, { 'NormalBg', main_color } },
            { ' Spectre ', { 'white', main_color, 'bold' } },
        },
        show_in_active = true,
    }
    return spectre
end
return M
