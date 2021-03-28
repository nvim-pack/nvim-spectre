local api = vim.api
local M = {}

local _config = import('spectre.config')
local config, state=_config.config, _config.state
local _regex_file_line=[[([^:]+):(%d+):(%d+):(.*)]]

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

M.regex_slash_to_hash = function(query)
  return query.gsub("%\\","%%")
end

M.escape_slash = function(query)
  return query:gsub('%\\', '\\\\')
end
M.escape_hl = function(query)
  return query:gsub("%\\%d", ".*")
            :gsub('%(', '\\(')
            :gsub('%)', '\\)')
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

-- adsafdsa trieu  trieu trieu
-- @FIXME
-- to highlight different text of onput and output_line
-- highlight regex on replace_line is not work with \0 \1
M.hl_different_text = function( input_line, output_line, lnum)
  local luaquery = state.query.search_query:gsub("%\\","%%")
  local col_start, col_end = string.find(input_line,luaquery )
  print(vim.inspect(col_start))
  local diff = {}
  local count = 0
  local last_col = 0
  if col_start == nil then return end
  repeat
    input_line = string.sub(input_line, col_end + 1,-1)
    table.insert(diff,{col_start + last_col, col_end + last_col})
    last_col = last_col + col_end
    col_start, col_end = string.find(input_line, state.query.search_query)
    count = count + 1
  until count > 10 or col_start == nil
  print(vim.inspect(diff))
end
return M
