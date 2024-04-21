local Path = require('plenary.path')
local log = require('spectre._log')

local sd = {}

sd.init = function(_, config)
    return config
end

sd.replace = function(self, value)
    local cwd = value.cwd or vim.loop.cwd()
    if not value.filename:match('^%/') then
        value.filename = Path:new(cwd):joinpath(value.filename):absolute()
    end

    -- Read the original file
    local lines = {}
    local file = io.open(value.filename, 'r')
    for line in file:lines() do
        table.insert(lines, line)
    end
    file:close()

    if value.lnum <= #lines then
        -- Use `io.popen` to get the transformed line using `sd`
        local command =
            string.format("echo '%s' | sd '%s' '%s'", lines[value.lnum], value.search_text, value.replace_text)
        local handle = io.popen(command, 'r')
        if handle then
            local transformedLine = handle:read('*a')
            handle:close()
            -- Replace the line in memory
            lines[value.lnum] = transformedLine:gsub('\n$', '') -- Remove trailing newline added by `echo`
        else
            self:on_error(false, value)
            return
        end
    else
        log.debug('Line number out of bounds.')
        return
    end

    -- Write the modified lines back to the file
    file = io.open(value.filename, 'w')
    for _, line in ipairs(lines) do
        file:write(line, '\n')
    end
    file:close()

    self:on_done(true, value)
end

return sd
