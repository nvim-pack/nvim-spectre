local utils = import('spectre.utils')
local search = import('spectre.search.base')
local rg = {}
local Job = require("plenary.job")
local flatten = vim.tbl_flatten
local MAX_LINE_CHARS = 255

rg.init = function(_, config)
    config = vim.tbl_extend('force',{
        cmd = "rg",
        args = {
            '--color=never',
            '--no-heading',
            '--with-filename',
            '--line-number',
            '--column',
        }
    }, config or {})
    return {
        config = config
    }
end
rg.search = function(self, query)
    local on_output = function(_, output_text)
        pcall(vim.schedule_wrap( function()
            if output_text == nil then return end
            if string.len(output_text) > MAX_LINE_CHARS then
                output_text = string.sub(output_text, 0, MAX_LINE_CHARS)
            end
            local t = utils.parse_line_grep(output_text)
            if t.lnum ==nil or t.col ==nil then
                return
            end
            self.handler.on_result(t)
        end))
    end

    local on_error = function(_, line)
        if line ~= nil then
            pcall(vim.schedule_wrap( function()
                self.handler.on_error(line)
                return
            end))
        end
    end
    local on_exit = function(line)
        pcall(vim.schedule_wrap( function()
            self.handler.on_finish(line)
        end))
    end

    local args = vim.tbl_flatten{
        self.state.config.args,
        query.search_text,
    }

    if query.path then
        local args_path={
            '-g',query.path
        }
        table.insert(args, args_path)
    end

    args = flatten(args)
    self.handler.on_start()
    local job = Job:new({
        enable_recording = true ,
        command = self.state.config.cmd,
        args = args,
        on_stdout = on_output,
        on_stderr = on_error,
        on_exit = on_exit
    })

    job:start()
end

return search.extend(rg)
