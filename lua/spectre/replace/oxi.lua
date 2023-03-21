local oxi = {}
local Path = require('plenary.path')
local regex = require("spectre.regex.rust")
oxi.init = function(_, config)
    return config
end

oxi.replace = function(self, value)
    local cwd = value.cwd or vim.loop.cwd()
    if not value.filename:match("^%/") then
        value.filename = Path:new(cwd):joinpath(value.filename)
    end

    regex.change_options(self.state.options_value)
    local result = regex.replace_file(value.filename, value.lnum, value.search_text, value.replace_text)
    if not result then
        self:on_error(result, value)
        return
    end
    self:on_done(result, value)
end

return oxi
