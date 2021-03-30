local api = vim.api
local M = {}

local Job = require("plenary.job")

local config = import('spectre.config')
local state = import('spectre.state')
local _regex_file_line=[[([^:]+):(%d+):(%d+):(.*)]]

-- -- don't throw error of hightlight syntax regex
-- local highlight_safe = function(group, query)
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

M.escape_chars = function(query)
  return query:gsub('^%^', '\\^')
            :gsub("%/", "\\/")
            :gsub("%{", "\\{")
            :gsub("%}", "\\}")
            :gsub('%(', '\\(')
            :gsub('%)', '\\)')
            :gsub('%.', '\\.')
            :gsub('%[', '\\[')
            :gsub('%]', '\\]')
end

-- change form slash to hash
M.regex_slash_to_hash = function(query)
  return query.gsub("%\\","%%")
end

-- only escape slash
M.escape_slash = function(query)
  return query:gsub('%\\', '\\\\')
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
-- local string_to_table=function(str)
--   local t = {}
--   for i=1, string.len(str) do
--     t[i]= (string.sub(str,i,i))
--   end
--   return t
-- end

--- use vim function substitute with magic mode
--- need to sure that query is work in vim when you run command
function M.vim_replace_text(search_text, replace_text, search_line)
  return vim.fn.substitute(
    search_line,
    "\\v"..search_text,
    replace_text,
    'g'
  )
end

--- get position of text match in string
--- @return table
local function get_col_match_on_line(match, str)
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
--- find different tex of 2 line with search_text and replace_text
--- @params opts {search_text, replace_text, search_line, replace_line}
--- @return table {inpu:{},output{}}
M.different_text_col = function(opts)
  local search_text, replace_text, search_line, replace_line
    = opts.search_text, opts.replace_text, opts.search_line, opts.replace_line
  local result = {input = {}, output = {}}
  local search_match = vim.fn.matchstr(search_line, M.escape_chars(search_text))
  result.input = get_col_match_on_line(search_match, search_line)
  local replace_match = M.vim_replace_text(search_text, replace_text, search_match)
  result.output = get_col_match_on_line(replace_match, replace_line)
  return result
end
return M
