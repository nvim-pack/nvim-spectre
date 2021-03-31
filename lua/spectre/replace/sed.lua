
local Job = require("plenary.job")
local utils = import('spectre.utils')

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
    return {
        config = config
    }
end

sed.replace = function(self, value)
    local t_sed = string.format(
        self.state.config.pattern,
        value.lnum,
        value.lnum,
        utils.escape_sed(value.search_text),
        utils.escape_sed(value.replace_text)
    )
    local args={
        '-i',
        '-E',
        t_sed,
        value.filename,
    }
    -- print(table.concat(args, ' '))
    local job = Job:new({
        command = self.state.config.cmd,
        args = args,
        on_stdout = function(_, v) self:on_output(v, value) end,
        on_stderr = function(_, v) self:on_error(v, value) end,
        on_exit = function(_, v) self:on_exit(v, value) end
    })
    job:sync()
end
return sed
