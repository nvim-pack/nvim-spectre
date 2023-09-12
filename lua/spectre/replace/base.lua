---@diagnostic disable: param-type-mismatch
local base = {}
base.__index = base

base.on_error = function(self, value, ref)
    if value ~= 0 then
        pcall(vim.schedule_wrap(function()
            self.handler.on_error({
                value = value,
                ref = ref
            })
        end))
    end
end

base.on_done= function(self, value, ref)
    if value == 0 or value == true then
        pcall(vim.schedule_wrap(function()
            self.handler.on_done({
                ref = ref
            })
        end))
    else
        base.on_error(self, value, ref)
    end
end


local function extend(child)
    local creator = {}
    creator.__index = creator
    function creator:new(config, handler)
        assert(config ~= nil, "replace config not nil")
        handler = vim.tbl_extend('force', {
            on_error = function()
            end,
            on_done = function()
            end,
        }, handler or {})
        local replace_state = child:init(config)
        local replace = {
            state = replace_state,
            handler = handler
        }
        local meta = {}
        meta.__index = vim.tbl_extend('force', base, child)
        return setmetatable(replace, meta)
    end

    return creator
end

return { extend = extend }
