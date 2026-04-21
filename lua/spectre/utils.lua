---@module 'spectre.utils'
local api = vim.api
local M = {}

local Job = require('plenary.job')

local config = require('spectre.config')
local state = require('spectre.state')

local _regex_file_line = [[([^:]+):(%d+):(%d+):(.*)]]

---@class GrepParsedLine
---@field filename string
---@field lnum number
---@field col number
---@field text string

---Parse a grep-style output line into its components.
---@param query string A line of output in format "file:lnum:col:text"
---@return GrepParsedLine|nil parsed Parsed result with filename, lnum, col, text fields
M.parse_line_grep = function(query)
    local t = { text = query }
    local _, _, filename, lnum, col, text = string.find(t.text, _regex_file_line)

    if filename == nil then
        return nil
    end
    local ok
    ok, lnum = pcall(tonumber, lnum)
    if not ok then
        return nil
    end
    ok, col = pcall(tonumber, col)
    if not ok then
        return nil
    end

    t.filename = filename
    t.lnum = lnum
    t.col = col
    t.text = text
    return t
end

---Escape vim magic mode special characters in a query string.
---@param query string
---@return string
M.escape_vim_magic = function(query)
    query = string.gsub(query, '@', '\\@')
    local regex = [=[(\\)@<![><=](\\)@!]=]
    return vim.fn.substitute(query, '\\v' .. regex, [[\\\0]], 'g')
end
---Escape special regex characters in a query string.
---@param query string
---@return string
M.escape_chars = function(query)
    local regex = [=[(\\)@<![\^\%\(\)\[\]{\}\.\*\|\"\\\/]([\\\{\}])@!]=]
    return vim.fn.substitute(query, '\\v' .. regex, [[\\\0]], 'g')
end

---Trim leading and trailing whitespace from a string.
---@param s string
---@return string
function M.trim(s)
    return (string.gsub(s, '^%s*(.-)%s*$', '%1'))
end

---Truncate a string to a given display width, appending " ..." if truncated.
---@param str string|number|nil
---@param len number
---@return string
M.truncate = function(str, len)
    if not str then
        return ''
    end
    str = tostring(str) -- We need to make sure its an actually a string and not a number
    if vim.api.nvim_strwidth(str) <= len then
        return str
    end
    return string.sub(str, 0, len) .. ' ...'
end
---Escape backslashes in a string.
---@param query string
---@return string
M.escape_slash = function(query)
    return query:gsub('%\\', '\\\\')
end

---Escape forward slashes for use in sed expressions.
---@param query string
---@return string
M.escape_sed = function(query)
    return query:gsub('[%/]', function(v)
        return [[\]] .. v
    end)
end

---Run an external command synchronously.
---@param cmd table Command and arguments as a list
---@param cwd string|nil Working directory
---@return string[] stdout, number ret, string[] stderr
M.run_os_cmd = function(cmd, cwd)
    if type(cmd) ~= 'table' then
        print('cmd has to be a table')
        return {}
    end
    local command = table.remove(cmd, 1)
    local stderr = {}
    local stdout, ret = Job:new({
        command = command,
        args = cmd,
        cwd = cwd,
        on_stderr = function(_, data)
            table.insert(stderr, data)
        end,
    }):sync()
    return stdout, ret, stderr
end

---Write virtual text (extmark) to a buffer.
---@param bufnr number
---@param ns number Namespace ID
---@param line number 0-indexed line number
---@param chunks table[] Virtual text chunks
---@param virt_text_pos string|nil Position of virtual text (default: "overlay")
---@return number extmark_id
function M.write_virtual_text(bufnr, ns, line, chunks, virt_text_pos)
    local vt_id = nil
    if ns == config.namespace_status and state.vt.status_id ~= 0 then
        vt_id = state.vt.status_id
    end
    return api.nvim_buf_set_extmark(
        bufnr,
        ns,
        line,
        0,
        { id = vt_id, virt_text = chunks, virt_text_pos = virt_text_pos or 'overlay' }
    )
end

---Get the text of the current visual selection.
---@return string
function M.get_visual_selection()
    local start_pos = vim.api.nvim_buf_get_mark(0, '<')
    local end_pos = vim.api.nvim_buf_get_mark(0, '>')
    local lines = vim.fn.getline(start_pos[1], end_pos[1])
    -- add when only select in 1 line
    local plusEnd = 0
    local plusStart = 1
    if #lines == 0 then
        return ''
    elseif #lines == 1 then
        plusEnd = 1
        plusStart = 1
    end
    lines[#lines] = string.sub(lines[#lines], 0, end_pos[2] + plusEnd)
    lines[1] = string.sub(lines[1], start_pos[2] + plusStart, string.len(lines[1]))
    local query = table.concat(lines, '')
    return query
end

--- use vim function substitute with magic mode
--- need to verify that query is work in vim when you run command
function M.vim_replace_text(search_text, replace_text, search_line)
    local text = vim.fn.substitute(search_line, '\\v' .. M.escape_vim_magic(search_text), replace_text, 'g')
    return text
end

--- get all position of text match in string
---@return table col{{start1, end1},{start2, end2}} math in line
local function match_text_line(match, str, padding)
    if match == nil or str == nil then
        return {}
    end
    if match == '' or str == '' then
        return {}
    end
    padding = padding or 0
    local index = 0
    local len = string.len(str)
    local match_len = string.len(match)
    local col_tbl = {}
    while index < len do
        local txt = string.sub(str, index, index + match_len - 1)
        if txt == match then
            table.insert(col_tbl, { index - 1 + padding, index + match_len - 1 + padding })
            index = index + match_len
        else
            index = index + 1
        end
    end
    return col_tbl
end

--- get highlight text from search_text and replace_text
--- @params opts {search_query, replace_query, search_text, padding}
--- @param regex RegexEngine
--- @return table { text, search = {}, replace = {}}
M.get_hl_line_text = function(opts, regex)
    local search_match = regex.matchstr(opts.search_text, opts.search_query)
    local result = { search = {}, replace = {}, text = '' }
    opts.replace_query = opts.replace_query or ''
    result.text = opts.search_text
    if search_match then
        result.search = match_text_line(search_match, opts.search_text, 0)
        if opts.replace_query and #opts.replace_query > 0 and opts.show_replace ~= false then
            local replace_match = regex.replace_all(opts.search_query, opts.replace_query, search_match)
            local replace_length = #replace_match
            local total_increase = 0
            if opts.show_search == false then
                result.text = regex.replace_all(opts.search_query, opts.replace_query, opts.search_text)
                result.replace = match_text_line(replace_match, result.text, 0)
                result.search = {}
            else
                -- highlight and join replace text
                for _, v in pairs(result.search) do
                    v[1] = v[1] + total_increase
                    v[2] = v[2] + total_increase
                    local pos = { v[2], v[2] + replace_length }
                    table.insert(result.replace, pos)
                    local text = result.text
                    result.text = text:sub(0, v[2]) .. replace_match .. text:sub(v[2] + 1)
                    total_increase = total_increase + replace_length
                end
            end
        end
    end
    return result
end
---Remove duplicate values from a list.
---@param tbl table
---@return table
M.tbl_remove_dup = function(tbl)
    local hash = {}
    local res = {}
    for _, v in ipairs(tbl) do
        if not hash[v] then
            res[#res + 1] = v
            hash[v] = true
        end
    end
    return res
end

---Flatten a nested table into a single-level list.
---Uses vim.iter on Neovim 0.11+, falls back to vim.tbl_flatten.
---@param t table
---@return table
M.tbl_flatten = function(t)
    return vim.fn.has('nvim-0.11') == 1 and vim.iter(t):flatten(math.huge):totable() or vim.tbl_flatten(t)
end

return M
