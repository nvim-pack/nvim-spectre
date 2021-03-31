local base=import('spectre.replace.base')
local sed = import('spectre.replace.sed')

local r = {
    sed = base.extend(sed)
}

r.get = function (key)
    if key and r[key]~= nil then return r[key] end
    return r.sed
end

return r
