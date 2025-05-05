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
---@field renderer any|nil
local M = {}

M.user_config = {
    default = {
        find = {
            cmd = 'rg',
        },
        replace = {
            cmd = 'sed',
        },
    },
    find_engine = {
        rg = {
            cmd = 'rg',
            args = {
                '--color=never',
                '--no-heading',
                '--with-filename',
                '--line-number',
                '--column',
            },
            options = {
                ['ignore-case'] = {
                    value = '-i',
                    icon = '[I]',
                    desc = 'ignore case',
                },
                ['hidden'] = {
                    value = '--hidden',
                    desc = 'hidden file',
                    icon = '[H]',
                },
            },
        },
    },
    replace_engine = {
        oxi = {
            cmd = 'oxi',
            args = {},
            options = {
                ['ignore-case'] = {
                    value = '-i',
                    icon = '[I]',
                    desc = 'ignore case',
                },
            },
        },
    },
    live_update = false,
    line_sep = '└──────────────────────────────────────────────────────',
    result_padding = '│  ',
    line_sep_start = '┌──────────────────────────────────────────────────────',
    highlight = {
        ui = 'SpectreBody',
        search = 'SpectreSearch',
        replace = 'SpectreReplace',
        border = 'SpectreBorder',
    },
}

M.query = {}
M.options = {}
M.search_paths = {}
M.cwd = nil
M.target_winid = nil
M.target_bufnr = nil
M.finder_instance = nil
M.total_item = {}
M.is_running = false
M.status_line = ''
M.async_id = nil
M.view = {
    mode = 'both',
    show_search = true,
}
M.regex = nil
M.renderer = nil

if _G.__is_dev then
    _G.__spectre_state = _G.__spectre_state or M
    M = _G.__spectre_state
end

return M
