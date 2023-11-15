---@class SpectreQuery
---@field search_query string
---@field replace_query string
---@field path string
---@field is_file boolean


---@class SpectreState
---@field user_config SpectreConfig
---@field status_line string
---@field cwd string|nil
---@field query SpectreQuery
---@field query_backup SpectreQuery|nil
---@field options table
---@field is_running boolean
---@field is_open boolean
---@field total_item table
---@field regex any
---@field finder_instance any|nil
---@field async_id number
---@field target_winid number
---@field target_bufnr number
local state = {
    -- current config
    status_line = '',
    query = {
        search_query = '',
        replace_query = '',
        path = '',
        is_file = false -- search in current file
    },
    query_backup = nil,
    -- display text and highlight on result
    view = {
        mode = "both",
        search = true,
        replace = true
    },
    -- virtual text namespace
    vt = {},
    --for options
    options = {
        ['ignore-case'] = false,
        ['hidden'] = false
    },
    regex = nil,
    user_config = nil,
    bufnr = nil,
    cwd = nil,
    target_winid = nil,
    total_item = {},
    is_running = false,
    is_open = false
}

if _G.__is_dev then
    _G.__spectre_state = _G.__spectre_state or state
    state = _G.__spectre_state
end

return state
