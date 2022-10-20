---@diagnostic disable: undefined-field
local empty = {
    debug = function(_) end,
    info = function(_) end,
    error = function(_) end,
}
if _G.__spectre_log then
    return require('plenary.log').new {
        plugin = 'nvim-spectre',
        level = (_G.__spectre_log == true and 'debug') or 'warn',
    } or empty
end
return empty
