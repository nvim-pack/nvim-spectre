local state = require('spectre.state')
local search_engine = require('spectre.search')
local replace_engine = require('spectre.replace')
local M = {}

M.get_finder_creator = function()
    return search_engine[state.user_config.default.find.cmd]
end

M.get_replace_creator = function()
    return replace_engine[state.user_config.default.replace.cmd]
end

 M.get_replace_engine_config = function ()
    local cfg = state.user_config.replace_engine[state.user_config.default.replace.cmd] or {}
    return vim.deepcopy(cfg)
end

M.get_search_engine_config = function ()
    local cfg = state.user_config.find_engine[state.user_config.default.find.cmd] or {}
    cfg = vim.deepcopy( cfg)
    cfg.options_value = {}
    for key, value in pairs(state.options) do
        if value and cfg.options[key]~=nil then
            table.insert(cfg.options_value, cfg.options[key].value)
        end
    end
    return cfg
end


M.has_options = function(key)
    return state.options[key] == true
end

return M
