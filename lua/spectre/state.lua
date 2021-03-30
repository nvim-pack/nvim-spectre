local state = {
    -- current config
    config = {

    },
    query = {
        search_quey = '',
        replace_query = '',
        path = '',
        is_file = '' -- search in current file
    },
    finder = nil,
    replacer = nil,
    -- virtual text namespace
    vt = {

    }
}

if _G.__is_dev then
    _G.__spectre_state = _G.__spectre_state or state
    state = _G.__spectre_state
end

return state
