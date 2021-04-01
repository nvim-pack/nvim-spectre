
local Job = require("plenary.job")
local utils = require('spectre.utils')

local sed={}

sed.init = function(_, config)
    config = vim.tbl_extend('force',{
        cmd = "sed",
        pattern = "%s,%ss/%s/%s/g",
        args = {
            '-i',
            '-E',
        }
    }, config or {})
    return config
end

sed.replace = function(self, value)
    local t_sed = string.format(
        self.state.pattern,
        value.lnum,
        value.lnum,
        utils.escape_sed(value.search_text),
        utils.escape_sed(value.replace_text)
    )
    local args = vim.tbl_flatten({
        self.state.args,
        t_sed,
        value.filename,
    })
    -- print(table.concat(args, ' '))
    local job = Job:new({
        command = self.state.cmd,
        args = args,
        on_stdout = function(_, v) self:on_output(v, value) end,
        on_stderr = function(_, v) self:on_error(v, value) end,
        on_exit = function(_, v) self:on_exit(v, value) end
    })
    job:sync()
end
return sed
