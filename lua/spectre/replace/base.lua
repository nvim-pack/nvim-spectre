local state = import('spectre.state')
local base = {}
base.__index = base

base.on_output = function(self, value)
    pcall(vim.schedule_wrap( function()
        self.handler.on_result(value)
    end))
end

base.on_error = function (self, value, ref)
    if value ~= 0 then
        pcall(vim.schedule_wrap( function()
            self.handler.on_error({
                ref = ref
            })
            return
        end))
    end
end

base.on_exit = function(self, value, ref)
    if value == 0 then
        pcall(vim.schedule_wrap( function()
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
        assert(config ~= nil, "search config not nil")
        if(config.args == nil and state.user_config ~= nil) then
            config = state.user_config.replace_engine[child.name] or config
        end
        handler = vim.tbl_extend('force', {
            on_start = function()
            end,
            on_error = function()
            end,
            on_finish = function()
            end
        }, handler or {})
        local replace_state = child:init(config)
        local search = {
            state = replace_state,
            handler = handler
        }
        local meta = {}
        meta.__index = vim.tbl_extend('force', base, child)
        return setmetatable(search, meta)
    end
    return creator
end

return {extend = extend}
