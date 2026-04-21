---@module 'spectre.search'
---Search engine factory. Lazily loads search engine modules by name.
local base = require('spectre.search.base')
local s = {}

---Get a search engine by name.
---@param key string Engine name (e.g., "rg", "ag")
---@return table engine Search engine creator
s.get = function(key)
    assert(key ~= nil, 'key no nil')
    local ok, engine = pcall(require, 'spectre.search.' .. key)
    if not ok then
        print('No search engine ' .. key)
        engine = require('spectre.search.rg')
    end
    engine.name = key
    return base.extend(engine)
end
return setmetatable(s, {
    __index = function(self, key)
        return self.get(key)
    end,
})
