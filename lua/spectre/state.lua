local state = {
  query = { },
  vt = { }--virtual text namespace
}

if _G.__is_dev then
    _G.__spectre_state = _G.__spectre_state or state
    state = _G.__spectre_state
end

return state
