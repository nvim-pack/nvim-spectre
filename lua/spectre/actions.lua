local Job = require("plenary.job")
local api = vim.api
local utils = import('spectre.utils')
local config = import('spectre.config')
local state=import('spectre.state')

local M = {}

local open_file = function(filename, lnum, col, winid)
  if winid ~= nil then
    vim.fn.win_gotoid(winid)
  end
  vim.api.nvim_command[[execute "normal! m` "]]
  vim.cmd("e " .. filename)
  api.nvim_win_set_cursor(0,{lnum, col})
end

M.goto_file = function()
  local t = M.get_current_entries()
  if t == nil then return nil end
  if config.is_open_target_win and state.target_winid ~= nil then
    open_file(t.filename, t.lnum, t.col, state.target_winid)
  else
    open_file(t.filename, t.lnum, t.col)
  end
end

M.get_current_entries = function ()
  local lnum  = vim.fn.getpos('.')[2]
  local line  = ""
  local check = false
  local start = lnum
  repeat
    line = vim.fn.getline(start)
    check = string.find(line, "^[^%s]*%:%d*:%d*:")
    if check then
      local t = utils.parse_line_grep(line)
      if t ~= nil and t.filename ~= nil then
        return t
      end
    end
    start = start -1
  until check or lnum - start > 3
end

M.get_all_entries = function()
  local lines = api.nvim_buf_get_lines(state.bufnr, config.line_result -1, -1, false)
  local entries   = {}
  for index, line in pairs(lines) do
    local grep = utils.parse_line_grep(line)
    if grep ~= nil and line:match("^%w") ~= nil then
      grep.lnum_result = config.line_result + index -2
      table.insert(entries, grep)
    end
  end
  return entries
end

M.send_to_qf = function ()
  local entries = M.get_all_entries()
  vim.cmd[[copen]]
  vim.fn.setqflist(entries,"r")
  return entries
end

M.replace_cmd = function()
  M.send_to_qf()
  local keyquery=''
  if #state.query.search_query > 2 then
    if state.query.is_file == true then
      vim.fn.win_gotoid(state.target_winid)
      keyquery = string.format(
        ':%%s/\\v%s/%s/g',
        state.query.search_query,
        state.query.replace_query
      )
    else
      keyquery = string.format(
        ':%s %%s/\\v%s/%s/g | update',
        config.replace_cmd,
        state.query.search_query,
        state.query.replace_query
      )
    end
  end
  if keyquery then
    vim.api.nvim_feedkeys( keyquery, 'n', true)
  end
end

M.replace_tool = function()
  local entries = M.get_all_entries()
  for _, value in pairs(entries) do
    local t_sed = string.format(
      "%s,%ss/%s/%s/g",
      value.lnum,
      value.lnum,
      utils.escape_chars(state.query.search_query),
      utils.escape_chars(state.query.replace_query)
    )

    local args={
      '-i',
      '-E',
      t_sed,
      value.filename,
    }

    local job = Job:new({
      command = "sed",
      args = args,
      on_stderr = function(error,status)
        pcall(vim.schedule_wrap( function()
          value.text = " ERROR"
          vim.fn.setqflist(entries, 'r')
        end))
      end,
      on_exit = function(_,status)
        if status == 0 then
          pcall(vim.schedule_wrap( function()
            value.text = " DONE"
            vim.fn.setqflist(entries, 'r')
            api.nvim_buf_set_extmark(M.bufnr, config.namespace, value.lnum_result, 0, { virt_text = {{" DONE", "String"}}, virt_text_pos = 'eol'})
          end))
        end
      end,
    })
    job:sync()
  end
end


M.undo=function()

end

M.undo_all=function()

end
return M
