local log = require('spectre._log')
local rust_oxi = require('spectre_oxi')

--- WARNING: it can't work on not utf8 string file
local rust = {}

local get_query = function(query)
    return rust.flag .. query
end
rust.change_options = function(options_value)
    rust.flag = ''
    if options_value then
        for _, v in pairs(options_value) do
            rust.flag = rust.flag .. v
        end
        if #rust.flag > 0 then
            rust.flag = string.format("(?%s)", rust.flag)
        end
    end
end

rust.matchstr = function(search_text, search_query)
    local ok, result = pcall(rust_oxi.matchstr, search_text, get_query(search_query))
    if not ok then
        log.debug(search_text)
        log.debug(result)
        return ""
    end
    return result
end

rust.replace_all = function(search_query, replace_query, text)
    local ok, result = pcall(rust_oxi.replace_all, get_query(search_query), replace_query, text)
    if not ok then
        log.debug(text)
        log.debug(result)
        return text
    end
    return result
end

-- replace text on line number of file
---@return boolean
rust.replace_file = function(filepath, lnum, search_query, replace_query)
    return rust_oxi.replace_file(filepath, lnum, get_query(search_query), replace_query)
end

return rust
