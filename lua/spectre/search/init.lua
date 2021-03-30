local base = import('spectre.search.base')
local rg = import('spectre.search.rg')

local s={
    rg = base.extend(rg)
}
s.get = function (key)
    if key and s[key]~= nil then return s[key] end
    return s.rg
end
return s
