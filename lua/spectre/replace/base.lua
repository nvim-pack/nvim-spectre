---@diagnostic disable: param-type-mismatch
local Path = require('plenary.path')
local log = require('spectre._log')
local base = {}
base.__index = base

base.on_error = function(self, value, ref)
    if value ~= 0 then
        pcall(vim.schedule_wrap(function()
            self.handler.on_error({
                value = value,
                ref = ref,
            })
        end))
    end
end

base.on_done = function(self, value, ref)
    if value == 0 or value == true then
        pcall(vim.schedule_wrap(function()
            self.handler.on_done({
                ref = ref,
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
        assert(config ~= nil, 'replace config not nil')
        handler = vim.tbl_extend('force', {
            on_error = function() end,
            on_done = function() end,
        }, handler or {})
        local replace_state = child:init(config)
        local replace = {
            state = replace_state,
            handler = handler,
        }
        local meta = {}
        meta.__index = vim.tbl_extend('force', base, child)
        return setmetatable(replace, meta)
    end

    return creator
end

base.delete_line = function(self, value)
    local cwd = value.cwd or vim.loop.cwd()
    if not value.filename:match('^%/') then
        value.filename = Path:new(cwd):joinpath(value.filename):absolute()
    end
    log.debug('delete line on file: ' .. value.filename)
    -- Read the original file
    local lines = {}
    local file = io.open(value.filename, 'r')
    if not file then
        self.on_error(false, value)
        return
    end
    local lnum = 0
    local changed = false
    for line in file:lines() do
        lnum = lnum + 1
        if vim.iter(value.lnums):find(lnum) then
            log.debug('delete line: ' .. lnum)
            changed = true
        else
            table.insert(lines, line)
        end
    end
    file:close()

    if not changed then
        self.on_error(false, value)
        return
    end
    file = io.open(value.filename, 'w')
    if not file then
        self.on_error(false, value)
        return
    end
    for _, line in ipairs(lines) do
        file:write(line, '\n')
    end
    file:close()
    self:on_done(true, value)
end
return { extend = extend }
