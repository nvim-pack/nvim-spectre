local base = require('spectre.search.base')
local s = {}
s.get = function(key)
    assert(key ~= nil, "key no nil")
    local ok, engine = pcall(require, "spectre.search." .. key)
    if not ok then
        print("No search engine " .. key)
        engine = require("spectre.search.rg")
    end
    engine.name = key
    return base.extend(engine)
end
return setmetatable(s, {
    __index = function(self, key)
        return self.get(key)
    end
})
