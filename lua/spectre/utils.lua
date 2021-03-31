local api = vim.api
local M = {}

local Job = require("plenary.job")

local config = import('spectre.config')
local state = import('spectre.state')
local _regex_file_line=[[([^:]+):(%d+):(%d+):(.*)]]

-- -- don't throw error of hightlight syntax regex
-- local highlight_safe = function(group, query)
-- if state.target_bufnr ~= nil and state.query.is_file then
--     api.nvim_buf_call(state.target_bufnr,function()
--         vim.cmd(string.format([[2match %s /%s/]], state.user_config.highlight.search, state.query.search_query))
--     end)
-- end
--   if #query > 1 then
--     pcall(vim.cmd, string.format("syn match %s /%s/", group, query))
--   end
-- end
--
M.parse_line_grep = function(query)
  local t = {text = query}
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

-- escape_chars but don't escape it if have slash before or after
M.escape_chars = function(query)
-- local regex = string.gsub([[ ([^\\])([\^\%\(\)\[\]\{\}\.\*\|\\])([^\\]) ]]," ","")
--   return vim.fn.substitute(
--     query,
--     "\\v"..regex,
--     "\\1\\\\\\2\\3",
--     'g'
--   )
   return query:gsub("[^%\\][%^%/%{%}%(%)%[%]%\\%.][^%\\]", function(v)
        local cmd = v:sub(1, 1) .. "\\"..v:sub(2,3)
        return cmd
   end)

end
-- change form slash to hash
M.regex_slash_to_hash = function(query)
  return query:gsub("%\\","%%")
end

-- only escape slash
M.escape_slash = function(query)
  return query:gsub('%\\', '\\\\')
end

-- escape slash with / and '
M.escape_sed = function (query)
    return query:gsub("[%/%']", function (v)
        return "\\" ..v
    end)
end

--escape slash without number
M.escape_slash_ex_number = function(query)
  return query:gsub('%\\[^%d]', function(v1)
      return "\\"..v1
  end)
end

M.get_os_command_output = function(cmd, cwd)
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
    {id = vt_id , virt_text = chunks, virt_text_pos = virt_text_pos or 'overlay'})
end


function M.get_visual_selection()
    local start_pos = vim.api.nvim_buf_get_mark(0, '<')
    local end_pos =  vim.api.nvim_buf_get_mark(0, '>')
    local lines = vim.fn.getline(start_pos[1], end_pos[1])
    -- add when only select in 1 line
    local plusEnd = 0
    local plusStart = 1
    if #lines == 0 then
      return ''
    elseif #lines ==1 then
      plusEnd = 1
      plusStart =1
    end
    lines[#lines] = string.sub(lines[#lines], 0 , end_pos[2]+ plusEnd)
    lines[1] = string.sub(lines[1], start_pos[2] + plusStart , string.len(lines[1]))
    local query=table.concat(lines,'')
    return query
end

--- use vim function substitute with magic mode
--- need to verify that query is work in vim when you run command
function M.vim_replace_text(search_text, replace_text, search_line)
  return vim.fn.substitute(
    search_line,
    "\\v"..search_text,
    replace_text,
    'g'
  )
end

--- get all position of text match in string
---@return table col{{start1, end1},{start2, end2}} math in line
local function match_text_line(match, str)
  if match == nil or str == nil then return {}  end
  if match == "" or str == "" then return {}  end
  local index = 0
  local len = string.len(str)
  local match_len = string.len(match)
  local col_tbl = {}
  while index < len do
    local txt = string.sub(str, index, index + match_len -1)
    if txt == match then
      table.insert(col_tbl,{index -1, index + match_len -1})
      index = index + match_len
    else
      index = index + 1
    end
  end
return col_tbl
end

--- find different text of 2 line with search_text and replace_text
--- @params opts {search_text, replace_text, search_line, replace_line}
--- @return table { input={}, output = {}}
M.different_text_col = function(opts)
    local search_text, replace_text, search_line, replace_line =
    opts.search_text, opts.replace_text, opts.search_line, opts.replace_line
    local result = {input = {}, output = {}}
    local ok, search_match = pcall(vim.fn.matchstr, search_line, "\\v" .. search_text)
    if ok then
        result.input = match_text_line(search_match, search_line)
        local replace_match = M.vim_replace_text(search_text, replace_text, search_match)
        result.output = match_text_line(replace_match, replace_line)
    end
    return result
end

return M
