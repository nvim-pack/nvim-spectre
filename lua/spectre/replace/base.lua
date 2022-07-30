---@diagnostic disable: param-type-mismatch
local base = {}
base.__index = base

base.on_output = function(self, value)
    pcall(vim.schedule_wrap(function()
        self.handler.on_result(value)
    end))
end

base.on_error = function(self, value, ref)
    if value ~= 0 then
        pcall(vim.schedule_wrap(function()
            self.handler.on_error({
                ref = ref
            })
        end))
    end
end

base.on_exit = function(self, value, ref)
    if value == 0 then
        pcall(vim.schedule_wrap(function()
            self.handler.on_finish({
                ref = ref
            })
        end))
    else
        base.on_error(self, value)
    end
end


local function extend(child)
    local creator = {}
    creator.__index = creator
    function creator:new(config, handler)
        assert(config ~= nil, "replace config not nil")
        handler = vim.tbl_extend('force', {
            on_start = function()
            end,
            on_error = function()
            end,
            on_finish = function()
            end
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
