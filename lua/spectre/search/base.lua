---@diagnostic disable: param-type-mismatch
local flatten = vim.tbl_flatten
local Job = require("plenary.job")
local log = require('spectre._log')
local MAX_LINE_CHARS = 255
local utils = require('spectre.utils')
local is_win = vim.api.nvim_call_function("has", { "win32" }) == 1
local base = {}
base.__index = base

---Scan a path string and split it into multiple paths.
---@param s_path string
---@return string[]
local function scan_paths(s_path)
    local paths = {}
    local path = ""
    local escape_char = is_win and "^" or "\\"

    local i = 1
    while i <= #s_path do
        local char = s_path:sub(i, i)
        if char == escape_char then
            -- Escape next character
            if i < #s_path then
                i = i + 1
                path = path .. s_path:sub(i, i)
            end
        elseif char:match("%s") then
            -- Unescaped whitespace: split here.
            if path ~= "" then
                table.insert(paths, path)
            end
            path = ""
            i = i + s_path:sub(i, -1):match("^%s+()") - 2
        else
            path = path .. char
        end

        i = i + 1
    end

    if #path > 0 then
        table.insert(paths, path)
    end

    return paths
end

base.get_path_args = function(self, path)
    print("[spectre] should implement path_args for ", self.state.cmd)
    return { path }
end


base.on_output = function(self, output_text)
    pcall(vim.schedule_wrap(function()
        if output_text == nil then return end
        -- it make vim broken with  (min.js) file has a long line
        if string.len(output_text) > MAX_LINE_CHARS then
            output_text = string.sub(output_text, 0, MAX_LINE_CHARS)
        end
        local t = utils.parse_line_grep(output_text)
        if t == nil or t.lnum == nil or t.col == nil then
            return
        end
        self.handler.on_result(t)
    end))
end

base.on_error = function(self, output_text)
    if output_text ~= nil then
        log.debug("search error " .. output_text)
        pcall(vim.schedule_wrap(function()
            self.handler.on_error(output_text)
        end))
    end
end

base.on_exit = function(self, value)
    pcall(vim.schedule_wrap(function()
        self.handler.on_finish(value)
    end))
end

base.search = function(self, query)
    local args = flatten {
        -- query.search_text,
        self.state.args,
    }
    if query.path then
        local args_path = self:get_path_args(scan_paths(query.path))
        table.insert(args, args_path)
    end

    if self.state.options_value then
        table.insert(args, self.state.options_value)
    end

    -- no more args
    table.insert(args, "--")
    args = flatten(args)

    if query.cwd == "" then
        query.cwd = nil
    end
    table.insert(args, query.search_text)

    -- https://github.com/nvim-telescope/telescope.nvim/issues/907
    -- ripgrep issue
    table.insert(args, '.')

    log.debug("search cwd " .. (query.cwd or ''))
    log.debug("search: " .. self.state.cmd .. ' ' .. table.concat(args, ' '))


    self.handler.on_start()
    self.job = Job:new({
        enable_recording = true,
        command = self.state.cmd,
        cwd = query.cwd,
        args = args,
        on_stdout = function(_, value) self:on_output(value) end,
        on_stderr = function(_, value) self:on_error(value) end,
        on_exit = function(_, value) self:on_exit(value) end
    })

    self.job:start()
end

base.stop = function(self)
    if self.job ~= nil and self.job.is_shutdown == nil then
        log.debug('base search stop')
        self.job:shutdown()
    end
    self.job = nil
end

local function extend(child)
    local creator = {}
    creator.__index = creator
    function creator:new(config, handler)
        assert(config ~= nil, "search config not nil")
        handler = vim.tbl_extend('force', {
            on_start = function()
            end,
            on_result = function()
            end,
            on_error = function()
            end,
            on_finish = function()
            end
        }, handler or {})
        local engine_state = child:init(config)
        local search = {
            state = engine_state,
            handler = handler
        }
        local meta = {}
        -- if child already have function then it will call child function
        meta.__index = vim.tbl_extend('force', base, child)
        return setmetatable(search, meta)
    end

    return creator
end

return { extend = extend }
