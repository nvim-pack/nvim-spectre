local utils = require('spectre.utils')

---@class RegexEngine
local vim_regex = {}

vim_regex.change_options = function(_) end

vim_regex.matchstr = function(search_text, search_query)
    local ok, match = pcall(
        vim.fn.matchstr,
        search_text,
        "\\v" .. utils.escape_vim_magic(search_query)
    )
    if ok then
        return match
    end
end

vim_regex.replace_all = function(search_query, replace_query, text)
    local result = vim.fn.substitute(
        text,
        "\\v" .. utils.escape_vim_magic(search_query),
        replace_query,
        'g'
    )
    return result
end

--- get all position of text match in string
---@return table col{{start1, end1},{start2, end2}} math in line
vim_regex.match_text_line = function(match, str, padding)
    if match == nil or str == nil then return {} end
    if match == "" or str == "" then return {} end
    padding = padding or 0
    local index = 0
    local len = string.len(str)
    local match_len = string.len(match)
    local col_tbl = {}
    while index < len do
        local txt = string.sub(str, index, index + match_len - 1)
        if txt == match then
            table.insert(col_tbl, { index - 1 + padding, index + match_len - 1 + padding })
            index = index + match_len
        else
            index = index + 1
        end
    end
    return col_tbl
end

vim_regex.replace_file = function(filepath, lnum, search_query, replace_query)
end

return vim_regex
