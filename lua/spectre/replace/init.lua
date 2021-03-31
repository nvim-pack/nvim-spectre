local base = import('spectre.replace.base')
local r = {}
r.get = function(key)
    assert(key ~= nil, "key no nil")
    local ok, engine = pcall(import, "spectre.replace." .. key)
    if not ok then
        print("No replace engine" .. key)
        engine = import("spectre.replace.sed")
    end
    engine.name = key
    return base.extend(engine)
end

return setmetatable(r, {
    __index = function(self, key)
        return self.get(key)
    end
})
