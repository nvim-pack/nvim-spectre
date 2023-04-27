local api = vim.api
local M = {}

local Job = require("plenary.job")

local config = require('spectre.config')
local state = require('spectre.state')

local _regex_file_line = [[([^:]+):(%d+):(%d+):(.*)]]
M.parse_line_grep = function(query)
    local t = { text = query }
    local _, _, filename, lnum, col, text = string.find(t.text, _regex_file_line)

    if filename == nil then return nil end
    local ok
    ok, lnum = pcall(tonumber, lnum)
    if not ok then return nil end
    ok, col = pcall(tonumber, col)
    if not ok then return nil end

    t.filename = filename
    t.lnum = lnum
    t.col = col
    t.text = text
    return t
end

-- help /ordinary-atom
-- help non-greedy
-- escape >=< to \> \= \< but if it dont have \>
M.escape_vim_magic = function(query)
    query = string.gsub(query, '@', '\\@')
    local regex = [=[(\\)@<![><=](\\)@!]=]
    return vim.fn.substitute(
        query,
        "\\v" .. regex,
        [[\\\0]],
        'g'
    )
end
-- escape_chars but don't escape it if have slash before or after !
M.escape_chars = function(query)
    local regex = [=[(\\)@<![\^\%\(\)\[\]{\}\.\*\|\"\\\/]([\\\{\}])@!]=]
    return vim.fn.substitute(
        query,
        "\\v" .. regex,
        [[\\\0]],
        'g'
    )
end

function M.trim(s)
    return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

M.truncate = function(str, len)
    if not str then return '' end
    str = tostring(str) -- We need to make sure its an actually a string and not a number
    if vim.api.nvim_strwidth(str) <= len then
        return str
    end
    local charlen = 0
    local cur_len = 0
    local result = ''
    local len_of_dots = vim.api.nvim_strwidth('…')
    while true do
        local part = M.strcharpart(str, charlen, 1)
        cur_len = cur_len + vim.api.nvim_strwidth(part)
        if (cur_len + len_of_dots) > len then
            result = result .. '…'
            break
        end
        result = result .. part
        charlen = charlen + 1
    end
    return result
end
-- only escape slash
M.escape_slash = function(query)
    return query:gsub('%\\', '\\\\')
end

-- escape slash with /
M.escape_sed = function(query)
    return query:gsub("[%/]", function(v)
        return [[\]] .. v
    end)
end

M.run_os_cmd = function(cmd, cwd)
    if type(cmd) ~= "table" then
        print('cmd has to be a table')
        return {}
    end
    local command = table.remove(cmd, 1)
    local stderr = {}
    local stdout, ret = Job:new({ command = command, args = cmd, cwd = cwd, on_stderr = function(_, data)
        table.insert(stderr, data)
    end }):sync()
    return stdout, ret, stderr
end

function M.write_virtual_text(bufnr, ns, line, chunks, virt_text_pos)
    local vt_id = nil
    if ns == config.namespace_status and state.vt.status_id ~= 0 then
        vt_id = state.vt.status_id
    end
    return api.nvim_buf_set_extmark(bufnr, ns, line, 0,
        { id = vt_id, virt_text = chunks, virt_text_pos = virt_text_pos or 'overlay' })
end

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
    local text = vim.fn.substitute(
        search_line,
        "\\v" .. M.escape_vim_magic(search_text),
        replace_text,
        'g'
    )
    return text
end

--- get all position of text match in string
---@return table col{{start1, end1},{start2, end2}} math in line
local function match_text_line(match, str, padding)
    if match == nil or str == nil then return {} end
    if match == "" or str == "" then return {} end
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
    local result = { search = {}, replace = {}, text = "" }
    opts.replace_query = opts.replace_query or ""
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
                    result.text = text:sub(0, v[2])
                        .. replace_match
                        .. text:sub(v[2] + 1)
                    total_increase = total_increase + replace_length
                end
            end
        end
    end
    return result
end
--- remove item duplicate on table
M.tbl_remove_dup = function(tbl)
    local hash = {}
    local res = {}
    for _, v in ipairs(tbl) do
        if (not hash[v]) then
            res[#res + 1] = v
            hash[v] = true
        end
    end
    return res
end
return M
