local utils = require('spectre.utils')

-- local rust_oxi = require('spectre_oxi')

---@type RegexEngine
local rust = {}

rust.matchstr = function(search_text, search_query)
    return rust_oxi.matchstr(search_text, search_query)
end

rust.replace_all = function(search_query, replace_query, text)
    return rust_oxi.replace_all(search_query, replace_query, text)
end

rust.replace_file = function(filepath, lnum, search_query, replace_query)
    return rust_oxi.replace_all(filepath, lnum, search_query, replace_query)
end

return rust
