local state = {
    -- current config
    user_config = nil,
    query = {
        search_quey = '',
        replace_query = '',
        path = '',
        is_file = '' -- search in current file
    },
    -- virtual text namespace
    vt = {

    },
    --for options
    options={
        ['ignore-case'] = false,
        ['hidden'] = false
    }
}

if _G.__is_dev then
    _G.__spectre_state = _G.__spectre_state or state
    state = _G.__spectre_state
end

return state
