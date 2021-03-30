

local base = {}
base.__index = base


base.get_path_args = function(self, path)
    print("[spectre] should implement path_args for ", self.state.config.cmd)
    return {path}
end


base.on_output = function(self, value)
    pcall(vim.schedule_wrap( function()
        self.handler.on_result(value)
    end))
end

base.on_error = function (self, value)
    if value ~= 0 then
        pcall(vim.schedule_wrap( function()
            self.handler.on_error(value)
            return
        end))
    end
end

base.on_exit = function(self, value)
    if value == 0 then
        pcall(vim.schedule_wrap( function()
            self.handler.on_finish(value)
        end))
    else
        base.on_error(self, value)
    end
end


local function extend(child)
    local creator = {}
    creator.__index = creator
    function creator:new(config, handler)
        handler = vim.tbl_extend('force', {
            on_start = function()
            end,
            on_error = function()
            end,
            on_finish = function()
            end
        }, handler or {})
        local state = child.init(config)
        local search = {
            state = state,
            handler = handler
        }
        local meta = {}
        meta.__index = vim.tbl_extend('force', base, child)
        return setmetatable(search, meta)
    end
    return creator
end

return {extend = extend}
