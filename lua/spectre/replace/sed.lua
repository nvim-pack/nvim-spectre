local Job = require("plenary.job")
local utils = require('spectre.utils')
local log = require('spectre._log')

local sed = {}


sed.init = function(_, config)
    config = vim.tbl_extend('force', {
        cmd = "sed",
        pattern = "%s,%ss/%s/%s/g",
        args = {
            '-i',
            '-E',
        },
    }, config or {})
    return config
end

sed.replace = function(self, value)
    local pattern = self.state.pattern
    if self.state.options_value ~= nil then
        for _, v in pairs(self.state.options_value) do
            if v == '--ignore-case' then
                pattern = pattern .. "i"
            end
        end
    end

    local t_sed = string.format(
        pattern,
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

    log.debug("replace cwd " .. (value.cwd or ''))
    log.debug("replace cmd: " .. self.state.cmd .. ' ' .. table.concat(args, ' '))

    if value.cwd == "" then value.cwd = nil end
    local job = Job:new({
        command = self.state.cmd,
        cwd = value.cwd,
        args = args,
        on_stdout = function(_, v) end,
        on_stderr = function(_, v)
            v = self.state.cmd .. ' "' .. table.concat(args, '" "') .. '"\n' .. v
            self:on_error(v, value)
        end,
        on_exit = function(_, v) self:on_done(v, value) end
    })
    job:sync()
end
return sed
