
local utils = import('spectre.utils')
local Job = require("plenary.job")
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
        utils.escape_slash(value.search_text),
        utils.escape_slash(value.replace_text)
    )

    local args={
        '-i',
        '-E',
        t_sed,
        value.filename,
    }

    local job = Job:new({
        command = self.state.config.cmd,
        args = args,
        on_stdout = function(_, v) self:on_output(v) end,
        on_stderr = function(_, v) self:on_error(v) end,
        on_exit = function(_, v) self:on_exit(v) end
    })
    job:sync()
end
return sed
